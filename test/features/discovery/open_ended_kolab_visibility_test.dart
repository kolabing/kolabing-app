import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/screens/explore_screen.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/discovery/models/explore_feed_item.dart';

/// An open-ended Kolab — one the API sends with `availability.end == null` —
/// must reach the Explore deck.
///
/// Reported from production: a community account filtering Explore by Mexico
/// City saw the filter report one result and the deck render nothing. The API
/// was returning that Kolab correctly at every layer (service, paginator,
/// resource); the app dropped it client-side.
///
/// The cause was `_parseDate(null)` defaulting to `DateTime.now()`, so an
/// open-ended Kolab starting tomorrow parsed as `end = today`, which is
/// *before* its own start. `buildSelectableApplicationDates` then produced no
/// selectable dates and `filterExploreDeckItems` removed the card.
///
/// The fix makes the client read an absent end as the server does —
/// `COALESCE(availability_end, availability_start)` — so the two agree about
/// which Kolabs are open. Note how narrow the old window was: an open-ended
/// Kolab was visible only on the single day its start date equalled today, and
/// the server hid it from the day after. That is why this went unnoticed.
void main() {
  // Fixed, so these tests do not change meaning with the calendar.
  final DateTime today = DateTime(2026, 9, 22);

  DiscoveryItem offer({
    required String id,
    required String start,
    String? end,
  }) {
    return DiscoveryItem.fromJson(<String, dynamic>{
      'id': id,
      'creator_type': 'business',
      'intent_type': 'venue_promotion',
      'title': 'Kolab $id',
      'description': 'desc',
      'preferred_city': 'Mexico City',
      'availability': <String, dynamic>{
        'mode': 'flexible',
        'start': start,
        if (end != null) 'end': end,
      },
      'creator_profile': <String, dynamic>{'id': 'creator-$id'},
    });
  }

  List<ExploreFeedItem> visible(List<DiscoveryItem> offers) =>
      filterExploreDeckItems(
        offers.map<ExploreFeedItem>(ExploreOfferItem.new).toList(),
        blockedProfileIds: <String>{},
        myProfileId: 'viewer-1',
        today: today,
        isCommunityViewer: true,
      );

  group('open-ended Kolabs in the Explore deck', () {
    test('an open-ended Kolab starting tomorrow is shown', () {
      // The exact production row: starts 2026-09-23, no end date.
      final result = visible(<DiscoveryItem>[
        offer(id: 'mexico-city', start: '2026-09-23'),
      ]);

      expect(
        result,
        hasLength(1),
        reason: 'The API counts this Kolab; the deck must not silently drop it.',
      );
    });

    test('an open-ended Kolab starting today is shown', () {
      expect(visible(<DiscoveryItem>[offer(id: 'today', start: '2026-09-22')]),
          hasLength(1));
    });

    test('an absent end date is read as the start date, not as now()', () {
      final item = offer(id: 'x', start: '2026-09-23');

      expect(item.availability.end, DateTime.parse('2026-09-23'));
    });

    test('an explicit end date is still honoured', () {
      final item = offer(id: 'x', start: '2026-09-23', end: '2026-10-30');

      expect(item.availability.end, DateTime.parse('2026-10-30'));
    });

    /// The fix must not resurrect genuinely expired Kolabs. An open-ended Kolab
    /// whose start has passed is closed on the server too
    /// (`COALESCE(end, start) >= today` fails), so the two still agree.
    test('an open-ended Kolab whose start has passed stays hidden', () {
      expect(
        visible(<DiscoveryItem>[offer(id: 'past', start: '2026-09-19')]),
        isEmpty,
        reason: 'COALESCE(end, start) is in the past — the server hides it too.',
      );
    });

    test('a dated window that has fully expired stays hidden', () {
      expect(
        visible(<DiscoveryItem>[
          offer(id: 'expired', start: '2026-08-01', end: '2026-08-31'),
        ]),
        isEmpty,
      );
    });

    test('a dated window still running is shown', () {
      expect(
        visible(<DiscoveryItem>[
          offer(id: 'running', start: '2026-09-01', end: '2026-10-31'),
        ]),
        hasLength(1),
      );
    });
  });
}
