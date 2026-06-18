import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return http.get(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return http.delete(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
  }
}
