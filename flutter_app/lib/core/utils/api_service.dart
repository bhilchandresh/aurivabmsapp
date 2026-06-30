import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
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

  static Future<bool> _hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return true;
  }

  static Future<http.Response> _processRequest(Future<http.Response> Function() request) async {
    if (!await _hasConnection()) {
      Get.snackbar('No Internet', 'Please check your connection and try again.', snackPosition: SnackPosition.BOTTOM);
      throw Exception('No Internet Connection');
    }
    
    try {
      final response = await request().timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error: $e');
      rethrow;
    }
  }

  static http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      // Handle unauthorized (e.g., clear token, logout user)
      _storage.delete(key: 'auth_token');
      Get.offAllNamed('/login');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return _processRequest(() => http.get(Uri.parse(ApiConstants.baseUrl + endpoint), headers: headers));
  }

  static Future<http.Response> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    return _processRequest(() => http.post(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  static Future<http.Response> put(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    return _processRequest(() => http.put(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _processRequest(() => http.delete(Uri.parse(ApiConstants.baseUrl + endpoint), headers: headers));
  }

  static Future<http.Response> registerDeviceToken(String token, String platform) async {
    return post('/users/register-device', {'token': token, 'platform': platform});
  }
}
