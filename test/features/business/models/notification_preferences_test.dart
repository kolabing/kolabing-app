import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';

void main() {
  test('fromJson reads new backend preference keys', () {
    final prefs = NotificationPreferences.fromJson(<String, dynamic>{
      'email_notifications': true,
      'whatsapp_notifications': false,
      'messages_enabled': false,
      'applications_enabled': true,
      'collaborations_enabled': false,
      'rewards_enabled': true,
      'marketing_enabled': true,
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '08:00',
      'timezone': 'Europe/Istanbul',
    });

    expect(prefs.emailNotifications, isTrue);
    expect(prefs.whatsappNotifications, isFalse);
    expect(prefs.messagesEnabled, isFalse);
    expect(prefs.applicationsEnabled, isTrue);
    expect(prefs.collaborationsEnabled, isFalse);
    expect(prefs.rewardsEnabled, isTrue);
    expect(prefs.marketingEnabled, isTrue);
    expect(prefs.quietHoursStart, '22:00');
    expect(prefs.quietHoursEnd, '08:00');
    expect(prefs.timezone, 'Europe/Istanbul');
  });

  test(
    'fromJson prefers message_notifications over messages_enabled (NF-16)',
    () {
      final prefs = NotificationPreferences.fromJson(<String, dynamic>{
        'message_notifications': false,
        'messages_enabled': true,
      });
      expect(prefs.messagesEnabled, isFalse);
      expect(prefs.messageNotifications, isFalse);
    },
  );

  test('message_notifications defaults on when both keys absent', () {
    final prefs = NotificationPreferences.fromJson(<String, dynamic>{});
    expect(prefs.messagesEnabled, isTrue);
  });

  test('toJson writes both message keys for forward/back compatibility', () {
    final json = const NotificationPreferences(messagesEnabled: false).toJson();
    expect(json['message_notifications'], isFalse);
    expect(json['messages_enabled'], isFalse);
  });

  // #191 — event reminders opt-out.
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
