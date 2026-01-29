import 'package:flutter/foundation.dart';

// =============================================================================
// Enums
// =============================================================================

/// Availability mode for an opportunity
enum AvailabilityMode {
  oneTime,
  recurring,
  flexible;

  String get displayName {
    switch (this) {
      case AvailabilityMode.oneTime:
        return 'One Time';
      case AvailabilityMode.recurring:
        return 'Recurring';
      case AvailabilityMode.flexible:
        return 'Flexible';
    }
  }

  String get description {
    switch (this) {
      case AvailabilityMode.oneTime:
        return 'A single event or collaboration';
      case AvailabilityMode.recurring:
        return 'Repeated collaborations over time';
      case AvailabilityMode.flexible:
        return 'Open to discussion on timing';
    }
  }

  String toApiValue() {
    switch (this) {
      case AvailabilityMode.oneTime:
        return 'one_time';
      case AvailabilityMode.recurring:
        return 'recurring';
      case AvailabilityMode.flexible:
        return 'flexible';
    }
  }

  static AvailabilityMode fromString(String value) {
    switch (value) {
      case 'one_time':
        return AvailabilityMode.oneTime;
      case 'recurring':
        return AvailabilityMode.recurring;
      case 'flexible':
        return AvailabilityMode.flexible;
      default:
        return AvailabilityMode.flexible;
    }
  }
}

/// Venue mode for an opportunity
enum VenueMode {
  businessVenue,
  communityVenue,
  noVenue;

  String get displayName {
    switch (this) {
      case VenueMode.businessVenue:
        return 'Business Venue';
      case VenueMode.communityVenue:
        return 'Community Venue';
      case VenueMode.noVenue:
        return 'No Venue';
    }
  }

  String get description {
    switch (this) {
      case VenueMode.businessVenue:
        return 'At the business location';
      case VenueMode.communityVenue:
        return 'At the community location';
      case VenueMode.noVenue:
        return 'Online or no specific venue';
    }
  }

  bool get requiresAddress => this != VenueMode.noVenue;

  String toApiValue() {
    switch (this) {
      case VenueMode.businessVenue:
        return 'business_venue';
      case VenueMode.communityVenue:
        return 'community_venue';
      case VenueMode.noVenue:
        return 'no_venue';
    }
  }

  static VenueMode fromString(String value) {
    switch (value) {
      case 'business_venue':
        return VenueMode.businessVenue;
      case 'community_venue':
        return VenueMode.communityVenue;
      case 'no_venue':
        return VenueMode.noVenue;
      default:
        return VenueMode.noVenue;
    }
  }
}

/// Status of an opportunity
enum OpportunityStatus {
  draft,
  published,
  closed,
  completed;

  String get displayName {
    switch (this) {
      case OpportunityStatus.draft:
        return 'Draft';
      case OpportunityStatus.published:
        return 'Published';
      case OpportunityStatus.closed:
        return 'Closed';
      case OpportunityStatus.completed:
        return 'Completed';
    }
  }

  bool get canEdit => this == draft || this == published;
  bool get canPublish => this == draft;
  bool get canClose => this == published;
  bool get canDelete => this == draft;

  String toApiValue() => name;

  static OpportunityStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return OpportunityStatus.draft;
      case 'published':
        return OpportunityStatus.published;
      case 'closed':
        return OpportunityStatus.closed;
      case 'completed':
        return OpportunityStatus.completed;
      default:
        return OpportunityStatus.draft;
    }
  }
}

// =============================================================================
// Value Objects
// =============================================================================

/// Discount offer within business_offer
@immutable
class DiscountOffer {
  const DiscountOffer({
    this.enabled = false,
    this.percentage,
  });

  factory DiscountOffer.fromJson(Map<String, dynamic> json) => DiscountOffer(
        enabled: json['enabled'] as bool? ?? false,
        percentage: json['percentage'] as int?,
      );

  final bool enabled;
  final int? percentage;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (enabled && percentage != null) 'percentage': percentage,
      };

  DiscountOffer copyWith({
    bool? enabled,
    int? percentage,
    bool clearPercentage = false,
  }) =>
      DiscountOffer(
        enabled: enabled ?? this.enabled,
        percentage: clearPercentage ? null : (percentage ?? this.percentage),
      );
}

