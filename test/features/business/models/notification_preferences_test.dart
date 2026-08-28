import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';

void main() {
  test('eventsEnabled defaults on when the backend omits the key', () {
    final prefs = NotificationPreferences.fromJson(<String, dynamic>{});

    // Opt-out semantics: a missing row/key must never mute an existing user.
    expect(prefs.eventsEnabled, isTrue);
  });

  test('eventsEnabled round-trips through fromJson and toJson', () {
    final prefs = NotificationPreferences.fromJson(<String, dynamic>{
      'events_enabled': false,
    });

    expect(prefs.eventsEnabled, isFalse);
    expect(prefs.toJson()['events_enabled'], isFalse);
  });

  test('copyWith can flip eventsEnabled without touching the rest', () {
    const prefs = NotificationPreferences();
    final updated = prefs.copyWith(eventsEnabled: false);

    expect(updated.eventsEnabled, isFalse);
    expect(updated.messagesEnabled, prefs.messagesEnabled);
    expect(updated.marketingEnabled, prefs.marketingEnabled);
  });
}
