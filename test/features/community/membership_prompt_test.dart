import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/event_checkin.dart';

/// What a check-in has to say before the app asks anyone to join (#148).
///
/// The interesting case is the null one: an older backend does not send
/// `is_member` at all, and treating that absence as "no" would ask everyone to
/// join a community the app cannot even name.
void main() {
  EventCheckin parse(Map<String, dynamic> extra) => EventCheckin.fromJson({
    'id': 'c-1',
    'event_id': 'e-1',
    'profile_id': 'p-1',
    'checked_in_at': '2026-08-23T18:00:00Z',
    'created_at': '2026-08-23T18:00:00Z',
    ...extra,
  });

  test('a non-member at a community event is worth asking', () {
    final checkin = parse({
      'community': {'id': 'com-1', 'name': 'Eixample Runners'},
      'is_member': false,
    });

    expect(checkin.communityId, 'com-1');
    expect(checkin.communityName, 'Eixample Runners');
    expect(checkin.canOfferMembership, isTrue);
  });

  test('an existing member is never asked', () {
    final checkin = parse({
      'community': {'id': 'com-1', 'name': 'Eixample Runners'},
      'is_member': true,
    });

    expect(checkin.canOfferMembership, isFalse);
  });

  test('an event with no community has nothing to offer', () {
    final checkin = parse({'community': null, 'is_member': null});

    expect(checkin.communityId, isNull);
    expect(checkin.canOfferMembership, isFalse);
  });

  /// The self-gate: absent is not "no". A backend without #148 deployed sends
  /// neither key, and the app must stay quiet rather than invent a prompt.
  test('a payload from an older backend offers nothing', () {
    final checkin = parse(const <String, dynamic>{});

    expect(checkin.isMember, isNull);
    expect(checkin.canOfferMembership, isFalse);
  });

  test('the fields survive a round trip', () {
    final checkin = parse({
      'community': {'id': 'com-1', 'name': 'Eixample Runners'},
      'is_member': false,
    });

    final again = EventCheckin.fromJson(checkin.toJson());

    expect(again.communityId, 'com-1');
    expect(again.communityName, 'Eixample Runners');
    expect(again.isMember, isFalse);
    expect(again.canOfferMembership, isTrue);
  });
}
