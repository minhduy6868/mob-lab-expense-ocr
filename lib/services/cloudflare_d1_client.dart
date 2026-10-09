import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/expense_item.dart';

class CloudflareD1Exception implements Exception {
  final String message;
  const CloudflareD1Exception(this.message);

  @override
  String toString() => message;
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
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? resolveD1BaseUrl();

  final http.Client _client;
  final String baseUrl;
  final String deviceId;

  static const _timeout = Duration(seconds: 12);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Device-Id': deviceId,
      };

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

  void _ensureJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudflareD1Exception('Cloudflare D1 trả về ${response.statusCode}');
    }
    final trimmed = response.body.trimLeft();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      throw const CloudflareD1Exception('API Cloudflare D1 chưa được gắn trên Pages');
    }
  }
}
