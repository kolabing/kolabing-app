import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';
import 'package:kolabing_app/features/settings/providers/notification_settings_provider.dart';

class _RecordingProfileService extends ProfileService {
  Map<String, bool>? lastPayload;

  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    lastPayload = prefs;
    return NotificationPreferences.fromJson(
      prefs.map((k, v) => MapEntry<String, dynamic>(k, v)),
    );
  }
}

void main() {
  test('setPreference PUTs events_enabled', () async {
    final service = _RecordingProfileService();
    final container = ProviderContainer(
      overrides: [profileServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(notificationSettingsProvider.notifier);
    await notifier.setPreference(
      const NotificationPreferences().copyWith(eventsEnabled: false),
    );

    expect(
      service.lastPayload,
      containsPair('events_enabled', false),
      reason:
          '_payload is a hand-written whitelist, not toJson() — a new pref must '
          'be added there too or the toggle is a dead switch',
    );
  });

  test('setPreference still PUTs every pre-existing preference key', () async {
    final service = _RecordingProfileService();
    final container = ProviderContainer(
      overrides: [profileServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container
        .read(notificationSettingsProvider.notifier)
        .setPreference(const NotificationPreferences());

    expect(
      service.lastPayload?.keys,
      containsAll(<String>[
        'message_notifications',
        'messages_enabled',
        'new_application_alerts',
        'applications_enabled',
        'collaboration_updates',
        'collaborations_enabled',
        'marketing_tips',
        'marketing_enabled',
      ]),
    );
  });

  test('turning events off survives a backend that omits the key', () async {
    final container = ProviderContainer(
      overrides: [
        profileServiceProvider.overrideWithValue(_ColumnlessProfileService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(notificationSettingsProvider.notifier);
    await notifier.setPreference(
      const NotificationPreferences().copyWith(eventsEnabled: false),
    );

    expect(
      container.read(notificationSettingsProvider).value?.eventsEnabled,
      isFalse,
      reason: 'the switch must not snap back on when the server drops the key',
    );
  });
}

class _ColumnlessProfileService extends ProfileService {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    // Today's backend has no `events_enabled` column (kolabing-v2#252), so the
    // 200 body comes back without the key.
    final echoed = Map<String, dynamic>.from(prefs)..remove('events_enabled');
    return NotificationPreferences.fromJson(echoed);
  }
}
