import 'package:flutter/material.dart';

import '../../opportunity/models/opportunity.dart';

@immutable
class DiscoveryItem {
  const DiscoveryItem({
    required this.id,
    required this.creatorType,
    required this.intentType,
    required this.title,
    required this.description,
    required this.preferredCity,
    required this.availability,
    required this.creatorProfile,
    this.canonicalOpportunityId,
    this.area,
    this.coverPhotoUrl,
    this.publishedAt,
    this.businessOffer,
    this.communityRequest,
    this.match,
  });

  factory DiscoveryItem.fromJson(Map<String, dynamic> json) => DiscoveryItem(
    id: json['id']?.toString() ?? '',
    canonicalOpportunityId: _resolveCanonicalOpportunityId(json),
    creatorType: json['creator_type']?.toString() ?? '',
    intentType: json['intent_type']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    preferredCity: json['preferred_city']?.toString() ?? '',
    area: json['area']?.toString(),
    coverPhotoUrl: json['cover_photo_url']?.toString(),
    publishedAt: _parseDateTime(json['published_at']),
    availability: DiscoveryAvailability.fromJson(
      (json['availability'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    ),
    creatorProfile: DiscoveryCreatorProfile.fromJson(
      (json['creator_profile'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    ),
    businessOffer: json['business_offer'] is Map<String, dynamic>
        ? BusinessOfferSummary.fromJson(
            json['business_offer'] as Map<String, dynamic>,
          )
        : null,
    communityRequest: json['community_request'] is Map<String, dynamic>
        ? CommunityRequestSummary.fromJson(
            json['community_request'] as Map<String, dynamic>,
          )
        : null,
    match: json['match'] is Map<String, dynamic>
        ? DiscoveryMatch.fromJson(json['match'] as Map<String, dynamic>)
        : null,
  );

  final String id;
  final String? canonicalOpportunityId;
  final String creatorType;
  final String intentType;
  final String title;
  final String description;
  final String preferredCity;
  final String? area;
  final String? coverPhotoUrl;
  final DateTime? publishedAt;
  final DiscoveryAvailability availability;
  final DiscoveryCreatorProfile creatorProfile;
  final BusinessOfferSummary? businessOffer;
  final CommunityRequestSummary? communityRequest;
  final DiscoveryMatch? match;

  bool get isBusinessOffer => businessOffer != null;
  bool get isCommunityRequest => communityRequest != null;

  List<String> get primaryBadges {
    if (isBusinessOffer) {
      final badges = <String>[...businessOffer!.offerTypeLabels.take(2)];
      if (businessOffer!.venueTypeLabel case final venueType?) {
        badges.add(venueType);
      }
      if (businessOffer!.productTypeLabel case final productType?) {
        badges.add(productType);
      }
      return badges.take(3).toList();
    }

    if (isCommunityRequest) {
      final badges = <String>[
        ...communityRequest!.needTypeLabels.take(2),
        ...communityRequest!.communityTypeLabels.take(1),
      ];
      return badges.take(3).toList();
    }

    return const <String>[];
  }

  List<String> get fitReasonLabels => match?.reasonLabels ?? const <String>[];
  String get resolvedOpportunityId {
    final canonicalId = canonicalOpportunityId;
    if (canonicalId != null && canonicalId.isNotEmpty) {
      return canonicalId;
    }
    return id;
  }

  Opportunity toOpportunity() {
    final venueMode = _mapVenueMode();

    return Opportunity(
      id: resolvedOpportunityId,
      title: title,
      description: description,
      businessOffer: _mapBusinessOffer(),
      communityDeliverables: _mapCommunityDeliverables(),
      categories: _mapCategories(),
      availabilityMode: availability.toOpportunityAvailabilityMode(),
      availabilityStart: availability.start,
      availabilityEnd: availability.end,
      selectedTime: availability.selectedTimeOfDay,
      recurringDays: availability.recurringDays,
      venueMode: venueMode,
      preferredCity: preferredCity,
      offerPhoto: coverPhotoUrl,
      status: OpportunityStatus.published,
      publishedAt: publishedAt,
      creatorProfile: CreatorProfile(
        id: creatorProfile.id,
        userType: creatorType,
        displayNameValue: creatorProfile.displayName,
        avatarUrl: creatorProfile.avatarUrl,
      ),
      isOwn: false,
      hasApplied: false,
    );
  }

  VenueMode _mapVenueMode() {
    if (communityRequest?.venuePreference case final preference?) {
      return switch (preference) {
        'business_provides' => VenueMode.businessVenue,
        'community_provides' => VenueMode.communityVenue,
        _ => VenueMode.noVenue,
      };
    }

    if ((businessOffer?.venueType?.isNotEmpty ?? false) ||
        (businessOffer?.offerTypes.contains('venue') ?? false)) {
      return VenueMode.businessVenue;
    }

    return VenueMode.noVenue;
  }

  BusinessOffer _mapBusinessOffer() {
    final offerTypes = businessOffer?.offerTypes ?? const <String>[];
    final discountEnabled = offerTypes.contains('discount');
    final products = <String>[
      if (businessOffer?.productTypeLabel case final productType?) productType,
    ];

    return BusinessOffer(
      venue: offerTypes.contains('venue'),
      foodDrink: offerTypes.contains('food_drink'),
      socialMediaExposure: offerTypes.contains('social_media'),
      contentCreation: offerTypes.contains('content_creation'),
      discount: DiscountOffer(enabled: discountEnabled),
      products: products,
      other: offerTypes.contains('other') ? 'Other' : null,
    );
  }

  CommunityDeliverables _mapCommunityDeliverables() {
    final deliverables =
        communityRequest?.offersInReturn ??
        businessOffer?.expectedDeliverables ??
        const <String>[];

    return CommunityDeliverables(
      socialMediaContent: deliverables.contains('social_media'),
      eventActivation: deliverables.contains('event_activation'),
      productPlacement: deliverables.contains('product_placement'),
      communityReach: deliverables.contains('community_reach'),
      reviewFeedback: deliverables.contains('review_feedback'),
    );
  }

  List<String> _mapCategories() {
    if (isCommunityRequest) {
      return communityRequest!.communityTypeLabels;
    }
    if (isBusinessOffer) {
      return businessOffer!.seekingCommunityLabels;
    }
    return const <String>[];
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? _resolveCanonicalOpportunityId(Map<String, dynamic> json) {
    const directKeys = <String>[
      'opportunity_id',
      'collab_opportunity_id',
      'legacy_opportunity_id',
      'application_target_id',
      'target_opportunity_id',
      'detail_id',
      'resource_id',
    ];

    for (final key in directKeys) {
      final value = json[key]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final nestedCandidates = <Object?>[
      json['opportunity'],
      json['collab_opportunity'],
      json['application_target'],
      (json['actions'] as Map<String, dynamic>?)?['apply'],
      (json['actions'] as Map<String, dynamic>?)?['open'],
      json['links'],
    ];

    for (final candidate in nestedCandidates) {
      if (candidate is! Map<String, dynamic>) continue;

      for (final key in directKeys) {
        final value = candidate[key]?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      final nestedId = candidate['id']?.toString();
      if (nestedId != null && nestedId.isNotEmpty) {
        return nestedId;
      }
    }

    return null;
  }
}

@immutable
class DiscoveryAvailability {
  const DiscoveryAvailability({
    required this.mode,
    required this.start,
    required this.end,
    this.selectedTime,
    this.recurringDays = const <int>[],
  });

  factory DiscoveryAvailability.fromJson(Map<String, dynamic> json) =>
      DiscoveryAvailability(
        mode: json['mode']?.toString() ?? 'flexible',
        start: _parseDate(json['start']),
        end: _parseDate(json['end']),
        selectedTime: json['selected_time']?.toString(),
        recurringDays:
            (json['recurring_days'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => int.tryParse(value.toString()) ?? 0)
                .where((int value) => value > 0)
                .toList(),
      );

  final String mode;
  final DateTime start;
  final DateTime end;
  final String? selectedTime;
  final List<int> recurringDays;

  AvailabilityMode toOpportunityAvailabilityMode() =>
      AvailabilityMode.fromString(mode);

  TimeOfDay? get selectedTimeOfDay {
    if (selectedTime == null || selectedTime!.isEmpty) return null;
    final parts = selectedTime!.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static DateTime _parseDate(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

@immutable
class DiscoveryCreatorProfile {
  const DiscoveryCreatorProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory DiscoveryCreatorProfile.fromJson(Map<String, dynamic> json) =>
      DiscoveryCreatorProfile(
        id: json['id']?.toString() ?? '',
        displayName: json['display_name']?.toString() ?? 'Unknown',
        avatarUrl: json['avatar_url']?.toString(),
      );

  final String id;
  final String displayName;
  final String? avatarUrl;
}

@immutable
class BusinessOfferSummary {
  const BusinessOfferSummary({
    this.offerTypes = const <String>[],
    this.venueType,
    this.productType,
    this.seekingCommunities = const <DiscoveryLabelValue>[],
    this.minCommunitySize,
    this.expectedDeliverables = const <String>[],
  });

  factory BusinessOfferSummary.fromJson(Map<String, dynamic> json) =>
      BusinessOfferSummary(
        offerTypes: (json['offer_types'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value.toString())
            .toList(),
        venueType: json['venue_type']?.toString(),
        productType: json['product_type']?.toString(),
        seekingCommunities:
            (json['seeking_communities'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(DiscoveryLabelValue.fromJson)
                .toList(),
        minCommunitySize: _parseInt(json['min_community_size']),
        expectedDeliverables:
            (json['expected_deliverables'] as List<dynamic>? ??
                    const <dynamic>[])
                .map((value) => value.toString())
                .toList(),
      );

  final List<String> offerTypes;
  final String? venueType;
  final String? productType;
  final List<DiscoveryLabelValue> seekingCommunities;
  final int? minCommunitySize;
  final List<String> expectedDeliverables;

  List<String> get offerTypeLabels =>
      offerTypes.map(_discoveryLabelFromKey).toList();
  List<String> get seekingCommunityLabels =>
      seekingCommunities.map((item) => item.label).toList();
  String? get venueTypeLabel =>
      venueType != null ? _discoveryLabelFromKey(venueType!) : null;
  String? get productTypeLabel =>
      productType != null ? _discoveryLabelFromKey(productType!) : null;
}

@immutable
class CommunityRequestSummary {
  const CommunityRequestSummary({
    this.needTypes = const <String>[],
    this.communityTypes = const <DiscoveryLabelValue>[],
    this.communitySize,
    this.typicalAttendance,
    this.offersInReturn = const <String>[],
    this.venuePreference,
  });

  factory CommunityRequestSummary.fromJson(Map<String, dynamic> json) =>
      CommunityRequestSummary(
        needTypes: (json['need_types'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value.toString())
            .toList(),
        communityTypes:
            (json['community_types'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(DiscoveryLabelValue.fromJson)
                .toList(),
        communitySize: _parseInt(json['community_size']),
        typicalAttendance: _parseInt(json['typical_attendance']),
        offersInReturn:
            (json['offers_in_return'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value.toString())
                .toList(),
        venuePreference: json['venue_preference']?.toString(),
      );

  final List<String> needTypes;
  final List<DiscoveryLabelValue> communityTypes;
  final int? communitySize;
  final int? typicalAttendance;
  final List<String> offersInReturn;
  final String? venuePreference;

  List<String> get needTypeLabels =>
      needTypes.map(_discoveryLabelFromKey).toList();
  List<String> get communityTypeLabels =>
      communityTypes.map((item) => item.label).toList();
}

@immutable
class DiscoveryMatch {
  const DiscoveryMatch({
    required this.feed,
    required this.score,
    this.tier,
    this.reasons = const <String>[],
  });

  factory DiscoveryMatch.fromJson(Map<String, dynamic> json) => DiscoveryMatch(
    feed: json['feed']?.toString() ?? 'recommended',
    score: _parseInt(json['score']) ?? 0,
    tier: json['tier']?.toString(),
    reasons: (json['reasons'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => value.toString())
        .toList(),
  );

  final String feed;
  final int score;
  final String? tier;
  final List<String> reasons;

  List<String> get reasonLabels => reasons.map(_matchReasonLabel).toList();
}

@immutable
class DiscoveryLabelValue {
  const DiscoveryLabelValue({required this.key, required this.label});

  factory DiscoveryLabelValue.fromJson(Map<String, dynamic> json) =>
      DiscoveryLabelValue(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );

  final String key;
  final String label;
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String _matchReasonLabel(String reason) => switch (reason) {
  'city_match' => 'City match',
  'need_offer_overlap' => 'Offer overlap',
  'community_type_match' => 'Community fit',
  'audience_size_match' => 'Audience fit',
  'venue_preference_match' => 'Venue fit',
  'expected_deliverable_match' => 'Deliverable fit',
  'fresh_listing' => 'Fresh listing',
  _ => _discoveryLabelFromKey(reason),
};

String _discoveryLabelFromKey(String key) => key
    .split('_')
    .where((String part) => part.isNotEmpty)
    .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
