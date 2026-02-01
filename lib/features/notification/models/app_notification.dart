import 'package:flutter/foundation.dart';

/// Notification types matching backend categories
enum NotificationType {
  /// New message received in an application chat
  newMessage,

  /// New application received for your opportunity
  applicationReceived,

  /// Your application was accepted
  applicationAccepted,

  /// Your application was declined
  applicationDeclined;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'new_message':
        return NotificationType.newMessage;
      case 'application_received':
        return NotificationType.applicationReceived;
      case 'application_accepted':
        return NotificationType.applicationAccepted;
      case 'application_declined':
        return NotificationType.applicationDeclined;
      default:
        return NotificationType.newMessage;
    }
  }

  String toJson() {
    switch (this) {
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.applicationReceived:
        return 'application_received';
      case NotificationType.applicationAccepted:
        return 'application_accepted';
      case NotificationType.applicationDeclined:
        return 'application_declined';
    }
  }
}

/// A single in-app notification
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.actorName,
    this.actorAvatarUrl,
    this.targetId,
    this.targetType,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  /// Who triggered the notification (sender name)
  final String? actorName;

  /// Avatar URL of the actor
  final String? actorAvatarUrl;

  /// ID of the related entity (application ID, opportunity ID, etc.)
  final String? targetId;

  /// Type of the related entity ('application', 'opportunity', etc.)
  final String? targetType;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      actorName: json['actor_name'] as String?,
      actorAvatarUrl: json['actor_avatar_url'] as String?,
      targetId: json['target_id']?.toString(),
      targetType: json['target_type'] as String?,
    );
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? actorName,
    String? actorAvatarUrl,
    String? targetId,
    String? targetType,
  }) =>
      AppNotification(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        actorName: actorName ?? this.actorName,
        actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
        targetId: targetId ?? this.targetId,
        targetType: targetType ?? this.targetType,
      );
}
