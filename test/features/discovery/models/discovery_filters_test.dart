import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';

void main() {
  test('serializes common filters and feed correctly', () {
    final filters = DiscoveryFilters(
      feed: DiscoveryFeed.all,
      searchQuery: 'wellness',
      city: 'Madrid',
      availabilityMode: 'recurring',
      availabilityFrom: DateTime(2026, 5, 20),
      availabilityTo: DateTime(2026, 5, 30),
      sort: 'recent',
    );

    expect(filters.toQueryParameters(), <String, String>{
      'feed': 'all',
      'search': 'wellness',
      'city': 'Madrid',
      'availability_mode': 'recurring',
      'availability_from': '2026-05-20',
      'availability_to': '2026-05-30',
      'sort': 'recent',
    });
  });

  test('serializes business and community filter arrays correctly', () {
    const filters = DiscoveryFilters(
      needTypes: <String>['food_drink', 'sponsor'],
      communityTypes: <String>['wellness'],
      audienceSizeBand: 'large',
      offersInReturn: <String>['social_media', 'event_activation'],
      venuePreferences: <String>['business_provides'],
      intentTypes: <String>['venue_promotion'],
      offerTypes: <String>['venue', 'food_drink'],
      venueTypes: <String>['rooftop'],
      productTypes: <String>['beverage'],
      expectedDeliverables: <String>['community_reach'],
      communityRequirementBand: 'medium',
    );

    expect(filters.toQueryParameters()['audience_size_band'], 'large');
    expect(filters.toQueryParameters()['community_requirement_band'], 'medium');
    expect(
      filters
          .toArrayParameters()
          .map((entry) => '${entry.key}:${entry.value}')
          .toList(),
      <String>[
        'need_types[]:food_drink',
        'need_types[]:sponsor',
        'community_types[]:wellness',
        'offers_in_return[]:social_media',
        'offers_in_return[]:event_activation',
        'venue_preferences[]:business_provides',
        'intent_types[]:venue_promotion',
        'offer_types[]:venue',
        'offer_types[]:food_drink',
        'venue_types[]:rooftop',
        'product_types[]:beverage',
        'expected_deliverables[]:community_reach',
      ],
    );
  });

  test('clearAll preserves feed and removes user filters', () {
    const filters = DiscoveryFilters(
      feed: DiscoveryFeed.all,
      searchQuery: 'wellness',
      city: 'Madrid',
      needTypes: <String>['sponsor'],
      audienceSizeBand: 'large',
    );

    final cleared = filters.clearAll();

    expect(cleared.feed, DiscoveryFeed.all);
    expect(cleared.searchQuery, isEmpty);
    expect(cleared.city, isNull);
    expect(cleared.needTypes, isEmpty);
    expect(cleared.audienceSizeBand, isNull);
    expect(cleared.hasActiveFilters, isFalse);
  });
}
