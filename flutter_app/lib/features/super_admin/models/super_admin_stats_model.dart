class SuperAdminStatsModel {
  final int totalTenants;
  final int activeTenants;
  final int totalUsers;
  final num estRevenue;

  SuperAdminStatsModel({
    required this.totalTenants,
    required this.activeTenants,
    required this.totalUsers,
    required this.estRevenue,
  });

  factory SuperAdminStatsModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminStatsModel(
      totalTenants: json['totalTenants'] ?? 0,
      activeTenants: json['activeTenants'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      estRevenue: json['estRevenue'] ?? 0,
    );
  }
}
