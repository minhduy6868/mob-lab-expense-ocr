import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/expense_item.dart';

class CloudflareD1Exception implements Exception {
  final String message;
  final int? statusCode;
  const CloudflareD1Exception(this.message, {this.statusCode});

  bool get unauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class AuthSession {
  final String token;
  final String userId;
  final String username;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
  });
}

/// Production Pages origin. Override with --dart-define=D1_API_BASE=https://host
String resolveD1BaseUrl() {
  const fromEnv = String.fromEnvironment('D1_API_BASE');
  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/+$'), '');
  }
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.endsWith('pages.dev')) return Uri.base.origin;
  }
  return 'https://vku-expense-ocr.pages.dev';
}

class CloudflareD1Client {
  CloudflareD1Client({
    http.Client? client,
    String? baseUrl,
    required this.deviceId,
    this.accessToken,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? resolveD1BaseUrl();

  final http.Client _client;
  final String baseUrl;
  final String deviceId;
  final String? accessToken;

  static const _timeout = Duration(seconds: 12);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Device-Id': deviceId,
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<AuthSession> register(String username, String password) {
    return _auth('register', username, password);
  }

  Future<AuthSession> login(String username, String password) {
    return _auth('login', username, password);
  }

  Future<AuthSession> me() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers)
        .timeout(_timeout);
    final body = _decodeObject(response);
    return AuthSession(
      token: accessToken ?? '',
      userId: body['userId'] as String,
      username: body['username'] as String,
    );
  }

  Future<void> logout() async {
    final response = await _client
        .post(Uri.parse('$baseUrl/api/auth/logout'), headers: _headers)
        .timeout(_timeout);
    _ensureJson(response);
  }

  Future<AuthSession> _auth(String action, String username, String password) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/$action'),
          headers: _headers,
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);
    final body = _decodeObject(response);
    return AuthSession(
      token: body['token'] as String,
      userId: body['userId'] as String,
      username: body['username'] as String,
    );
  }

  Future<bool> health() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/health'))
        .timeout(_timeout);
    _ensureJson(response);
    final body = jsonDecode(response.body);
    return body is Map && body['ok'] == true;
  }

  Future<List<ExpenseItem>> list() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/expenses'),
          headers: _headers,
        )
        .timeout(_timeout);
    return _readItems(response);
  }

  Future<List<ExpenseItem>> sync(List<Map<String, dynamic>> ops) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/expenses/sync'),
          headers: _headers,
          body: jsonEncode({'ops': ops}),
        )
        .timeout(_timeout);
    return _readItems(response);
  }

  List<ExpenseItem> _readItems(http.Response response) {
    _ensureJson(response);
    final body = jsonDecode(response.body);
    if (body is! Map || body['items'] is! List) {
      throw const CloudflareD1Exception('Phản hồi Cloudflare D1 không hợp lệ');
    }
    return (body['items'] as List).map((row) {
      return ExpenseItem.fromMap(Map<String, dynamic>.from(row as Map));
    }).toList();
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    _ensureJson(response);
    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw const CloudflareD1Exception('invalid_response');
    }
    return Map<String, dynamic>.from(body);
  }

  void _ensureJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var code = 'http_${response.statusCode}';
      final trimmed = response.body.trimLeft();
      if (trimmed.startsWith('{')) {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] is String) code = body['error'] as String;
      }
      throw CloudflareD1Exception(code, statusCode: response.statusCode);
    }
    final trimmed = response.body.trimLeft();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      throw const CloudflareD1Exception('api_missing');
    }
  }
}
