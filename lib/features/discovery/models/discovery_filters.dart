import 'package:flutter/foundation.dart';

enum DiscoveryFeed {
  recommended,
  all;

  String toApiValue() => name;
}

@immutable
class DiscoveryFilters {
  const DiscoveryFilters({
    this.feed = DiscoveryFeed.recommended,
    this.searchQuery = '',
    this.city,
    this.availabilityMode,
    this.availabilityFrom,
    this.availabilityTo,
    this.sort,
    this.intentTypes = const <String>[],
    this.offerTypes = const <String>[],
    this.needTypes = const <String>[],
    this.communityTypes = const <String>[],
    this.audienceSizeBand,
    this.communityRequirementBand,
    this.venueTypes = const <String>[],
    this.productTypes = const <String>[],
    this.expectedDeliverables = const <String>[],
    this.offersInReturn = const <String>[],
    this.venuePreferences = const <String>[],
  });

  final DiscoveryFeed feed;
  final String searchQuery;
  final String? city;
  final String? availabilityMode;
  final DateTime? availabilityFrom;
  final DateTime? availabilityTo;
  final String? sort;
  final List<String> intentTypes;
  final List<String> offerTypes;
  final List<String> needTypes;
  final List<String> communityTypes;
  final String? audienceSizeBand;
  final String? communityRequirementBand;
  final List<String> venueTypes;
  final List<String> productTypes;
  final List<String> expectedDeliverables;
  final List<String> offersInReturn;
  final List<String> venuePreferences;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      city != null ||
      availabilityMode != null ||
      availabilityFrom != null ||
      availabilityTo != null ||
      sort != null ||
      intentTypes.isNotEmpty ||
      offerTypes.isNotEmpty ||
      needTypes.isNotEmpty ||
      communityTypes.isNotEmpty ||
      audienceSizeBand != null ||
      communityRequirementBand != null ||
      venueTypes.isNotEmpty ||
      productTypes.isNotEmpty ||
      expectedDeliverables.isNotEmpty ||
      offersInReturn.isNotEmpty ||
      venuePreferences.isNotEmpty;

  DiscoveryFilters copyWith({
    DiscoveryFeed? feed,
    String? searchQuery,
    String? city,
    String? availabilityMode,
    DateTime? availabilityFrom,
    DateTime? availabilityTo,
    String? sort,
    List<String>? intentTypes,
    List<String>? offerTypes,
    List<String>? needTypes,
    List<String>? communityTypes,
    String? audienceSizeBand,
    String? communityRequirementBand,
    List<String>? venueTypes,
    List<String>? productTypes,
    List<String>? expectedDeliverables,
    List<String>? offersInReturn,
    List<String>? venuePreferences,
    bool clearCity = false,
    bool clearAvailabilityMode = false,
    bool clearAvailabilityRange = false,
    bool clearSort = false,
    bool clearAudienceSizeBand = false,
    bool clearCommunityRequirementBand = false,
  }) => DiscoveryFilters(
    feed: feed ?? this.feed,
    searchQuery: searchQuery ?? this.searchQuery,
    city: clearCity ? null : (city ?? this.city),
    availabilityMode: clearAvailabilityMode
        ? null
        : (availabilityMode ?? this.availabilityMode),
    availabilityFrom: clearAvailabilityRange
        ? null
        : (availabilityFrom ?? this.availabilityFrom),
    availabilityTo: clearAvailabilityRange
        ? null
        : (availabilityTo ?? this.availabilityTo),
    sort: clearSort ? null : (sort ?? this.sort),
    intentTypes: intentTypes ?? this.intentTypes,
    offerTypes: offerTypes ?? this.offerTypes,
    needTypes: needTypes ?? this.needTypes,
    communityTypes: communityTypes ?? this.communityTypes,
    audienceSizeBand: clearAudienceSizeBand
        ? null
        : (audienceSizeBand ?? this.audienceSizeBand),
    communityRequirementBand: clearCommunityRequirementBand
        ? null
        : (communityRequirementBand ?? this.communityRequirementBand),
    venueTypes: venueTypes ?? this.venueTypes,
    productTypes: productTypes ?? this.productTypes,
    expectedDeliverables: expectedDeliverables ?? this.expectedDeliverables,
    offersInReturn: offersInReturn ?? this.offersInReturn,
    venuePreferences: venuePreferences ?? this.venuePreferences,
  );

  DiscoveryFilters clearAll() => DiscoveryFilters(feed: feed);

  Map<String, String> toQueryParameters() {
    final params = <String, String>{'feed': feed.toApiValue()};

    if (searchQuery.isNotEmpty) params['search'] = searchQuery;
    if (city != null && city!.isNotEmpty) params['city'] = city!;
    if (availabilityMode != null) {
      params['availability_mode'] = availabilityMode!;
    }
    if (availabilityFrom != null) {
      params['availability_from'] = _dateOnly(availabilityFrom!);
    }
    if (availabilityTo != null) {
      params['availability_to'] = _dateOnly(availabilityTo!);
    }
    if (sort != null && sort!.isNotEmpty) params['sort'] = sort!;
    if (audienceSizeBand != null) {
      params['audience_size_band'] = audienceSizeBand!;
    }
    if (communityRequirementBand != null) {
      params['community_requirement_band'] = communityRequirementBand!;
    }

    return params;
  }

  List<MapEntry<String, String>> toArrayParameters() =>
      <MapEntry<String, String>>[
        ...needTypes.map(
          (String value) => MapEntry<String, String>('need_types[]', value),
        ),
        ...communityTypes.map(
          (String value) =>
              MapEntry<String, String>('community_types[]', value),
        ),
        ...offersInReturn.map(
          (String value) =>
              MapEntry<String, String>('offers_in_return[]', value),
        ),
        ...venuePreferences.map(
          (String value) =>
              MapEntry<String, String>('venue_preferences[]', value),
        ),
        ...intentTypes.map(
          (String value) => MapEntry<String, String>('intent_types[]', value),
        ),
        ...offerTypes.map(
          (String value) => MapEntry<String, String>('offer_types[]', value),
        ),
        ...venueTypes.map(
          (String value) => MapEntry<String, String>('venue_types[]', value),
        ),
        ...productTypes.map(
          (String value) => MapEntry<String, String>('product_types[]', value),
        ),
        ...expectedDeliverables.map(
          (String value) =>
              MapEntry<String, String>('expected_deliverables[]', value),
        ),
      ];

  static String _dateOnly(DateTime value) =>
      value.toIso8601String().split('T').first;
}
