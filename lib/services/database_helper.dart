import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web fallback storage (when deployed to web / Cloudflare Pages)
  final List<ExpenseItem> _webMemoryStore = [];

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('vku_expense_ocr.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
    if (kIsWeb) {
      _webMemoryStore.removeWhere((e) => e.id == item.id);
      _webMemoryStore.insert(0, item);
      return 1;
    }

    final db = await database;
    return await db!.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    if (kIsWeb) {
      return List.unmodifiable(_webMemoryStore);
    }

    final db = await database;
    final result = await db!.query('expenses', orderBy: 'timestamp DESC');
    return result.map((json) => ExpenseItem.fromMap(json)).toList();
  }

  Future<ExpenseItem?> getExpenseById(String id) async {
    if (kIsWeb) {
      try {
        return _webMemoryStore.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final maps = await db!.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ExpenseItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(ExpenseItem item) async {
    if (kIsWeb) {
      final index = _webMemoryStore.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        _webMemoryStore[index] = item;
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db!.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    if (kIsWeb) {
      _webMemoryStore.removeWhere((e) => e.id == id);
      return 1;
    }

    final db = await database;
    return await db!.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllExpenses() async {
    if (kIsWeb) {
      final count = _webMemoryStore.length;
      _webMemoryStore.clear();
      return count;
    }

    final db = await database;
    return await db!.delete('expenses');
  }

  /// Calculates total expense amount grouped by category
  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    final expenses = await getAllExpenses();
    final map = <ExpenseCategory, double>{};
    for (final item in expenses) {
      map[item.category] = (map[item.category] ?? 0.0) + item.amount;
    }
    return map;
  }

  /// Calculates daily expenses for the current 7 days
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
}
