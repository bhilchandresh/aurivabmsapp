import '../models/auth_user.dart';
import '../models/auth_tokens.dart';
import '../models/company_session.dart';

class AuthMapper {
  static AuthUser fromLoginResponse(Map<String, dynamic> response) {
    final userJson = response['user'] ?? {};
    final tenantJson = response['tenant'] ?? {};
    
    // Map permissions
    final List<String> permissions = List<String>.from(userJson['permissions'] ?? []);
    if (permissions.isEmpty) {
      // Add default permissions fallback
      permissions.addAll([
        'invoices:rwda',
        'inventory:rwda',
        'clients:rwda',
        'expenses:rwda',
        'quotations:rwda',
        'dashboard:r',
        'settings:r',
      ]);
    }

    return AuthUser(
      userId: userJson['_id'] ?? userJson['id'] ?? '',
      companyId: tenantJson['_id'] ?? tenantJson['id'] ?? userJson['companyId'] ?? '',
      name: userJson['name'] ?? '',
      email: userJson['email'] ?? '',
      phone: userJson['phone'] ?? userJson['phoneNumber'] ?? '',
      avatar: userJson['signatureImage'] ?? '',
      roleId: userJson['roleId'] ?? '',
      roleName: userJson['role'] ?? 'Employee',
      permissions: permissions,
      language: userJson['language'] ?? 'en',
      timezone: userJson['timezone'] ?? 'Asia/Kolkata',
      currency: userJson['currency'] ?? 'INR',
      lastLogin: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static AuthTokens tokensFromLoginResponse(Map<String, dynamic> response) {
    return AuthTokens(
      accessToken: response['token'] ?? response['accessToken'] ?? '',
      refreshToken: response['refreshToken'] ?? '',
      expiresAt: DateTime.now().add(const Duration(minutes: 60)),
      refreshExpiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  static CompanySession companyFromTenantSettings(Map<String, dynamic> settingsJson, String companyId) {
    return CompanySession(
      companyId: companyId,
      companyName: settingsJson['name'] ?? '',
      logo: settingsJson['logoImage'] ?? '',
      branchId: '',
      branchName: '',
      fiscalYear: '',
      subscriptionPlan: 'business',
      currency: 'INR',
      timezone: 'Asia/Kolkata',
      language: 'en',
    );
  }
}
