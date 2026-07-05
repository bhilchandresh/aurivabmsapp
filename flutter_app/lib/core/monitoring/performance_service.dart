import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'monitoring_config.dart';

class PerformanceService {
  final MonitoringConfig _config;
  bool _firebaseInitialized = false;
  final Map<String, Trace> _activeTraces = {};

  PerformanceService(this._config);

  void setFirebaseInitialized(bool value) {
    _firebaseInitialized = value;
  }

  Future<void> startTrace(String name) async {
    if (!_config.performanceEnabled || !_firebaseInitialized) {
      debugPrint('[STUB PERFORMANCE] Start trace: $name');
      return;
    }

    try {
      if (_activeTraces.containsKey(name)) return;
      final trace = FirebasePerformance.instance.newTrace(name);
      await trace.start();
      _activeTraces[name] = trace;
    } catch (_) {}
  }

  Future<void> stopTrace(String name) async {
    if (!_config.performanceEnabled || !_firebaseInitialized) {
      debugPrint('[STUB PERFORMANCE] Stop trace: $name');
      return;
    }

    try {
      final trace = _activeTraces.remove(name);
      if (trace != null) {
        await trace.stop();
      }
    } catch (_) {}
  }
}
