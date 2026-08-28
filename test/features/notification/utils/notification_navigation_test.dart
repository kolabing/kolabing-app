import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/notification/utils/notification_navigation.dart';

void main() {
  test('resolveNotificationRoute prefers supported deeplink', () {
    final route = resolveNotificationRoute(
      type: 'application_received',
      id: 'app-1',
      deeplink: '/community/wallet',
    );

    expect(route, KolabingRoutes.communityWallet);
  });

  test(
    'resolveNotificationRoute falls back to legacy route when deeplink missing',
    () {
      final route = resolveNotificationRoute(type: 'new_message', id: 'app-42');

      expect(
        route,
        KolabingRoutes.applicationChat.replaceFirst(':id', 'app-42'),
      );
    },
  );

  for (final type in const <String>[
    'collaboration_created',
    'collaboration_activated',
    'collaboration_feedback_received',
    'collaboration_completed',
    'collaboration_cancelled',
  ]) {
    test('resolveNotificationRoute routes $type to collaboration detail', () {
      final route = resolveNotificationRoute(
        type: type,
        id: 'col-7',
        targetType: 'collaboration',
      );

      expect(
        route,
        KolabingRoutes.collaborationDetails.replaceFirst(':id', 'col-7'),
      );
    });
  }

  test('resolveNotificationRoute routes application_withdrawn to detail', () {
    final route = resolveNotificationRoute(
      type: 'application_withdrawn',
      id: 'app-9',
      targetType: 'application',
    );

    expect(
      route,
      KolabingRoutes.applicationDetails.replaceFirst(':id', 'app-9'),
    );
  });

  test(
    'resolveNotificationRoute falls back to notifications for unsupported input',
    () {
      final route = resolveNotificationRoute(
        type: 'totally_unknown_type',
        deeplink: '/not-a-real-route',
      );

      expect(route, KolabingRoutes.notifications);
    },
  );

  test('resolveNotificationRoute routes event reminders to event detail', () {
    for (final type in const ['event_reminder_24h', 'event_reminder_1h']) {
      expect(
        resolveNotificationRoute(type: type, id: 'event-1'),
        '/event/event-1',
        reason: '$type should open the event, not the notifications list',
      );
    }
  });

  test('resolveNotificationRoute keeps an event deeplink over the type branch', () {
    // A path-form deeplink wins over the type-derived route when they disagree.
    // NB: a custom-scheme deeplink (`kolabing://event/event-2`) does NOT work
    // here — Uri parsing eats `event` as the host, leaving an unsupported
    // `/event-2` path. Logged as FX in BACKLOG; the type branch masks it today.
    expect(
      resolveNotificationRoute(
        type: 'event_reminder_1h',
        id: 'event-1',
        deeplink: '/event/event-2',
      ),
      '/event/event-2',
    );
  });
}
