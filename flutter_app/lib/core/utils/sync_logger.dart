import 'dart:convert';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, success }

class SyncLogger {
  static void log({
    required LogLevel level,
    required String module,
    required String action,
    String? entity,
    required String message,
  }) {
    if (kDebugMode) {
      final logMap = {
        'time': DateTime.now().toIso8601String(),
        'level': level.name.toUpperCase(),
        'module': module,
        'action': action,
        if (entity != null) 'entity': entity,
        'message': message,
      };

      final jsonLog = jsonEncode(logMap);
      
      // Dynamic colored prints for local developers using ASCII codes
      String colorPrefix = '';
      const String resetColor = '\x1B[0m';
      
      switch (level) {
        case LogLevel.info:
          colorPrefix = '\x1B[34m'; // Blue
          break;
        case LogLevel.warning:
          colorPrefix = '\x1B[33m'; // Yellow
          break;
        case LogLevel.error:
          colorPrefix = '\x1B[31m'; // Red
          break;
        case LogLevel.success:
          colorPrefix = '\x1B[32m'; // Green
          break;
      }
      
      debugPrint('$colorPrefix$jsonLog$resetColor');
    }
  }

  static void info(String module, String action, String message, {String? entity}) {
    log(level: LogLevel.info, module: module, action: action, message: message, entity: entity);
  }

  static void warning(String module, String action, String message, {String? entity}) {
    log(level: LogLevel.warning, module: module, action: action, message: message, entity: entity);
  }

  static void error(String module, String action, String message, {String? entity}) {
    log(level: LogLevel.error, module: module, action: action, message: message, entity: entity);
  }

  static void success(String module, String action, String message, {String? entity}) {
    log(level: LogLevel.success, module: module, action: action, message: message, entity: entity);
  }
}
