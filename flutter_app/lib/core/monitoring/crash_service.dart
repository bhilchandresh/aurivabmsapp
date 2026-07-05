import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'monitoring_config.dart';
import '../services/session_manager.dart';

class CrashService {
  final MonitoringConfig _config;
  final SessionManager _sessionManager;
  bool _firebaseInitialized = false;

  CrashService(this._config, this._sessionManager);

  void setFirebaseInitialized(bool value) {
    _firebaseInitialized = value;
    if (value && _config.crashlyticsEnabled) {
      // Pass all uncaught errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason, bool fatal = false}) async {
    if (!_config.crashlyticsEnabled || !_firebaseInitialized) {
      debugPrint('[STUB CRASH] Recorded error: $exception. Reason: $reason. Fatal: $fatal');
      return;
    }

    try {
      final user = _sessionManager.currentUserModel;
      if (user != null) {
        await FirebaseCrashlytics.instance.setCustomKey('user_id', user.userId);
        await FirebaseCrashlytics.instance.setCustomKey('company_id', user.companyId);
        await FirebaseCrashlytics.instance.setCustomKey('role', user.roleName);
      }
      await FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
    } catch (_) {}
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    if (_config.crashlyticsEnabled && _firebaseInitialized) {
      try {
        await FirebaseCrashlytics.instance.setCustomKey(key, value);
      } catch (_) {}
    }
  }
}
