class AuthUser {
  final String userId;
  final String companyId;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final String roleId;
  final String roleName;
  final List<String> permissions;
  final String language;
  final String timezone;
  final String currency;
  final DateTime lastLogin;
  final DateTime updatedAt;

  AuthUser({
    required this.userId,
    required this.companyId,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.roleId,
    required this.roleName,
    required this.permissions,
    required this.language,
    required this.timezone,
    required this.currency,
    required this.lastLogin,
    required this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['_id'] ?? json['id'] ?? json['userId'] ?? '',
      companyId: json['companyId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      avatar: json['avatar'] ?? json['avatarUrl'] ?? '',
      roleId: json['roleId'] ?? '',
      roleName: json['role'] ?? json['roleName'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      language: json['language'] ?? 'en',
      timezone: json['timezone'] ?? 'UTC',
      currency: json['currency'] ?? 'INR',
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin'].toString()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'companyId': companyId,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'roleId': roleId,
      'role': roleName,
      'permissions': permissions,
      'language': language,
      'timezone': timezone,
      'currency': currency,
      'lastLogin': lastLogin.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
