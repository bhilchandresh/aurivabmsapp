import '../models/auth_user.dart';
import '../models/auth_tokens.dart';
import '../models/company_session.dart';
import '../security/secure_storage_service.dart';

class AuthLocalDataSource {
  final SecureStorageService _secureStorage;

  AuthLocalDataSource(this._secureStorage);

  Future<void> saveSession({
    required AuthUser user,
    required AuthTokens tokens,
    required CompanySession company,
  }) async {
    await _secureStorage.saveUser(user);
    await _secureStorage.saveTokens(tokens);
    await _secureStorage.saveCompany(company);
    
    // Set default offline expiry to 7 days from now
    final expiry = DateTime.now().add(const Duration(days: 7));
    await _secureStorage.saveOfflineExpiry(expiry);
  }

  Future<void> clearSession() async {
    await _secureStorage.clearSession();
  }

  Future<bool> validateOfflineLogin(String email) async {
    final cachedUser = await _secureStorage.getUser();
    if (cachedUser == null) return false;
    
    // Validate email case insensitively
    if (cachedUser.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      return false;
    }

    // Check offline expiry policy
    final expiry = await _secureStorage.getOfflineExpiry();
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      return false; // offline session expired
    }

    return true;
  }

  Future<AuthUser?> getCachedUser() => _secureStorage.getUser();
  Future<AuthTokens?> getCachedTokens() => _secureStorage.getTokens();
  Future<CompanySession?> getCachedCompany() => _secureStorage.getCompany();
  Future<String?> getSignature() => _secureStorage.getSignature();
  Future<void> saveSignature(String signatureBase64) => _secureStorage.saveSignature(signatureBase64);
}
