import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin Frappe whitelisted-method client for Delivery (`delivery_management`).
class FrappeApi {
  FrappeApi({required this.baseUrl, this.apiKey, this.apiSecret});

  final String baseUrl;
  final String? apiKey;
  final String? apiSecret;

  factory FrappeApi.fromEnvironment() {
    const base = String.fromEnvironment(
      'FRAPPE_BASE_URL',
      defaultValue: 'http://127.0.0.1:8082',
    );
    const key = String.fromEnvironment('FRAPPE_API_KEY', defaultValue: '');
    const secret = String.fromEnvironment(
      'FRAPPE_API_SECRET',
      defaultValue: '',
    );
    return FrappeApi(
      baseUrl: base.replaceAll(RegExp(r'/$'), ''),
      apiKey: key.isEmpty ? null : key,
      apiSecret: secret.isEmpty ? null : secret,
    );
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (apiKey != null && apiSecret != null) {
      headers['Authorization'] = 'token $apiKey:$apiSecret';
    }
    return headers;
  }

  /// Call `/api/method/<method>` and return the parsed JSON map.
  Future<Map<String, dynamic>> call(
    String method, {
    Map<String, dynamic>? args,
  }) async {
    final uri = Uri.parse('$baseUrl/api/method/$method');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(args ?? {}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is Map<String, dynamic>) {
        return message;
      }
      return decoded;
    }
    throw Exception('Unexpected response: $decoded');
  }

  Future<Map<String, dynamic>> ping() {
    return call('ping');
  }
}
