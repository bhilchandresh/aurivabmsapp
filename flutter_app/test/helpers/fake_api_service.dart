import 'dart:convert';
import 'package:http/http.dart' as http;

class FakeApiService {
  static http.Response successResponse(Map<String, dynamic> body) {
    return http.Response(jsonEncode(body), 200, headers: {
      'content-type': 'application/json; charset=utf-8',
    });
  }

  static http.Response successListResponse(List<dynamic> body) {
    return http.Response(jsonEncode(body), 200, headers: {
      'content-type': 'application/json; charset=utf-8',
    });
  }

  static http.Response errorResponse(int statusCode, String message) {
    return http.Response(jsonEncode({'message': message}), statusCode, headers: {
      'content-type': 'application/json; charset=utf-8',
    });
  }
}
