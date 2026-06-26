import 'package:flutter/material.dart';

import '../../../utils/remote_media_url.dart';
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
    this.offerHeadline,
    this.pastEventsCount,
    this.activeThisMonth,
    this.activeThisMonthLabel,
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
    coverPhotoUrl: normalizeRemoteMediaUrlOrNull(
      json['cover_photo_url']?.toString(),
    ),
    publishedAt: _parseDateTime(json['published_at']),
    offerHeadline: _firstNonEmptyString(<Object?>[
      json['offer_headline'],
      (json['business_offer'] as Map<String, dynamic>?)?['offer_headline'],
      (json['community_request'] as Map<String, dynamic>?)?['request_headline'],
    ]),
    pastEventsCount: _parseInt(
      json['past_events_count'] ??
          json['profile_past_events_count'] ??
          json['completed_events_count'],
    ),
    activeThisMonth: _parseBool(
      json['active_this_month'] ?? json['creator_active_this_month'],
    ),
    activeThisMonthLabel: _firstNonEmptyString(<Object?>[
      json['active_this_month_label'],
      json['activity_badge_label'],
    ]),
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
        ? DiscoveryMatch.fromJson({
            ...(json['match'] as Map<String, dynamic>),
            // H1: backend may emit match_breakdown at the item level
            // alongside `match`. Surface it inside the match object.
            if (json['match_breakdown'] is List)
              'match_breakdown': json['match_breakdown'],
            if (json['match_score'] != null &&
                json['match'] is Map<String, dynamic> &&
                (json['match'] as Map<String, dynamic>)['score'] == null)
              'score': json['match_score'],
          })
        : json['match_score'] != null || json['match_breakdown'] is List
        ? DiscoveryMatch.fromJson({
            'score': json['match_score'],
            if (json['match_breakdown'] is List)
              'match_breakdown': json['match_breakdown'],
          })
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
  final String? offerHeadline;
  final int? pastEventsCount;
  final bool? activeThisMonth;
  final String? activeThisMonthLabel;

  bool get isBusinessOffer => businessOffer != null;
  bool get isCommunityRequest => communityRequest != null;
  String get locationLabel {
    final trimmedArea = area?.trim();
    final trimmedCity = preferredCity.trim();
    if (trimmedArea != null && trimmedArea.isNotEmpty) {
      if (trimmedCity.isNotEmpty) {
        return '$trimmedArea, $trimmedCity';
      }
      return trimmedArea;
    }
    return trimmedCity;
  }

  String? get displayHeadline {
    final trimmedHeadline = offerHeadline?.trim();
    if (trimmedHeadline != null && trimmedHeadline.isNotEmpty) {
      return trimmedHeadline;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty &&
        trimmedTitle != creatorProfile.displayName.trim()) {
      return trimmedTitle;
    }

    return null;
  }

  /// Concrete one-line summary of what a COMMUNITY offers in return, used on
  /// the business-side Explore card so it reads as cleanly as the community
  /// side (e.g. "Social Media · 30+ people"). Returns null when no concrete
  /// detail is available, so the caller can fall back gracefully.
  String? get communityOfferLine {
    final request = communityRequest;
    if (request == null) {
      return null;
    }

    final parts = <String>[];
    final offers = request.offerInReturnLabels;
    if (offers.isNotEmpty) {
      parts.add(offers.take(2).join(' · '));
    }

    // Append a concrete people-scale (attendance preferred, else community
    // size) so the line mirrors the "Social Media · 30+ people" pattern.
    final scale = request.typicalAttendance ?? request.communitySize;
    if (scale != null && scale > 0) {
      parts.add('$scale+ people');
    }

    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }

  String? get activityBadgeLabel {
    if (activeThisMonth ?? false) {
      final customLabel = activeThisMonthLabel?.trim();
      if (customLabel != null && customLabel.isNotEmpty) {
        return customLabel;
      }
      return 'Active this month';
    }

    final count = pastEventsCount;
    if (count != null && count > 0) {
      return '$count past event${count == 1 ? '' : 's'}';
    }

    return null;
  }

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
      'kolab_id',
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
      json['kolab'],
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
        mode: json['mode']?.toString() ?? 'one_time',
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
        avatarUrl: normalizeRemoteMediaUrlOrNull(
          json['avatar_url']?.toString(),
        ),
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
    this.venueTypeLabelRaw,
    this.productTypeLabelRaw,
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
        // Prefer the backend's pre-formatted `*_type_label` slug variants when
        // present so the card never has to title-case a raw slug.
        venueTypeLabelRaw: json['venue_type_label']?.toString(),
        productTypeLabelRaw: json['product_type_label']?.toString(),
        seekingCommunities: _parseLabelValues(json['seeking_communities']),
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
  final String? venueTypeLabelRaw;
  final String? productTypeLabelRaw;
  final List<DiscoveryLabelValue> seekingCommunities;
  final int? minCommunitySize;
  final List<String> expectedDeliverables;

  List<String> get offerTypeLabels =>
      offerTypes.map(_discoveryLabelFromKey).toList();
  List<String> get seekingCommunityLabels =>
      seekingCommunities.map((item) => item.label).toList();
  // Prefer the backend-formatted label; fall back to title-casing the slug so
  // a raw value like "coffee_shop" never reaches the UI.
  String? get venueTypeLabel => _preferFormatted(venueTypeLabelRaw, venueType);
  String? get productTypeLabel =>
      _preferFormatted(productTypeLabelRaw, productType);
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
        communityTypes: _parseLabelValues(json['community_types']),
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
  List<String> get offerInReturnLabels =>
      offersInReturn.map(_discoveryLabelFromKey).toList();
}

