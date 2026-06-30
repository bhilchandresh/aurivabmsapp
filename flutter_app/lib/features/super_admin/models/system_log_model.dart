class SystemLogModel {
  final String id;
  final DateTime createdAt;
  final String action;
  final String details;
  final String userName;

  SystemLogModel({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.details,
    required this.userName,
  });

  factory SystemLogModel.fromJson(Map<String, dynamic> json) {
    return SystemLogModel(
      id: json['_id'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      action: json['action'] ?? 'UNKNOWN',
      details: json['details'] ?? '',
      userName: json['tenantId'] != null
          ? (json['tenantId']['name'] ?? 'System')
          : 'System',
    );
  }
}
