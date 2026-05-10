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
}
