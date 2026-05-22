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
}
