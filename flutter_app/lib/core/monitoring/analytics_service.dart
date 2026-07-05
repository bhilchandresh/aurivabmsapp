import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'monitoring_config.dart';
import '../services/session_manager.dart';

class AnalyticsService {
  final MonitoringConfig _config;
  final SessionManager _sessionManager;
  bool _firebaseInitialized = false;

  AnalyticsService(this._config, this._sessionManager);

  void setFirebaseInitialized(bool value) {
    _firebaseInitialized = value;
  }

  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    if (!_config.analyticsEnabled || !_firebaseInitialized) {
      debugPrint('[STUB ANALYTICS] Log event: $name. Parameters: $parameters');
      return;
    }

    try {
      final user = _sessionManager.currentUserModel;
      final Map<String, Object> finalParams = {
        ...?parameters,
        if (user != null) ...{
          'company_id': user.companyId,
          'user_role': user.roleName,
        }
      };

      await FirebaseAnalytics.instance.logEvent(name: name, parameters: finalParams);
    } catch (_) {}
  }

  Future<void> logScreenView({required String screenName}) async {
    if (!_config.analyticsEnabled || !_firebaseInitialized) {
      debugPrint('[STUB ANALYTICS] Log screen view: $screenName');
      return;
    }

    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (_) {}
  }
}
