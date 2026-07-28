import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/application/widgets/apply_modal.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

void main() {
  test(
    'buildSelectableApplicationDates keeps only the marked recurring days',
    () {
      final opportunity = Opportunity(
        id: 'opp-1',
        title: 'Training & Brunch',
        description: 'Community brunch',
        businessOffer: const BusinessOffer(),
        communityDeliverables: const CommunityDeliverables(),
        categories: const <String>['Wellness'],
        availabilityMode: AvailabilityMode.recurring,
        availabilityStart: DateTime(2030, 6, 10),
        availabilityEnd: DateTime(2030, 6, 16),
        recurringDays: const <int>[2, 4],
        venueMode: VenueMode.businessVenue,
        preferredCity: 'Barcelona',
      );

      final dates = buildSelectableApplicationDates(
        opportunity,
        today: DateTime(2030, 6, 10),
      );

      expect(
        dates.map((date) => date.weekday).toList(),
        everyElement(anyOf(2, 4)),
      );
      expect(dates.map((date) => date.day).toList(), <int>[11, 13]);
    },
  );

  group('opportunityApplicationsOpen', () {
    Opportunity build({
      required AvailabilityMode mode,
      required DateTime start,
      required DateTime end,
      List<int> recurringDays = const <int>[],
      OpportunityStatus status = OpportunityStatus.published,
    }) => Opportunity(
      id: 'opp-1',
      title: 'T',
      description: 'D',
      businessOffer: const BusinessOffer(),
      communityDeliverables: const CommunityDeliverables(),
      categories: const <String>['Wellness'],
      availabilityMode: mode,
      availabilityStart: start,
      availabilityEnd: end,
      recurringDays: recurringDays,
      venueMode: VenueMode.businessVenue,
      preferredCity: 'Barcelona',
      status: status,
    );

    final today = DateTime(2030, 6, 10); // a Monday

    test('open when a one-time window is still in the future', () {
      final o = build(
        mode: AvailabilityMode.oneTime,
        start: DateTime(2030, 6, 10),
        end: DateTime(2030, 6, 16),
      );
      expect(opportunityApplicationsOpen(o, today: today), isTrue);
    });

    test('closed when the window is entirely in the past', () {
      final o = build(
        mode: AvailabilityMode.oneTime,
        start: DateTime(2020, 1, 1),
        end: DateTime(2020, 1, 5),
      );
      expect(opportunityApplicationsOpen(o, today: today), isFalse);
    });

    test('open when a recurring day still falls in the remaining window', () {
      final o = build(
        mode: AvailabilityMode.recurring,
        start: DateTime(2030, 6, 10),
        end: DateTime(2030, 6, 16),
        recurringDays: const <int>[2, 4], // Tue, Thu
      );
      expect(opportunityApplicationsOpen(o, today: today), isTrue);
    });

    test(
      'open for a recurring window still in the future even when today is not '
      'a matching weekday (gate is genuine-expiry, not weekday-match)',
      () {
        final o = build(
          mode: AvailabilityMode.recurring,
          start: DateTime(2030, 6, 11), // Tue
          end: DateTime(2030, 6, 16), // Sun — window not yet ended
          recurringDays: const <int>[1], // Monday only
        );
        expect(opportunityApplicationsOpen(o, today: today), isTrue);
      },
    );

    test(
      'open for a degenerate window (start==end==today) — regression #94: '
      'discovery items with a defaulted window must not hide the whole feed',
      () {
        final o = build(
          mode: AvailabilityMode.recurring,
          start: today, // Mon 2030-06-10
          end: today,
          recurringDays: const <int>[6], // Saturday — never matches today
        );
        expect(opportunityApplicationsOpen(o, today: today), isTrue);
      },
    );

    test('closed when a recurring window has genuinely ended', () {
      final o = build(
        mode: AvailabilityMode.recurring,
        start: DateTime(2020, 1, 1),
        end: DateTime(2020, 1, 31),
        recurringDays: const <int>[2, 4],
      );
      expect(opportunityApplicationsOpen(o, today: today), isFalse);
    });

    test('closed when status is closed even with valid future dates', () {
      final o = build(
        mode: AvailabilityMode.oneTime,
        start: DateTime(2030, 6, 10),
        end: DateTime(2030, 6, 16),
        status: OpportunityStatus.closed,
      );
      expect(opportunityApplicationsOpen(o, today: today), isFalse);
    });

    test('closed when status is completed even with valid future dates', () {
      final o = build(
        mode: AvailabilityMode.oneTime,
        start: DateTime(2030, 6, 10),
        end: DateTime(2030, 6, 16),
        status: OpportunityStatus.completed,
      );
      expect(opportunityApplicationsOpen(o, today: today), isFalse);
    });
  });
}
