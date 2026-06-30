class AppNotification {
  final String id;
  final String message;
  final String type;
  final String target;
  final bool isRead;
  final DateTime createdAt;
  final String? actionLink;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.target,
    required this.isRead,
    required this.createdAt,
    this.actionLink,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      target: json['target'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      actionLink: json['actionLink'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? message,
    String? type,
    String? target,
    bool? isRead,
    DateTime? createdAt,
    String? actionLink,
  }) {
    return AppNotification(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      target: target ?? this.target,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionLink: actionLink ?? this.actionLink,
    );
  }
}