@immutable
class DiscoveryMatch {
  const DiscoveryMatch({
    required this.feed,
    required this.score,
    this.tier,
    this.reasons = const <String>[],
    this.breakdown = const <DiscoveryMatchSignal>[],
  });

  factory DiscoveryMatch.fromJson(Map<String, dynamic> json) => DiscoveryMatch(
    feed: json['feed']?.toString() ?? 'recommended',
    score: _parseInt(json['score']) ?? 0,
    tier: json['tier']?.toString(),
    reasons: (json['reasons'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => value.toString())
        .toList(),
    // H1: ordered signal weights backing the score. Backend returns these as
    // `breakdown` (nested) or `match_breakdown` (sibling) — support both.
    breakdown: _parseBreakdown(json['breakdown'] ?? json['match_breakdown']),
  );

  final String feed;
  final int score;
  final String? tier;
  final List<String> reasons;
  final List<DiscoveryMatchSignal> breakdown;

  List<String> get reasonLabels => reasons.map(_matchReasonLabel).toList();
}

/// One signal in the discovery match-score breakdown (H1).
@immutable
class DiscoveryMatchSignal {
  const DiscoveryMatchSignal({
    required this.key,
    required this.label,
    required this.weight,
    required this.score,
  });

  factory DiscoveryMatchSignal.fromJson(Map<String, dynamic> json) =>
      DiscoveryMatchSignal(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );

  final String key;
  final String label;
  final double weight;
  final double score;
}

List<DiscoveryMatchSignal> _parseBreakdown(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(DiscoveryMatchSignal.fromJson)
      .toList(growable: false);
}

@immutable
class DiscoveryLabelValue {
  const DiscoveryLabelValue({required this.key, required this.label});

  factory DiscoveryLabelValue.fromJson(Map<String, dynamic> json) {
    final key = json['key']?.toString() ?? '';
    // Prefer the backend's pre-formatted label (`label`, also accepts
    // `type_label`). If absent, format the raw slug client-side so we never
    // surface a raw value like "Run_Club" — it becomes "Run Club".
    final rawLabel = (json['label'] ?? json['type_label'])?.toString().trim();
    final label = (rawLabel != null && rawLabel.isNotEmpty)
        ? rawLabel
        : _discoveryLabelFromKey(key);
    return DiscoveryLabelValue(key: key, label: label);
  }

  /// Builds a label/value from a heterogeneous list entry that may be a
  /// `{key,label}` map OR a bare slug string. A bare string is title-cased so
  /// the UI always shows a formatted label (e.g. "run_club" -> "Run Club"),
  /// never the raw slug.
  factory DiscoveryLabelValue.fromDynamic(Object? value) {
    if (value is Map<String, dynamic>) {
      return DiscoveryLabelValue.fromJson(value);
    }
    final slug = value?.toString() ?? '';
    return DiscoveryLabelValue(key: slug, label: _discoveryLabelFromKey(slug));
  }

  final String key;
  final String label;
}

/// Parses a discovery type-tag list that may contain `{key,label}` maps and/or
/// bare slug strings, always yielding formatted labels (never raw slugs).
List<DiscoveryLabelValue> _parseLabelValues(Object? raw) {
  if (raw is! List) return const <DiscoveryLabelValue>[];
  return raw
      .map(DiscoveryLabelValue.fromDynamic)
      .where((DiscoveryLabelValue item) => item.label.isNotEmpty)
      .toList(growable: false);
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _parseBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

String? _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
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

/// Returns the backend-formatted [formatted] label when present and non-empty,
/// otherwise title-cases the raw [slug]. Returns null when neither is usable.
/// Guards against raw slugs ("Run_Club") ever reaching the UI.
String? _preferFormatted(String? formatted, String? slug) {
  final trimmed = formatted?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  if (slug != null && slug.trim().isNotEmpty) {
    return _discoveryLabelFromKey(slug.trim());
  }
  return null;
}
