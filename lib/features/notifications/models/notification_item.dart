/// Notification domain model representing persistent role-routed in-app alerts.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.role,
    required this.title,
    required this.message,
    required this.type,
    this.entityType,
    this.entityId,
    this.isRead = false,
    this.readAt,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String role;
  final String title;
  final String message;
  final String type;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: (json['role'] as String?) ?? 'customer',
      title: json['title'] as String,
      message: json['message'] as String,
      type: (json['type'] as String?) ?? 'service_status',
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'title': title,
      'message': message,
      'type': type,
      'entity_type': entityType,
      'entity_id': entityId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? role,
    String? title,
    String? message,
    String? type,
    String? entityType,
    String? entityId,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
