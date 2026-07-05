import 'monitoring_config.dart';
import 'logger_service.dart';
import 'crash_service.dart';
import 'analytics_service.dart';
import 'performance_service.dart';

class MonitoringService {
  final LoggerService logger;
  final CrashService crash;
  final AnalyticsService analytics;
  final PerformanceService performance;
  final MonitoringConfig config;

  MonitoringService({
    required this.logger,
    required this.crash,
    required this.analytics,
    required this.performance,
    required this.config,
  });

  // ── Analytics ──────────────────────────────────────────────────────────────

  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logScreenView({required String screenName}) async {
    await analytics.logScreenView(screenName: screenName);
  }

  // ── Crash & Errors ─────────────────────────────────────────────────────────

  Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason, bool fatal = false}) async {
    // Log to Crashlytics
    await crash.recordError(exception, stack, reason: reason, fatal: fatal);
    // Write structured warning/error log
    logger.error(
      'MonitoringService',
      'recordError',
      reason ?? 'recordError',
      exception.toString(),
      exception: exception,
      stackTrace: stack,
    );
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    await crash.setCustomKey(key, value);
  }

  // ── Performance Tracing ────────────────────────────────────────────────────

  Future<void> startTrace(String name) async {
    await performance.startTrace(name);
  }

  Future<void> stopTrace(String name) async {
    await performance.stopTrace(name);
  }

  // ── Multi-level Logging Delegates ──────────────────────────────────────────

  void verbose(String module, String className, String method, String message) {
    logger.verbose(module, className, method, message);
  }

  void debug(String module, String className, String method, String message) {
    logger.debug(module, className, method, message);
  }

  void info(String module, String className, String method, String message) {
    logger.info(module, className, method, message);
  }

  void warning(String module, String className, String method, String message) {
    logger.warning(module, className, method, message);
  }

  void error(String module, String className, String method, String message, {Object? exception, StackTrace? stackTrace}) {
    logger.error(module, className, method, message, exception: exception, stackTrace: stackTrace);
    // Auto-record non-fatal error reports
    crash.recordError(exception ?? message, stackTrace, reason: '$module: $className.$method: $message');
  }

  void critical(String module, String className, String method, String message, {Object? exception, StackTrace? stackTrace}) {
    logger.critical(module, className, method, message, exception: exception, stackTrace: stackTrace);
    // Auto-record fatal error reports
    crash.recordError(exception ?? message, stackTrace, reason: '$module: $className.$method: $message', fatal: true);
  }
}
