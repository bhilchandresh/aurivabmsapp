import 'package:flutter/foundation.dart';
import 'monitoring_config.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggerService {
  final MonitoringConfig _config;

  LoggerService(this._config);

  void log({
    required LogLevel level,
    required String module,
    required String className,
    required String method,
    required String message,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    if (!_config.consoleLogsEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();
    buffer.write('[$timestamp] [${level.name.toUpperCase()}] [$module -> $className.$method] $message');

    if (exception != null) {
      buffer.write('\nException: $exception');
    }
    if (stackTrace != null) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }

    // Print to dev console
    if (kDebugMode) {
      print(buffer.toString());
    }
  }

  void verbose(String module, String className, String method, String message) {
    log(level: LogLevel.verbose, module: module, className: className, method: method, message: message);
  }

  void debug(String module, String className, String method, String message) {
    log(level: LogLevel.debug, module: module, className: className, method: method, message: message);
  }

  void info(String module, String className, String method, String message) {
    log(level: LogLevel.info, module: module, className: className, method: method, message: message);
  }

  void warning(String module, String className, String method, String message) {
    log(level: LogLevel.warning, module: module, className: className, method: method, message: message);
  }

  void error(String module, String className, String method, String message, {Object? exception, StackTrace? stackTrace}) {
    log(level: LogLevel.error, module: module, className: className, method: method, message: message, exception: exception, stackTrace: stackTrace);
  }

  void critical(String module, String className, String method, String message, {Object? exception, StackTrace? stackTrace}) {
    log(level: LogLevel.critical, module: module, className: className, method: method, message: message, exception: exception, stackTrace: stackTrace);
  }
}