/// What the business offers (JSONB)
@immutable
class BusinessOffer {
  const BusinessOffer({
    this.venue = false,
    this.foodDrink = false,
    this.discount = const DiscountOffer(),
    this.products = const [],
    this.other,
  });

  factory BusinessOffer.fromJson(Map<String, dynamic> json) => BusinessOffer(
        venue: json['venue'] as bool? ?? false,
        foodDrink: json['food_drink'] as bool? ?? false,
        discount: json['discount'] is Map<String, dynamic>
            ? DiscountOffer.fromJson(json['discount'] as Map<String, dynamic>)
            : const DiscountOffer(),
        products: (json['products'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        other: json['other'] as String?,
      );

  final bool venue;
  final bool foodDrink;
  final DiscountOffer discount;
  final List<String> products;
  final String? other;

  /// Whether any offer is configured
  bool get hasAnyOffer =>
      venue ||
      foodDrink ||
      discount.enabled ||
      products.isNotEmpty ||
      (other?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
        'venue': venue,
        'food_drink': foodDrink,
        'discount': discount.toJson(),
        if (products.isNotEmpty) 'products': products,
        if (other != null && other!.isNotEmpty) 'other': other,
      };

  BusinessOffer copyWith({
    bool? venue,
    bool? foodDrink,
    DiscountOffer? discount,
    List<String>? products,
    String? other,
    bool clearOther = false,
  }) =>
      BusinessOffer(
        venue: venue ?? this.venue,
        foodDrink: foodDrink ?? this.foodDrink,
        discount: discount ?? this.discount,
        products: products ?? this.products,
        other: clearOther ? null : (other ?? this.other),
      );
}

/// What the community will deliver (JSONB)
@immutable
class CommunityDeliverables {
  const CommunityDeliverables({
    this.instagramPost = false,
    this.instagramStory = false,
    this.tiktokVideo = false,
    this.eventMention = false,
    this.attendeeCount,
    this.other,
  });

  factory CommunityDeliverables.fromJson(Map<String, dynamic> json) =>
      CommunityDeliverables(
        instagramPost: json['instagram_post'] as bool? ?? false,
        instagramStory: json['instagram_story'] as bool? ?? false,
        tiktokVideo: json['tiktok_video'] as bool? ?? false,
        eventMention: json['event_mention'] as bool? ?? false,
        attendeeCount: json['attendee_count'] as int?,
        other: json['other'] as String?,
      );

  final bool instagramPost;
  final bool instagramStory;
  final bool tiktokVideo;
  final bool eventMention;
  final int? attendeeCount;
  final String? other;

  /// Whether any deliverable is configured
  bool get hasAnyDeliverable =>
      instagramPost ||
      instagramStory ||
      tiktokVideo ||
      eventMention ||
      attendeeCount != null ||
      (other?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
        'instagram_post': instagramPost,
        'instagram_story': instagramStory,
        'tiktok_video': tiktokVideo,
        'event_mention': eventMention,
        if (attendeeCount != null) 'attendee_count': attendeeCount,
        if (other != null && other!.isNotEmpty) 'other': other,
      };

  CommunityDeliverables copyWith({
    bool? instagramPost,
    bool? instagramStory,
    bool? tiktokVideo,
    bool? eventMention,
    int? attendeeCount,
    String? other,
    bool clearAttendeeCount = false,
    bool clearOther = false,
  }) =>
      CommunityDeliverables(
        instagramPost: instagramPost ?? this.instagramPost,
        instagramStory: instagramStory ?? this.instagramStory,
        tiktokVideo: tiktokVideo ?? this.tiktokVideo,
        eventMention: eventMention ?? this.eventMention,
        attendeeCount:
            clearAttendeeCount ? null : (attendeeCount ?? this.attendeeCount),
        other: clearOther ? null : (other ?? this.other),
      );
}

/// Creator profile from API response
@immutable
class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.userType,
    this.businessName,
    this.avatarUrl,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) => CreatorProfile(
        id: json['id']?.toString() ?? '',
        userType: json['user_type'] as String? ?? '',
        businessName: json['business_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  final String id;
  final String userType;
  final String? businessName;
  final String? avatarUrl;

  /// Display name - business name or fallback
  String get displayName => businessName ?? 'Unknown';

  /// Initial letter for avatar fallback
  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  bool get isBusiness => userType == 'business';
  bool get isCommunity => userType == 'community';
}

/// Application info (when user has applied)
@immutable
class MyApplication {
  const MyApplication({
    required this.id,
    required this.status,
    this.message,
    this.createdAt,
  });

  factory MyApplication.fromJson(Map<String, dynamic> json) => MyApplication(
        id: json['id']?.toString() ?? '',
        status: json['status'] as String? ?? 'pending',
        message: json['message'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String status;
  final String? message;
  final DateTime? createdAt;
}

// =============================================================================
// Main Opportunity Model
// =============================================================================

/// Unified opportunity model matching the real API
@immutable
class Opportunity {
  const Opportunity({
    this.id,
    required this.title,
    required this.description,
    required this.businessOffer,
    required this.communityDeliverables,
    required this.categories,
    required this.availabilityMode,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.venueMode,
    this.address,
    required this.preferredCity,
    this.offerPhoto,
    this.status = OpportunityStatus.draft,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.creatorProfile,
    this.applicationsCount,
    this.isOwn,
    this.hasApplied,
    this.myApplication,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : rawId as String?;

    return Opportunity(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      businessOffer: json['business_offer'] is Map<String, dynamic>
          ? BusinessOffer.fromJson(
              json['business_offer'] as Map<String, dynamic>)
          : const BusinessOffer(),
      communityDeliverables:
          json['community_deliverables'] is Map<String, dynamic>
              ? CommunityDeliverables.fromJson(
                  json['community_deliverables'] as Map<String, dynamic>)
              : const CommunityDeliverables(),
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availabilityMode: AvailabilityMode.fromString(
          json['availability_mode'] as String? ?? 'flexible'),
      availabilityStart: _parseDate(json['availability_start']),
      availabilityEnd: _parseDate(json['availability_end']),
      venueMode:
          VenueMode.fromString(json['venue_mode'] as String? ?? 'no_venue'),
      address: json['address'] as String?,
      preferredCity: json['preferred_city'] as String? ?? '',
      offerPhoto: json['offer_photo'] as String?,
      status: OpportunityStatus.fromString(
          json['status'] as String? ?? 'draft'),
      createdAt: _parseDateTimeNullable(json['created_at']),
      updatedAt: _parseDateTimeNullable(json['updated_at']),
      publishedAt: _parseDateTimeNullable(json['published_at']),
      creatorProfile: json['creator_profile'] is Map<String, dynamic>
          ? CreatorProfile.fromJson(
              json['creator_profile'] as Map<String, dynamic>)
          : null,
      applicationsCount: json['applications_count'] as int?,
      isOwn: json['is_own'] as bool?,
      hasApplied: json['has_applied'] as bool?,
      myApplication: json['my_application'] is Map<String, dynamic>
          ? MyApplication.fromJson(
              json['my_application'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Creates a default empty opportunity for form initialization
  factory Opportunity.empty() => Opportunity(
        title: '',
        description: '',
        businessOffer: const BusinessOffer(),
        communityDeliverables: const CommunityDeliverables(),
        categories: const [],
        availabilityMode: AvailabilityMode.flexible,
        availabilityStart: DateTime.now().add(const Duration(days: 7)),
        availabilityEnd: DateTime.now().add(const Duration(days: 37)),
        venueMode: VenueMode.noVenue,
        preferredCity: '',
      );

  // Fields matching API
  final String? id;
  final String title;
  final String description;
  final BusinessOffer businessOffer;
  final CommunityDeliverables communityDeliverables;
  final List<String> categories;
  final AvailabilityMode availabilityMode;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final VenueMode venueMode;
  final String? address;
  final String preferredCity;
  final String? offerPhoto;
  final OpportunityStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  // Response-only fields
  final CreatorProfile? creatorProfile;
  final int? applicationsCount;
  final bool? isOwn;
  final bool? hasApplied;
  final MyApplication? myApplication;

  /// JSON body for POST/PUT requests (excludes response-only fields)
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'business_offer': businessOffer.toJson(),
        'community_deliverables': communityDeliverables.toJson(),
        'categories': categories,
        'availability_mode': availabilityMode.toApiValue(),
        'availability_start':
            availabilityStart.toIso8601String().split('T').first,
        'availability_end': availabilityEnd.toIso8601String().split('T').first,
        'venue_mode': venueMode.toApiValue(),
        if (address != null && address!.isNotEmpty) 'address': address,
        'preferred_city': preferredCity,
        if (offerPhoto != null && offerPhoto!.isNotEmpty)
          'offer_photo': offerPhoto,
        'status': status.toApiValue(),
      };

  Opportunity copyWith({
    String? id,
    String? title,
    String? description,
    BusinessOffer? businessOffer,
    CommunityDeliverables? communityDeliverables,
    List<String>? categories,
    AvailabilityMode? availabilityMode,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
    VenueMode? venueMode,
    String? address,
    String? preferredCity,
    String? offerPhoto,
    OpportunityStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    CreatorProfile? creatorProfile,
    int? applicationsCount,
    bool? isOwn,
    bool? hasApplied,
    MyApplication? myApplication,
    bool clearAddress = false,
    bool clearOfferPhoto = false,
  }) =>
      Opportunity(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        businessOffer: businessOffer ?? this.businessOffer,
        communityDeliverables:
            communityDeliverables ?? this.communityDeliverables,
        categories: categories ?? this.categories,
        availabilityMode: availabilityMode ?? this.availabilityMode,
        availabilityStart: availabilityStart ?? this.availabilityStart,
        availabilityEnd: availabilityEnd ?? this.availabilityEnd,
        venueMode: venueMode ?? this.venueMode,
        address: clearAddress ? null : (address ?? this.address),
        preferredCity: preferredCity ?? this.preferredCity,
        offerPhoto: clearOfferPhoto ? null : (offerPhoto ?? this.offerPhoto),
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        publishedAt: publishedAt ?? this.publishedAt,
        creatorProfile: creatorProfile ?? this.creatorProfile,
        applicationsCount: applicationsCount ?? this.applicationsCount,
        isOwn: isOwn ?? this.isOwn,
        hasApplied: hasApplied ?? this.hasApplied,
        myApplication: myApplication ?? this.myApplication,
      );

  /// Summary of what the business offers (for card display)
  String get offerSummary {
    final parts = <String>[];
    if (businessOffer.venue) parts.add('Venue');
    if (businessOffer.foodDrink) parts.add('Food & Drink');
    if (businessOffer.discount.enabled) {
      final pct = businessOffer.discount.percentage;
      parts.add(pct != null ? '$pct% Discount' : 'Discount');
    }
    if (businessOffer.products.isNotEmpty) {
      parts.add('${businessOffer.products.length} Products');
    }
    if (businessOffer.other?.isNotEmpty ?? false) parts.add('More');
    return parts.isEmpty ? 'No offers specified' : parts.join(' · ');
  }

  /// Summary of community deliverables (for card display)
  String get deliverablesSummary {
    final parts = <String>[];
    if (communityDeliverables.instagramPost) parts.add('IG Post');
    if (communityDeliverables.instagramStory) parts.add('IG Story');
    if (communityDeliverables.tiktokVideo) parts.add('TikTok');
    if (communityDeliverables.eventMention) parts.add('Event Mention');
    if (communityDeliverables.attendeeCount != null) {
      parts.add('${communityDeliverables.attendeeCount} Attendees');
    }
    return parts.isEmpty ? 'No deliverables specified' : parts.join(' · ');
  }

  /// Date range display string
  String get dateRangeDisplay {
    final start =
        '${availabilityStart.day}/${availabilityStart.month}/${availabilityStart.year}';
    final end =
        '${availabilityEnd.day}/${availabilityEnd.month}/${availabilityEnd.year}';
    return '$start - $end';
  }

  @override
  String toString() =>
      'Opportunity(id: $id, title: $title, status: $status)';

  // ---------------------------------------------------------------------------
  // Date parsing helpers
  // ---------------------------------------------------------------------------

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

// =============================================================================
// Paginated Response
// =============================================================================

/// Paginated API response wrapper
@immutable
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

// =============================================================================
// Available Categories
// =============================================================================

/// Predefined opportunity categories
abstract final class OpportunityCategories {
  static const List<String> all = [
    'Food & Drink',
    'Sports',
    'Wellness',
    'Culture',
    'Technology',
    'Education',
    'Entertainment',
    'Fashion',
    'Music',
    'Art',
    'Travel',
    'Business',
    'Health',
    'Community',
    'Environment',
  ];
}
