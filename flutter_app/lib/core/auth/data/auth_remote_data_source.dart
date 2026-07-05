import 'dart:convert';
import '../../../core/utils/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
    }
    throw Exception('Login failed: ${response.statusCode} — ${response.body}');
  }

  Future<Map<String, dynamic>> fetchTenantSettings(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.settings),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return Map<String, dynamic>.from(body['data']);
      }
    }
    throw Exception('Failed to fetch settings');
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    // Wrap API endpoint for refresh token if exists, else fallback or throw no-op
    final response = await ApiService.post('/auth/refresh', {
      'refreshToken': refreshToken,
    });

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
    }
    throw Exception('Refresh token failed: ${response.statusCode}');
  }
}
