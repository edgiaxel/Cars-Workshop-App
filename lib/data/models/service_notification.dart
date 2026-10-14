/// Domain model for public.notifications table.
class ServiceNotification {
  const ServiceNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    this.priority = 'normal',
    required this.title,
    required this.message,
    this.serviceOrderId,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String recipientId;
  final String
  type; // 'booking', 'service', 'inventory', 'payment', 'reminder', 'system'
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final String title;
  final String message;
  final String? serviceOrderId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory ServiceNotification.fromJson(Map<String, dynamic> json) {
    return ServiceNotification(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      type: json['type'] as String? ?? 'system',
      priority: json['priority'] as String? ?? 'normal',
      title: json['title'] as String,
      message: json['message'] as String,
      serviceOrderId: json['service_order_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'type': type,
      'priority': priority,
      'title': title,
      'message': message,
      if (serviceOrderId != null) 'service_order_id': serviceOrderId,
      'is_read': isRead,
    };
  }

  ServiceNotification copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? priority,
    String? title,
    String? message,
    String? serviceOrderId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ServiceNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
