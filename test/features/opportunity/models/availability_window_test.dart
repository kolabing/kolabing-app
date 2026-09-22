import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/opportunity/models/availability_window.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

/// An availability bound the API omits must never become "today".
///
/// `_parseDate(null)` used to return `DateTime.now()` in both parsers. FX-57 was
/// that bug on `end`: an open-ended Kolab starting tomorrow parsed as
/// `end = today`, before its own start, so the client treated it as expired
/// while the API counted it — a Kolab visible to the filter and invisible in
/// the deck, reported from production (Mexico City, starts 2026-09-23).
///
/// FX-57 fixed `end`. The same invention still sat one field over: a null or
/// unreadable `start` produced `start = end = today`, a Kolab bookable for
/// exactly one day and then gone. `resolveAvailabilityWindow` reads every
/// missing bound the way the server reads it instead.
///
/// Which Kolabs reach Explore is no longer decided here at all — that is
/// `GET /discovery/opportunities` (kolabing-v2#316). These tests are about what
/// the payload MEANS, which is still the client's job.
void main() {
  // Fixed, so nothing here changes meaning with the calendar.
  final DateTime today = DateTime(2026, 9, 22);

  AvailabilityWindow resolve({Object? start, Object? end}) =>
      resolveAvailabilityWindow(rawStart: start, rawEnd: end, today: today);

  group('resolveAvailabilityWindow', () {
    test('both bounds present are taken as given', () {
      final window = resolve(start: '2026-09-23', end: '2026-10-30');

      expect(window.start, DateTime.parse('2026-09-23'));
      expect(window.end, DateTime.parse('2026-10-30'));
    });

    test(
      'an absent end is read as the start — the server\'s COALESCE rule',
      () {
        // The exact production row behind FX-57.
        final window = resolve(start: '2026-09-23');

        expect(window.end, DateTime.parse('2026-09-23'));
        expect(
          window.end.isBefore(window.start),
          isFalse,
          reason: 'An open-ended Kolab must never end before it starts.',
        );
      },
    );

    test('an absent start does not collapse the window onto today', () {
      final window = resolve(end: '2026-10-30');

      expect(window.start, today, reason: 'Open from today…');
      expect(
        window.end,
        DateTime.parse('2026-10-30'),
        reason: '…until the end',
      );
      expect(
        window.end.isAfter(window.start),
        isTrue,
        reason:
            'This is the bug FX-57 left one field over: start == end == now.',
      );
    });

    test('no window at all stays open, never expired', () {
      final window = resolve();

      expect(window.start, today);
      expect(window.end, today.add(kOpenEndedAvailabilityHorizon));
      expect(
        window.end.isAfter(window.start),
        isTrue,
        reason:
            'The server treats a kolab with no window as always bookable, so '
            'the client must not read it as ending today.',
      );
    });

    test('an unreadable bound is an ABSENT bound, not now()', () {
      final window = resolve(start: 'not-a-date', end: '2026-10-30');

      expect(window.start, today);
      expect(window.end, DateTime.parse('2026-10-30'));
    });

    test('an empty string is an absent bound', () {
      expect(parseAvailabilityDate(''), isNull);
      expect(parseAvailabilityDate('   '), isNull);
      expect(parseAvailabilityDate(null), isNull);
    });

    test('an end that already passed is left in the past, not stretched', () {
      final window = resolve(end: '2026-08-31');

      expect(window.end, DateTime.parse('2026-08-31'));
      expect(window.start.isAfter(window.end), isFalse);
    });
  });

  group('both parsers read a payload the same way', () {
    DiscoveryItem discoveryOffer({String? start, String? end}) =>
        DiscoveryItem.fromJson(<String, dynamic>{
          'id': 'k1',
          'creator_type': 'business',
          'intent_type': 'venue_promotion',
          'title': 'Kolab',
          'description': 'desc',
          'preferred_city': 'Mexico City',
          'availability': <String, dynamic>{
            'mode': 'flexible',
            if (start != null) 'start': start,
            if (end != null) 'end': end,
          },
          'creator_profile': <String, dynamic>{'id': 'creator-1'},
        });

    Opportunity opportunity({String? start, String? end}) =>
        Opportunity.fromJson(<String, dynamic>{
          'id': 'k1',
          'title': 'Kolab',
          'description': 'desc',
          'availability_mode': 'flexible',
          if (start != null) 'availability_start': start,
          if (end != null) 'availability_end': end,
        });

    test('an absent end resolves to the start in both', () {
      expect(
        discoveryOffer(start: '2026-09-23').availability.end,
        DateTime.parse('2026-09-23'),
      );
      expect(
        opportunity(start: '2026-09-23').availabilityEnd,
        DateTime.parse('2026-09-23'),
      );
    });

    test('an explicit end is honoured in both', () {
      expect(
        discoveryOffer(start: '2026-09-23', end: '2026-10-30').availability.end,
        DateTime.parse('2026-10-30'),
      );
      expect(
        opportunity(start: '2026-09-23', end: '2026-10-30').availabilityEnd,
        DateTime.parse('2026-10-30'),
      );
    });

    test('neither parser ever produces an end before its start', () {
      final discovery = discoveryOffer(start: '2099-01-01');
      final opp = opportunity(start: '2099-01-01');

      expect(
        discovery.availability.end.isBefore(discovery.availability.start),
        isFalse,
      );
      expect(opp.availabilityEnd.isBefore(opp.availabilityStart), isFalse);
    });
  });
}
