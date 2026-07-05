import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/auth_tokens.dart';

class TokenManager {
  Timer? _refreshTimer;
  final Future<bool> Function() _onRefreshTrigger;
  final VoidCallback _onSessionExpired;

  bool _isRefreshing = false;

  TokenManager({
    required Future<bool> Function() onRefreshTrigger,
    required VoidCallback onSessionExpired,
  })  : _onRefreshTrigger = onRefreshTrigger,
        _onSessionExpired = onSessionExpired;

  void scheduleAutoRefresh(AuthTokens tokens) {
    _refreshTimer?.cancel();
    
    if (tokens.isRefreshExpired) {
      _onSessionExpired();
      return;
    }

    final now = DateTime.now();
    // Refresh 5 minutes before expiration
    final refreshTime = tokens.expiresAt.subtract(const Duration(minutes: 5));
    final duration = refreshTime.difference(now);

    if (duration.isNegative) {
      // Access token is already expired or very close. Trigger immediately.
      triggerImmediateRefresh();
    } else {
      _refreshTimer = Timer(duration, () async {
        await triggerImmediateRefresh();
      });
    }
  }

  Future<bool> triggerImmediateRefresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final success = await _onRefreshTrigger();
      if (!success) {
        _onSessionExpired();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void stop() {
    _refreshTimer?.cancel();
  }
}
