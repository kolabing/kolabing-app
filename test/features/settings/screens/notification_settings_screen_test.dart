import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';
import 'package:kolabing_app/features/settings/screens/notification_settings_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

class _StubProfileService extends ProfileService {
  NotificationPreferences saved = const NotificationPreferences();

  @override
  Future<NotificationPreferences> getNotificationPreferences() async => saved;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    saved = saved.copyWith(eventsEnabled: prefs['events_enabled']);
    return saved;
  }
}

void main() {
  Widget harness(ProfileService service) => ProviderScope(
    overrides: [profileServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationSettingsScreen(),
    ),
  );

  testWidgets('event reminders toggle renders on by default', (tester) async {
    await tester.pumpWidget(harness(_StubProfileService()));
    await tester.pumpAndSettle();

    final toggle = find.widgetWithText(SwitchListTile, 'Event reminders');
    expect(toggle, findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets('turning it off writes events_enabled through', (tester) async {
    final service = _StubProfileService();
    await tester.pumpWidget(harness(service));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Event reminders'));
    await tester.pumpAndSettle();

    expect(service.saved.eventsEnabled, isFalse);
  });
}
