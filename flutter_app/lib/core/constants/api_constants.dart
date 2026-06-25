import 'package:flutter/foundation.dart';

class ApiConstants {
  // Toggle this to switch between local backend development and the live production server
  static const bool useLiveServer = true;

  // Base URL for the backend API
  static String get baseUrl {
    if (useLiveServer) {
      return 'https://api.aurivabms.in/api/v1';
    }
    
    // For local testing in Chrome (localhost) or Android Emulator (10.0.2.2)
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1'; 
    }
    return 'http://10.0.2.2:5000/api/v1';
  }

  // Base URL of the frontend web application (for public links, sharing, etc.)
  static String get publicWebUrl {
    if (useLiveServer) {
      return 'https://app.aurivabms.in';
    }
    if (kIsWeb) {
      final currentUrl = Uri.base.toString();
      if (currentUrl.contains('app.aurivabms.in') || !currentUrl.contains('localhost')) {
        return 'https://app.aurivabms.in';
      }
      return 'http://localhost:5173'; // Default local Vite frontend port
    }

    return 'http://localhost:5173';
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String settings = '/auth/settings';
  static const String quotations = '/quotations';
  static const String invoices = '/invoices';
  static const String expenses = '/business/expenses';
  static const String clients = '/clients';
  static const String inventory = '/inventory';
  static const String suppliers = '/suppliers';
  static const String users = '/users';
  static const String notifications = '/notifications';
}
