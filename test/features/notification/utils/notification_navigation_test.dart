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
}
