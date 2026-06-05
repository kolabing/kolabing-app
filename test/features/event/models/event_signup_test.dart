import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/event/models/event_signup.dart';

void main() {
  test('EventSignups.fromJson parses going + waitlist with profile', () {
    final signups = EventSignups.fromJson(<String, dynamic>{
      'going': [
        {
          'id': 's1',
          'profile_id': 'p1',
          'status': 'going',
          'profile': {'id': 'p1', 'name': 'Maria', 'avatar_url': 'http://a/1'},
        },
      ],
      'waitlist': [
        {
          'id': 's2',
          'profile_id': 'p2',
          'status': 'waitlisted',
          'waitlist_position': 1,
          'profile': {'id': 'p2', 'name': 'Lucia'},
        },
      ],
    });

    expect(signups.going.length, 1);
    expect(signups.going.first.name, 'Maria');
    expect(signups.going.first.avatarUrl, 'http://a/1');
    expect(signups.going.first.isWaitlisted, isFalse);

    expect(signups.waitlist.length, 1);
    expect(signups.waitlist.first.name, 'Lucia');
    expect(signups.waitlist.first.isWaitlisted, isTrue);
    expect(signups.waitlist.first.waitlistPosition, 1);
    expect(signups.waitlist.first.avatarUrl, isNull);
  });

  test('EventSignups.isEmpty when both lists empty / missing', () {
    expect(const EventSignups().isEmpty, isTrue);
    expect(EventSignups.fromJson(<String, dynamic>{}).isEmpty, isTrue);
  });
}
