import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/notification/models/app_notification.dart';

void main() {
  test('fromJson preserves deeplink and supported raw type', () {
    final notification = AppNotification.fromJson(<String, dynamic>{
      'id': 'notif-1',
      'notification_id': 'notif-1',
      'type': 'application_received',
      'title': 'New application received',
      'body': 'Ayse applied to Sunset Rooftop Campaign',
      'deeplink': '/application/app-1',
      'priority': 'high',
      'is_read': false,
      'created_at': '2026-05-09T10:20:30Z',
      'target_id': 'app-1',
      'target_type': 'application',
    });

    expect(notification.id, 'notif-1');
    expect(notification.notificationId, 'notif-1');
    expect(notification.type, NotificationType.applicationReceived);
    expect(notification.rawType, 'application_received');
    expect(notification.deeplink, '/application/app-1');
    expect(notification.priority, NotificationPriority.high);
  });

  test('fromJson parses collaboration completion-flow types', () {
    const cases = <String, NotificationType>{
      'collaboration_created': NotificationType.collaborationCreated,
      'collaboration_activated': NotificationType.collaborationActivated,
      'collaboration_feedback_received':
          NotificationType.collaborationFeedbackReceived,
      'collaboration_completed': NotificationType.collaborationCompleted,
      'collaboration_cancelled': NotificationType.collaborationCancelled,
    };

    cases.forEach((rawType, expectedType) {
      final notification = AppNotification.fromJson(<String, dynamic>{
        'id': 'notif-$rawType',
        'type': rawType,
        'title': 'Collaboration update',
        'body': 'Your collaboration changed state',
        'deeplink': '/collaboration/col-1',
        'priority': 'normal',
        'is_read': false,
        'created_at': '2026-05-09T10:20:30Z',
        'target_id': 'col-1',
        'target_type': 'collaboration',
      });

      expect(notification.type, expectedType);
      expect(notification.rawType, rawType);
      expect(notification.type.toJson(), rawType);
      expect(notification.deeplink, '/collaboration/col-1');
    });
  });

  test('fromJson parses application_withdrawn with round-trip toJson', () {
    final notification = AppNotification.fromJson(<String, dynamic>{
      'id': 'notif-withdrawn',
      'type': 'application_withdrawn',
      'title': 'Application withdrawn',
      'body': 'Ayse withdrew their application',
      'deeplink': '/application/app-1',
      'priority': 'normal',
      'is_read': false,
      'created_at': '2026-05-09T10:20:30Z',
      'target_id': 'app-1',
      'target_type': 'application',
    });

    expect(notification.type, NotificationType.applicationWithdrawn);
    expect(notification.rawType, 'application_withdrawn');
    expect(notification.type.toJson(), 'application_withdrawn');
    expect(notification.deeplink, '/application/app-1');
  });

  test('fromJson maps unsupported types to unknown instead of new message', () {
    final notification = AppNotification.fromJson(<String, dynamic>{
      'id': 'notif-2',
      'type': 'collaboration_scheduled',
      'title': 'Collaboration scheduled',
      'body': 'Your collaboration has been scheduled',
      'deeplink': '/collaboration/col-1',
      'priority': 'normal',
      'is_read': false,
      'created_at': '2026-05-09T10:20:30Z',
    });

    expect(notification.type, NotificationType.unknown);
    expect(notification.rawType, 'collaboration_scheduled');
    expect(notification.deeplink, '/collaboration/col-1');
    expect(notification.priority, NotificationPriority.normal);
  });
}
