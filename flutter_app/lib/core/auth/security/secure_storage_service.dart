import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_user.dart';
import '../models/auth_tokens.dart';
import '../models/company_session.dart';

class SecureStorageKeys {
  static const String accessToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String tokens = 'auth_tokens_json';
  static const String currentUser = 'current_user_json';
  static const String currentCompany = 'current_company_json';
  static const String lastLogin = 'last_login_timestamp';
  static const String offlineExpiry = 'offline_expiry_timestamp';
  static const String language = 'app_lang_code';
  static const String countryCode = 'app_country_code';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String userSignature = 'user_signature';
  
  // Legacy backward compatible fields
  static const String legacyUserName = 'user_name';
  static const String legacyUserEmail = 'user_email';
  static const String legacyUserRole = 'user_role';
  static const String legacyUserId = 'user_id';
}

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // ── Write operations ───────────────────────────────────────────────────────

  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(key: SecureStorageKeys.accessToken, value: tokens.accessToken);
    await _storage.write(key: SecureStorageKeys.refreshToken, value: tokens.refreshToken);
    await _storage.write(key: SecureStorageKeys.tokens, value: jsonEncode(tokens.toJson()));
  }

  Future<void> saveUser(AuthUser user) async {
    await _storage.write(key: SecureStorageKeys.currentUser, value: jsonEncode(user.toJson()));
    await _storage.write(key: SecureStorageKeys.lastLogin, value: DateTime.now().toIso8601String());
    
    // Save legacy keys for backward compatibility
    await _storage.write(key: SecureStorageKeys.legacyUserName, value: user.name);
    await _storage.write(key: SecureStorageKeys.legacyUserEmail, value: user.email);
    await _storage.write(key: SecureStorageKeys.legacyUserRole, value: user.roleName);
    await _storage.write(key: SecureStorageKeys.legacyUserId, value: user.userId);
  }

  Future<void> saveCompany(CompanySession company) async {
    await _storage.write(key: SecureStorageKeys.currentCompany, value: jsonEncode(company.toJson()));
  }

  Future<void> saveOfflineExpiry(DateTime expiry) async {
    await _storage.write(key: SecureStorageKeys.offlineExpiry, value: expiry.toIso8601String());
  }

  Future<void> saveSignature(String signatureBase64) async {
    await _storage.write(key: SecureStorageKeys.userSignature, value: signatureBase64);
  }

  // ── Read operations ────────────────────────────────────────────────────────

  Future<AuthTokens?> getTokens() async {
    final s = await _storage.read(key: SecureStorageKeys.tokens);
    if (s != null) {
      try {
        return AuthTokens.fromJson(jsonDecode(s));
      } catch (_) {}
    }
    // Fallback to reading raw tokens directly
    final access = await _storage.read(key: SecureStorageKeys.accessToken);
    final refresh = await _storage.read(key: SecureStorageKeys.refreshToken);
    if (access != null && refresh != null) {
      return AuthTokens(
        accessToken: access,
        refreshToken: refresh,
        expiresAt: DateTime.now().add(const Duration(minutes: 60)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }
    return null;
  }

  Future<AuthUser?> getUser() async {
    final s = await _storage.read(key: SecureStorageKeys.currentUser);
    if (s != null) {
      try {
        return AuthUser.fromJson(jsonDecode(s));
      } catch (_) {}
    }
    return null;
  }

  Future<CompanySession?> getCompany() async {
    final s = await _storage.read(key: SecureStorageKeys.currentCompany);
    if (s != null) {
      try {
        return CompanySession.fromJson(jsonDecode(s));
      } catch (_) {}
    }
    return null;
  }

  Future<DateTime?> getOfflineExpiry() async {
    final s = await _storage.read(key: SecureStorageKeys.offlineExpiry);
    if (s != null) {
      return DateTime.tryParse(s);
    }
    return null;
  }

  Future<String?> getSignature() async {
    return _storage.read(key: SecureStorageKeys.userSignature);
  }

  Future<String?> readRawKey(String key) async {
    return _storage.read(key: key);
  }

  Future<void> writeRawKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // ── Clear operations ───────────────────────────────────────────────────────

  Future<void> clearSession() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
    await _storage.delete(key: SecureStorageKeys.tokens);
    await _storage.delete(key: SecureStorageKeys.currentUser);
    await _storage.delete(key: SecureStorageKeys.currentCompany);
    await _storage.delete(key: SecureStorageKeys.lastLogin);
    await _storage.delete(key: SecureStorageKeys.offlineExpiry);
    await _storage.delete(key: SecureStorageKeys.userSignature);
    await _storage.delete(key: SecureStorageKeys.legacyUserName);
    await _storage.delete(key: SecureStorageKeys.legacyUserEmail);
    await _storage.delete(key: SecureStorageKeys.legacyUserRole);
    await _storage.delete(key: SecureStorageKeys.legacyUserId);
    await _storage.delete(key: SecureStorageKeys.language);
    await _storage.delete(key: SecureStorageKeys.countryCode);
  }
}
