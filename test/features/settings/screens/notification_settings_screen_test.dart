import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/settings/providers/notification_settings_provider.dart';
import 'package:kolabing_app/features/settings/providers/push_permission_provider.dart';
import 'package:kolabing_app/features/settings/screens/notification_settings_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

void main() {
  // Everything the backend defaults to "on" for a brand-new account.
  const allOn = NotificationPreferences();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool pushGranted,
    NotificationPreferences prefs = allOn,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationSettingsProvider.overrideWith(
            () => _FakeSettingsNotifier(prefs),
          ),
          pushPermissionGrantedProvider.overrideWith((ref) async => pushGranted),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<bool> switchValues(WidgetTester tester) => tester
      .widgetList<SwitchListTile>(find.byType(SwitchListTile))
      .map((tile) => tile.value)
      .toList();

  testWidgets(
    'every toggle reads off while the OS permission is missing (Apple 4.5.4)',
    (tester) async {
      // The rejection: "the toggle in the app settings was pre-set to enable
      // notifications". Stored prefs say on, the OS says nothing is delivered —
      // the UI must not claim otherwise.
      await pumpScreen(tester, pushGranted: false);

      expect(switchValues(tester), <bool>[false, false, false, false]);
    },
  );

  testWidgets('the off-state explains itself and offers the opt-in', (
    tester,
  ) async {
    await pumpScreen(tester, pushGranted: false);

    expect(find.text('Notifications are off'), findsOneWidget);
    expect(find.text('Turn on notifications'), findsOneWidget);
  });

  testWidgets('stored preferences show through once permission is granted', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      pushGranted: true,
      prefs: const NotificationPreferences(
        messagesEnabled: true,
        applicationsEnabled: false,
        collaborationsEnabled: true,
        marketingEnabled: false,
      ),
    );

    expect(switchValues(tester), <bool>[true, false, true, false]);
    expect(find.text('Notifications are off'), findsNothing);
  });

  testWidgets('a granted permission never forces a toggle on', (tester) async {
    await pumpScreen(
      tester,
      pushGranted: true,
      prefs: const NotificationPreferences(
        messagesEnabled: false,
        applicationsEnabled: false,
        collaborationsEnabled: false,
        marketingEnabled: false,
      ),
    );

    expect(switchValues(tester), <bool>[false, false, false, false]);
  });
}

class _FakeSettingsNotifier extends NotificationSettingsNotifier {
  _FakeSettingsNotifier(this._prefs);

  final NotificationPreferences _prefs;

  @override
  AsyncValue<NotificationPreferences> build() => AsyncData(_prefs);
}
