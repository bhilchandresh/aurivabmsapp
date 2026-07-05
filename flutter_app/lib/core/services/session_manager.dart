import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../auth/models/auth_user.dart';
import '../auth/models/company_session.dart';
import '../auth/security/secure_storage_service.dart';

enum AuthState {
  unknown,
  authenticating,
  authenticated,
  offlineAuthenticated,
  expired,
  loggedOut,
}

enum SessionEvent {
  started,
  refreshed,
  permissionChanged,
  companyChanged,
  loggedOut,
  expired,
}

class SessionManager {
  final _storage = const FlutterSecureStorage();

  // Legacy in-memory variables for backward compatibility
  String? _legacyCompanyId;
  String? _legacyUserId;
  String? _legacyToken;
  String? _legacyRefreshToken;
  String? _legacyLanguage;
  String? _legacyCurrency;
  String? _legacyTimezone;
  String? _legacyUserRole;

  // New models
  AuthUser? _currentUser;
  CompanySession? _currentCompany;
  AuthState _authState = AuthState.unknown;
  DateTime _lastActivity = DateTime.now();

  final _eventController = StreamController<SessionEvent>.broadcast();
  Stream<SessionEvent> get sessionEvents => _eventController.stream;

  Future<void> init() async {
    _legacyToken = await _storage.read(key: 'auth_token');
    _legacyUserId = await _storage.read(key: 'user_id');
    _legacyCompanyId = await _storage.read(key: 'company_id') ?? 'default_company';
    _legacyRefreshToken = await _storage.read(key: 'refresh_token');
    _legacyLanguage = await _storage.read(key: 'app_lang_code') ?? 'en';
    _legacyCurrency = await _storage.read(key: 'currency') ?? 'INR';
    _legacyTimezone = await _storage.read(key: 'timezone') ?? 'Asia/Kolkata';
    _legacyUserRole = await _storage.read(key: 'user_role');

    // Attempt to parse cached models if available
    final secureStorageService = SecureStorageService(_storage);
    _currentUser = await secureStorageService.getUser();
    _currentCompany = await secureStorageService.getCompany();

    if (_legacyToken != null && _legacyToken!.isNotEmpty) {
      _authState = AuthState.authenticated;
    } else {
      _authState = AuthState.loggedOut;
    }
  }

  // ── Legacy Getters ─────────────────────────────────────────────────────────

  String get currentCompanyId => _currentCompany?.companyId ?? _legacyCompanyId ?? 'default_company';
  String get currentUser => _currentUser?.userId ?? _legacyUserId ?? '';
  String get currentToken => _legacyToken ?? '';
  String get refreshToken => _legacyRefreshToken ?? '';
  String get language => _currentUser?.language ?? _legacyLanguage ?? 'en';
  String get currency => _currentUser?.currency ?? _legacyCurrency ?? 'INR';
  String get timezone => _currentUser?.timezone ?? _legacyTimezone ?? 'Asia/Kolkata';
  String get currentUserRole => _currentUser?.roleName ?? _legacyUserRole ?? '';

  // ── New Getters ────────────────────────────────────────────────────────────

  AuthUser? get currentUserModel => _currentUser;
  CompanySession? get currentCompany => _currentCompany;
  AuthState get authState => _authState;
  DateTime get lastActivity => _lastActivity;
  bool get isOfflineLogin => _authState == AuthState.offlineAuthenticated;
  bool get isLoggedIn =>
      _authState == AuthState.authenticated ||
      _authState == AuthState.offlineAuthenticated;

  Duration get sessionAge => DateTime.now().difference(_currentUser?.lastLogin ?? DateTime.now());

  // ── Helper methods ─────────────────────────────────────────────────────────

  void markActivity() {
    _lastActivity = DateTime.now();
  }

  void startSession(AuthUser user, CompanySession company, {bool isOffline = false}) {
    _currentUser = user;
    _currentCompany = company;
    _authState = isOffline ? AuthState.offlineAuthenticated : AuthState.authenticated;
    
    // Update legacy variables for backward compatibility
    _legacyUserId = user.userId;
    _legacyCompanyId = company.companyId;
    _legacyLanguage = user.language;
    _legacyCurrency = user.currency;
    _legacyTimezone = user.timezone;

    _lastActivity = DateTime.now();
    _eventController.add(SessionEvent.started);
  }

  void updateSession(AuthUser user, CompanySession company) {
    _currentUser = user;
    _currentCompany = company;
    _lastActivity = DateTime.now();
    _eventController.add(SessionEvent.refreshed);
  }

  // ── Legacy updates (delegate to state updates or handle raw key writes) ───

  Future<void> updateCompanyId(String companyId) async {
    _legacyCompanyId = companyId;
    await _storage.write(key: 'company_id', value: companyId);
    _eventController.add(SessionEvent.companyChanged);
  }

  Future<void> updateToken(String token) async {
    _legacyToken = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> updateRefreshToken(String refreshToken) async {
    _legacyRefreshToken = refreshToken;
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> updateLanguage(String language) async {
    _legacyLanguage = language;
    await _storage.write(key: 'app_lang_code', value: language);
  }

  Future<void> logout() async {
    await endSession();
    Get.offAllNamed('/login');
  }

  Future<void> endSession() async {
    _currentUser = null;
    _currentCompany = null;
    _legacyToken = null;
    _legacyUserId = null;
    _legacyCompanyId = null;
    _legacyRefreshToken = null;
    _authState = AuthState.loggedOut;
    
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'company_id');
    await _storage.delete(key: 'refresh_token');
    
    _eventController.add(SessionEvent.loggedOut);
  }

  void expireSession() {
    _authState = AuthState.expired;
    _eventController.add(SessionEvent.expired);
  }

  Future<void> refreshSession() async {
    // Legacy refresh session delegate
    _eventController.add(SessionEvent.refreshed);
  }
}
