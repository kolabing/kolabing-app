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
  applicationDeclined,

  /// Your application was withdrawn
  applicationWithdrawn,

  /// A rewards badge was awarded to the user
  badgeAwarded,

  /// A challenge was verified
  challengeVerified,

  /// A reward was won
  rewardWon,

  /// Day-of collab reminder ("Today's your Kolab!")
  collabDayReminder,

  /// Follow-up reminder for uncompleted collab ("Did it happen?")
  collabFollowUpReminder,

  /// A collaboration was created from an accepted application
  collaborationCreated,

  /// A collaboration moved into its active state
  collaborationActivated,

  /// Feedback was received for a collaboration
  collaborationFeedbackReceived,

  /// A collaboration was completed
  collaborationCompleted,

  /// A collaboration was cancelled
  collaborationCancelled,

  /// A backend type the current app does not handle explicitly yet
  unknown;

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
      case 'application_withdrawn':
        return NotificationType.applicationWithdrawn;
      case 'badge_awarded':
        return NotificationType.badgeAwarded;
      case 'challenge_verified':
        return NotificationType.challengeVerified;
      case 'reward_won':
        return NotificationType.rewardWon;
      case 'collab_day_reminder':
        return NotificationType.collabDayReminder;
      case 'collab_followup_reminder':
        return NotificationType.collabFollowUpReminder;
      case 'collaboration_created':
        return NotificationType.collaborationCreated;
      case 'collaboration_activated':
        return NotificationType.collaborationActivated;
      case 'collaboration_feedback_received':
        return NotificationType.collaborationFeedbackReceived;
      case 'collaboration_completed':
        return NotificationType.collaborationCompleted;
      case 'collaboration_cancelled':
        return NotificationType.collaborationCancelled;
      default:
        return NotificationType.unknown;
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
      case NotificationType.applicationWithdrawn:
        return 'application_withdrawn';
      case NotificationType.badgeAwarded:
        return 'badge_awarded';
      case NotificationType.challengeVerified:
        return 'challenge_verified';
      case NotificationType.rewardWon:
        return 'reward_won';
      case NotificationType.collabDayReminder:
        return 'collab_day_reminder';
      case NotificationType.collabFollowUpReminder:
        return 'collab_followup_reminder';
      case NotificationType.collaborationCreated:
        return 'collaboration_created';
      case NotificationType.collaborationActivated:
        return 'collaboration_activated';
      case NotificationType.collaborationFeedbackReceived:
        return 'collaboration_feedback_received';
      case NotificationType.collaborationCompleted:
        return 'collaboration_completed';
      case NotificationType.collaborationCancelled:
        return 'collaboration_cancelled';
      case NotificationType.unknown:
        return 'unknown';
    }
  }
}

enum NotificationPriority {
  high,
  normal,
  low;

  static NotificationPriority fromString(String value) {
    switch (value) {
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      case 'normal':
      default:
        return NotificationPriority.normal;
    }
  }
}

/// A single in-app notification
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.notificationId,
    required this.type,
    required this.rawType,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.deeplink,
    this.priority = NotificationPriority.normal,
    this.actorName,
    this.actorAvatarUrl,
    this.targetId,
    this.targetType,
  });

  /// Notification row ID used by read/unread APIs
  final String id;
  final String notificationId;
  final NotificationType type;
  final String rawType;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String? deeplink;
  final NotificationPriority priority;

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
    final rawType = json['type'] as String? ?? '';
    final id =
        json['id']?.toString() ?? json['notification_id']?.toString() ?? '';
    final notificationId = json['notification_id']?.toString() ?? id;

    return AppNotification(
      id: id,
      notificationId: notificationId,
      type: NotificationType.fromString(rawType),
      rawType: rawType,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      deeplink: json['deeplink'] as String?,
      priority: NotificationPriority.fromString(
        json['priority'] as String? ?? 'normal',
      ),
      actorName: json['actor_name'] as String?,
      actorAvatarUrl: json['actor_avatar_url'] as String?,
      targetId: json['target_id']?.toString(),
      targetType: json['target_type'] as String?,
    );
  }

  AppNotification copyWith({
    String? id,
    String? notificationId,
    NotificationType? type,
    String? rawType,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? deeplink,
    NotificationPriority? priority,
    String? actorName,
    String? actorAvatarUrl,
    String? targetId,
    String? targetType,
  }) => AppNotification(
    id: id ?? this.id,
    notificationId: notificationId ?? this.notificationId,
    type: type ?? this.type,
    rawType: rawType ?? this.rawType,
    title: title ?? this.title,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    isRead: isRead ?? this.isRead,
    readAt: readAt ?? this.readAt,
    deeplink: deeplink ?? this.deeplink,
    priority: priority ?? this.priority,
    actorName: actorName ?? this.actorName,
    actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
    targetId: targetId ?? this.targetId,
    targetType: targetType ?? this.targetType,
  );
}
