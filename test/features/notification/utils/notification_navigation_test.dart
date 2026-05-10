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

  test('resolveNotificationRoute falls back to legacy route when deeplink missing', () {
    final route = resolveNotificationRoute(
      type: 'new_message',
      id: 'app-42',
    );

    expect(
      route,
      KolabingRoutes.applicationChat.replaceFirst(':id', 'app-42'),
    );
  });

  test('resolveNotificationRoute falls back to notifications for unsupported input', () {
    final route = resolveNotificationRoute(
      type: 'totally_unknown_type',
      deeplink: '/not-a-real-route',
    );

    expect(route, KolabingRoutes.notifications);
  });
}
