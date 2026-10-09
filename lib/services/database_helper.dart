import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense_category.dart';
import '../models/expense_item.dart';
import 'cloudflare_d1_client.dart';
import 'sync_ops.dart';

enum CloudSyncPhase { checking, synced, offline }

class CloudSyncStatus {
  final CloudSyncPhase phase;
  final String detail;

  const CloudSyncStatus({required this.phase, this.detail = ''});

  static const checking = CloudSyncStatus(
    phase: CloudSyncPhase.checking,
    detail: 'Đang kết nối Cloudflare D1',
  );
}

/// SQLite on device, Cloudflare D1 when the network is up.
/// The cloud ledger is the source of truth. SQLite (and a web cache) keep a copy.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const _queueKey = 'vku_d1_queue';
  static const _cacheKey = 'vku_d1_cache';
  static const _bootKey = 'vku_d1_bootstrapped';
  static const _deviceKey = 'vku_device_id';

  final List<ExpenseItem> _webMemoryStore = [];
  final List<Map<String, dynamic>> _queue = [];

  SharedPreferences? _prefs;
  CloudflareD1Client? _client;
  String? _accessToken;
  bool _ready = false;

  CloudSyncStatus lastStatus = CloudSyncStatus.checking;
  String deviceId = '';

  DatabaseHelper._init();

  String get deviceLabel {
    if (deviceId.length < 4) return 'thiết bị này';
    return '••••${deviceId.substring(deviceId.length - 4)}';
  }

  Future<void> init() => _ensureInit();

  Future<void> _ensureInit() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    deviceId = prefs.getString(_deviceKey) ?? _createDeviceId();
    await prefs.setString(_deviceKey, deviceId);
    _client = _buildClient();
    _queue
      ..clear()
      ..addAll(_readQueue(prefs));
    if (kIsWeb) {
      _webMemoryStore
        ..clear()
        ..addAll(_readCache(prefs));
    }
    _ready = true;
  }

  void setAccessToken(String? token) {
    _accessToken = token;
    if (_ready) _client = _buildClient();
  }

  CloudflareD1Client _buildClient() {
    return CloudflareD1Client(deviceId: deviceId, accessToken: _accessToken);
  }

  Future<AuthSession> registerAccount(String username, String password) async {
    await _ensureInit();
    return _client!.register(username, password);
  }

  Future<AuthSession> loginAccount(String username, String password) async {
    await _ensureInit();
    return _client!.login(username, password);
  }

  Future<AuthSession> currentAccount() async {
    await _ensureInit();
    return _client!.me();
  }

  Future<void> logoutAccount() async {
    await _ensureInit();
    try {
      await _client!.logout();
    } catch (_) {}
  }

  Future<void> wipeLocalLedger() async {
    await _ensureInit();
    _queue.clear();
    await _saveQueue();
    await _clearLocal();
    await _prefs?.remove(_bootKey);
  }

  String _createDeviceId() {
    final clock = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final salt = Random().nextInt(0x7fffffff).toRadixString(16);
    return 'vku_${clock}_$salt';
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('vku_expense_ocr.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        category TEXT NOT NULL,
        receiptImagePath TEXT,
        rawOcrText TEXT,
        note TEXT
      )
    ''');
  }

  Future<int> insertExpense(ExpenseItem item) async {
    await _ensureInit();
    await _writeLocalUpsert(item);
    _enqueue({'op': 'upsert', 'item': item.toMap()});
    await _saveQueue();
    await _flushAndPull(migrateLocal: false);
    return 1;
  }

  Future<void> upsertAll(List<ExpenseItem> items) async {
    await _ensureInit();
    for (final item in items) {
      await _writeLocalUpsert(item);
      _enqueue({'op': 'upsert', 'item': item.toMap()});
    }
    await _saveQueue();
    await _flushAndPull(migrateLocal: false);
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    await _ensureInit();
    final remote = await _flushAndPull();
    if (remote != null) return remote;
    return _readLocal();
  }

  Future<ExpenseItem?> getExpenseById(String id) async {
    final items = await getAllExpenses();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<int> updateExpense(ExpenseItem item) => insertExpense(item);

  Future<int> deleteExpense(String id) async {
    await _ensureInit();
    await _deleteLocal(id);
    _enqueue({'op': 'delete', 'id': id});
    await _saveQueue();
    await _flushAndPull(migrateLocal: false);
    return 1;
  }

  Future<int> clearAllExpenses() async {
    await _ensureInit();
    final count = (await _readLocal()).length;
    await _clearLocal();
    _enqueue({'op': 'clear'});
    await _saveQueue();
    await _flushAndPull(migrateLocal: false);
    return count;
  }

  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    final expenses = await getAllExpenses();
    final map = <ExpenseCategory, double>{};
    for (final item in expenses) {
      map[item.category] = (map[item.category] ?? 0.0) + item.amount;
    }
    return map;
  }

  Future<Map<int, double>> getWeeklyTotals() async {
    final expenses = await getAllExpenses();
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weeklyMap = {for (int i = 1; i <= 7; i++) i: 0.0};
    for (final item in expenses) {
      if (item.timestamp.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        weeklyMap[item.timestamp.weekday] = (weeklyMap[item.timestamp.weekday] ?? 0.0) + item.amount;
      }
    }
    return weeklyMap;
  }

  Future<List<ExpenseItem>?> _flushAndPull({bool migrateLocal = true}) async {
    final client = _client;
    final prefs = _prefs;
    if (client == null || prefs == null) {
      lastStatus = const CloudSyncStatus(
        phase: CloudSyncPhase.offline,
        detail: 'Ngoại tuyến. Dữ liệu giữ trên máy.',
      );
      return null;
    }

    try {
      lastStatus = CloudSyncStatus.checking;
      List<ExpenseItem> remote;
      if (_queue.isNotEmpty) {
        remote = await client.sync(compactSyncOps(_queue));
        _queue.clear();
        await _saveQueue();
      } else {
        remote = await client.list();
      }

      final bootstrapped = prefs.getBool(_bootKey) ?? false;
      final local = await _readLocal();
      if (migrateLocal && !bootstrapped && remote.isEmpty && local.isNotEmpty) {
        remote = await client.sync([
          for (final item in local) {'op': 'upsert', 'item': item.toMap()},
        ]);
      }
      await prefs.setBool(_bootKey, true);
      await _replaceLocal(remote);
      lastStatus = const CloudSyncStatus(
        phase: CloudSyncPhase.synced,
        detail: 'Đã đồng bộ Cloudflare D1',
      );
      return remote;
    } catch (error) {
      debugPrint('Cloudflare D1 sync skipped: $error');
      lastStatus = const CloudSyncStatus(
        phase: CloudSyncPhase.offline,
        detail: 'Ngoại tuyến. Dữ liệu giữ trên máy.',
      );
      return null;
    }
  }

  void _enqueue(Map<String, dynamic> op) {
    _queue.add(op);
    final compacted = compactSyncOps(_queue);
    _queue
      ..clear()
      ..addAll(compacted);
  }

  Future<void> _saveQueue() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_queueKey, jsonEncode(_queue));
  }

  List<Map<String, dynamic>> _readQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  List<ExpenseItem> _readCache(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((row) => ExpenseItem.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ExpenseItem>> _readLocal() async {
    if (kIsWeb) {
      final copy = List<ExpenseItem>.from(_webMemoryStore);
      copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return copy;
    }
    final db = await database;
    final result = await db!.query('expenses', orderBy: 'timestamp DESC');
    return result.map(ExpenseItem.fromMap).toList();
  }

  Future<void> _writeLocalUpsert(ExpenseItem item) async {
    if (kIsWeb) {
      _webMemoryStore.removeWhere((entry) => entry.id == item.id);
      _webMemoryStore.insert(0, item);
      await _persistCache();
      return;
    }
    final db = await database;
    await db!.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _deleteLocal(String id) async {
    if (kIsWeb) {
      _webMemoryStore.removeWhere((entry) => entry.id == id);
      await _persistCache();
      return;
    }
    final db = await database;
    await db!.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _clearLocal() async {
    if (kIsWeb) {
      _webMemoryStore.clear();
      await _persistCache();
      return;
    }
    final db = await database;
    await db!.delete('expenses');
  }

  Future<void> _replaceLocal(List<ExpenseItem> items) async {
    if (kIsWeb) {
      _webMemoryStore
        ..clear()
        ..addAll(items);
      await _persistCache();
      return;
    }
    final db = await database;
    final batch = db!.batch();
    batch.delete('expenses');
    for (final item in items) {
      batch.insert('expenses', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> _persistCache() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final payload = _webMemoryStore.map((item) => item.toMap()).toList();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }
}
