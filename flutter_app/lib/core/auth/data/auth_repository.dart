import 'dart:async';
import '../models/auth_user.dart';
import 'auth_local_data_source.dart';
import 'auth_remote_data_source.dart';
import 'auth_mapper.dart';
import '../../services/session_manager.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/sync_logger.dart';

class AuthRepository {
  final AuthLocalDataSource _localDS;
  final AuthRemoteDataSource _remoteDS;
  final SessionManager _sessionManager;

  AuthRepository(this._localDS, this._remoteDS, this._sessionManager);

  // ── Session Gateway ────────────────────────────────────────────────────────

  Future<Result<AuthUser>> login({
    required String email,
    required String password,
    bool isOnline = true,
  }) async {
    if (isOnline) {
      try {
        final loginResponse = await _remoteDS.login(email, password);
        final user = AuthMapper.fromLoginResponse(loginResponse);
        final tokens = AuthMapper.tokensFromLoginResponse(loginResponse);

        // Fetch settings as part of login flow
        Map<String, dynamic> settings = {};
        try {
          settings = await _remoteDS.fetchTenantSettings(tokens.accessToken);
        } catch (_) {}

        final company = AuthMapper.companyFromTenantSettings(settings, user.companyId);

        // Cache session securely
        await _localDS.saveSession(user: user, tokens: tokens, company: company);
        _sessionManager.startSession(user, company, isOffline: false);
        
        SyncLogger.success('AuthRepository', 'login', 'Successfully logged in online and cached user session.');
        return Result.success(user);
      } catch (e) {
        SyncLogger.error('AuthRepository', 'login', 'Online login failed: $e');
        return Result.failure(ServerFailure(message: e.toString()));
      }
    } else {
      // ── Offline Validation Cascade ──
      try {
        final isValid = await _localDS.validateOfflineLogin(email);
        if (!isValid) {
          return Result.failure(const UnauthorizedFailure('No valid cached session found or offline session expired.'));
        }

        final cachedUser = await _localDS.getCachedUser();
        final cachedCompany = await _localDS.getCachedCompany();

        if (cachedUser != null && cachedCompany != null) {
          _sessionManager.startSession(cachedUser, cachedCompany, isOffline: true);
          SyncLogger.success('AuthRepository', 'login', 'Successfully validated and restored cached user session offline.');
          return Result.success(cachedUser);
        }
        return Result.failure(const UnauthorizedFailure('Cached session records corrupted.'));
      } catch (e) {
        return Result.failure(DatabaseFailure(e.toString()));
      }
    }
  }

  Future<Result<void>> logout() async {
    try {
      await _localDS.clearSession();
      _sessionManager.endSession();
      SyncLogger.success('AuthRepository', 'logout', 'Successfully cleared user session and logged out.');
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(e.toString()));
    }
  }

  Future<bool> refreshToken() async {
    try {
      final tokens = await _localDS.getCachedTokens();
      if (tokens == null || tokens.isRefreshExpired) return false;

      final refreshResponse = await _remoteDS.refreshToken(tokens.refreshToken);
      final newTokens = AuthMapper.tokensFromLoginResponse(refreshResponse);

      final user = await _localDS.getCachedUser();
      final company = await _localDS.getCachedCompany();

      if (user != null && company != null) {
        await _localDS.saveSession(user: user, tokens: newTokens, company: company);
        _sessionManager.updateSession(user, company);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Result<AuthUser>> restoreSession() async {
    try {
      final tokens = await _localDS.getCachedTokens();
      final user = await _localDS.getCachedUser();
      final company = await _localDS.getCachedCompany();

      if (tokens != null && user != null && company != null) {
        if (tokens.isRefreshExpired) {
          await logout();
          return Result.failure(const UnauthorizedFailure('Refresh token expired. Logged out.'));
        }

        final isOffline = tokens.isAccessExpired;
        _sessionManager.startSession(user, company, isOffline: isOffline);
        return Result.success(user);
      }
      return Result.failure(const UnauthorizedFailure('No session cached to restore.'));
    } catch (e) {
      return Result.failure(DatabaseFailure(e.toString()));
    }
  }

  Future<void> fetchAndUpdateSettings() async {
    final tokens = await _localDS.getCachedTokens();
    final user = await _localDS.getCachedUser();
    if (tokens != null && user != null) {
      try {
        final settings = await _remoteDS.fetchTenantSettings(tokens.accessToken);
        final company = AuthMapper.companyFromTenantSettings(settings, user.companyId);
        await _localDS.saveSession(user: user, tokens: tokens, company: company);
        _sessionManager.updateSession(user, company);
      } catch (_) {}
    }
  }

  Future<void> saveSignature(String signatureBase64) async {
    await _localDS.saveSignature(signatureBase64);
  }
}
