import 'package:flutter/material.dart';

import 'package:kolabing_app/features/kolab/enums/deliverable_type.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/enums/need_type.dart';
import 'package:kolabing_app/features/kolab/enums/product_type.dart';
import 'package:kolabing_app/features/kolab/enums/venue_type.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

// =============================================================================
// Venue Preference
// =============================================================================

/// Where the collaboration will take place.
enum VenuePreference {
  businessProvides,
  communityProvides,
  noVenue;

  String get displayName {
    switch (this) {
      case VenuePreference.businessProvides:
        return 'Business Provides';
      case VenuePreference.communityProvides:
        return 'Community Provides';
      case VenuePreference.noVenue:
        return 'No Venue Needed';
    }
  }

  String get description {
    switch (this) {
      case VenuePreference.businessProvides:
        return 'The business will provide the venue';
      case VenuePreference.communityProvides:
        return 'The community will provide the venue';
      case VenuePreference.noVenue:
        return 'No physical venue required';
    }
  }

  String toApiValue() {
    switch (this) {
      case VenuePreference.businessProvides:
        return 'business_provides';
      case VenuePreference.communityProvides:
        return 'community_provides';
      case VenuePreference.noVenue:
        return 'no_venue';
    }
  }

  static VenuePreference fromString(String value) {
    switch (value) {
      case 'business_provides':
        return VenuePreference.businessProvides;
      case 'community_provides':
        return VenuePreference.communityProvides;
      case 'no_venue':
        return VenuePreference.noVenue;
      default:
        return VenuePreference.noVenue;
    }
  }
}

// =============================================================================
// Kolab Media
// =============================================================================

/// A media attachment for a Kolab (photo or video).
@immutable
class KolabMedia {
  const KolabMedia({
    required this.url,
    required this.type,
    this.sortOrder = 0,
  });

  factory KolabMedia.fromJson(Map<String, dynamic> json) => KolabMedia(
        url: json['url']?.toString() ?? '',
        type: json['type']?.toString() ?? 'image',
        sortOrder: _parseInt(json['sort_order']) ?? 0,
      );

  final String url;
  final String type;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
        'sort_order': sortOrder,
      };

  KolabMedia copyWith({
    String? url,
    String? type,
    int? sortOrder,
  }) =>
      KolabMedia(
        url: url ?? this.url,
        type: type ?? this.type,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// =============================================================================
// Past Event
// =============================================================================

/// A past event reference for credibility/portfolio.
@immutable
class PastEvent {
  const PastEvent({
    required this.name,
    required this.date,
    this.partnerName,
    this.photos = const [],
  });

  factory PastEvent.fromJson(Map<String, dynamic> json) => PastEvent(
        name: json['name']?.toString() ?? '',
        date: _parseDate(json['date']),
        partnerName: json['partner_name']?.toString(),
        photos: json['photos'] is List
            ? (json['photos'] as List).map((e) => e.toString()).toList()
            : const [],
      );

  final String name;
  final DateTime date;
  final String? partnerName;
  final List<String> photos;

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String().split('T').first,
        if (partnerName != null && partnerName!.isNotEmpty)
          'partner_name': partnerName,
        if (photos.isNotEmpty) 'photos': photos,
      };

  PastEvent copyWith({
    String? name,
    DateTime? date,
    String? partnerName,
    List<String>? photos,
    bool clearPartnerName = false,
  }) =>
      PastEvent(
        name: name ?? this.name,
        date: date ?? this.date,
        partnerName:
            clearPartnerName ? null : (partnerName ?? this.partnerName),
        photos: photos ?? this.photos,
      );

  static DateTime _parseDate(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// =============================================================================
// Kolab Model
// =============================================================================

/// Main Kolab model representing a collaboration posting.
@immutable
class Kolab {
  const Kolab({
    required this.intentType,
    this.id,
    this.status = 'draft',
    this.title = '',
    this.description = '',
    this.preferredCity = '',
    this.area,
    this.media = const [],
    this.availabilityMode,
    this.availabilityStart,
    this.availabilityEnd,
    this.selectedTime,
    this.recurringDays = const [],
    this.needs = const [],
    this.communityTypes = const [],
    this.communitySize,
    this.typicalAttendance,
    this.offersInReturn = const [],
    this.venuePreference,
    this.venueName,
    this.venueType,
    this.capacity,
    this.venueAddress,
    this.productName,
    this.productType,
    this.offering = const [],
    this.seekingCommunities = const [],
    this.minCommunitySize,
    this.expects = const [],
    this.pastEvents = const [],
    this.publishedAt,
    this.createdAt,
  });

  /// Creates an empty Kolab with sensible defaults for the given intent type.
  factory Kolab.empty(IntentType intentType) => Kolab(
        intentType: intentType,
        status: 'draft',
        title: '',
        description: '',
        preferredCity: '',
        media: const [],
        recurringDays: const [],
        needs: const [],
        communityTypes: const [],
        offersInReturn: const [],
        offering: const [],
        seekingCommunities: const [],
        expects: const [],
        pastEvents: const [],
      );

  factory Kolab.fromJson(Map<String, dynamic> json) => Kolab(
        id: json['id']?.toString(),
        intentType: IntentType.fromString(
            json['intent_type']?.toString() ?? 'community_seeking'),
        status: json['status']?.toString() ?? 'draft',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        preferredCity: json['preferred_city']?.toString() ?? '',
        area: json['area']?.toString(),
        media: json['media'] is List
            ? (json['media'] as List)
                .map((e) => KolabMedia.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
        availabilityMode: json['availability_mode'] != null
            ? AvailabilityMode.fromString(
                json['availability_mode'].toString())
            : null,
        availabilityStart:
            _parseDateTimeNullable(json['availability_start']),
        availabilityEnd: _parseDateTimeNullable(json['availability_end']),
        selectedTime:
            _parseTimeOfDay(json['selected_time']?.toString()),
        recurringDays: _parseIntList(json['recurring_days']),
        needs: json['needs'] is List
            ? (json['needs'] as List)
                .map((e) => NeedType.fromString(e.toString()))
                .toList()
            : const [],
        communityTypes: json['community_types'] is List
            ? (json['community_types'] as List)
                .map((e) => e.toString())
                .toList()
            : const [],
        communitySize: _parseInt(json['community_size']),
        typicalAttendance: _parseInt(json['typical_attendance']),
        offersInReturn: json['offers_in_return'] is List
            ? (json['offers_in_return'] as List)
                .map((e) => DeliverableType.fromString(e.toString()))
                .toList()
            : const [],
        venuePreference: json['venue_preference'] != null
            ? VenuePreference.fromString(
                json['venue_preference'].toString())
            : null,
        venueName: json['venue_name']?.toString(),
        venueType: json['venue_type'] != null
            ? VenueType.fromString(json['venue_type'].toString())
            : null,
        capacity: _parseInt(json['capacity']),
        venueAddress: json['venue_address']?.toString(),
        productName: json['product_name']?.toString(),
        productType: json['product_type'] != null
            ? ProductType.fromString(json['product_type'].toString())
            : null,
        offering: json['offering'] is List
            ? (json['offering'] as List)
                .map((e) => e.toString())
                .toList()
            : const [],
        seekingCommunities: json['seeking_communities'] is List
            ? (json['seeking_communities'] as List)
                .map((e) => e.toString())
                .toList()
            : const [],
        minCommunitySize: _parseInt(json['min_community_size']),
        expects: json['expects'] is List
            ? (json['expects'] as List)
                .map((e) => DeliverableType.fromString(e.toString()))
                .toList()
            : const [],
        pastEvents: json['past_events'] is List
            ? (json['past_events'] as List)
                .map((e) => PastEvent.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
        publishedAt: _parseDateTimeNullable(json['published_at']),
        createdAt: _parseDateTimeNullable(json['created_at']),
      );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  final String? id;
  final IntentType intentType;
  final String status;

  // Core info
  final String title;
  final String description;
  final String preferredCity;
  final String? area;
  final List<KolabMedia> media;

  // Availability
  final AvailabilityMode? availabilityMode;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;
  final TimeOfDay? selectedTime;
  final List<int> recurringDays;

  // Community seeking fields
  final List<NeedType> needs;
  final List<String> communityTypes;
  final int? communitySize;
  final int? typicalAttendance;
  final List<DeliverableType> offersInReturn;
  final VenuePreference? venuePreference;

  // Venue promotion fields
  final String? venueName;
  final VenueType? venueType;
  final int? capacity;
  final String? venueAddress;

  // Product promotion fields
  final String? productName;
  final ProductType? productType;

  // Business offering fields (venue/product promotion)
  final List<String> offering;
  final List<String> seekingCommunities;
  final int? minCommunitySize;
  final List<DeliverableType> expects;

  // Portfolio
  final List<PastEvent> pastEvents;

  // Timestamps
  final DateTime? publishedAt;
  final DateTime? createdAt;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'intent_type': intentType.toApiValue(),
        'status': status,
        'title': title,
        'description': description,
        'preferred_city': preferredCity,
        if (area != null && area!.isNotEmpty) 'area': area,
        if (media.isNotEmpty)
          'media': media.map((m) => m.toJson()).toList(),
        if (availabilityMode != null)
          'availability_mode': availabilityMode!.toApiValue(),
        if (availabilityStart != null)
          'availability_start':
              availabilityStart!.toIso8601String().split('T').first,
        if (availabilityEnd != null)
          'availability_end':
              availabilityEnd!.toIso8601String().split('T').first,
        if (selectedTime != null)
          'selected_time':
              '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
        if (recurringDays.isNotEmpty) 'recurring_days': recurringDays,
        if (needs.isNotEmpty)
          'needs': needs.map((n) => n.toApiValue()).toList(),
        if (communityTypes.isNotEmpty) 'community_types': communityTypes,
        if (communitySize != null) 'community_size': communitySize,
        if (typicalAttendance != null)
          'typical_attendance': typicalAttendance,
        if (offersInReturn.isNotEmpty)
          'offers_in_return':
              offersInReturn.map((o) => o.toApiValue()).toList(),
        if (venuePreference != null)
          'venue_preference': venuePreference!.toApiValue(),
        if (venueName != null && venueName!.isNotEmpty)
          'venue_name': venueName,
        if (venueType != null) 'venue_type': venueType!.toApiValue(),
        if (capacity != null) 'capacity': capacity,
        if (venueAddress != null && venueAddress!.isNotEmpty)
          'venue_address': venueAddress,
        if (productName != null && productName!.isNotEmpty)
          'product_name': productName,
        if (productType != null)
          'product_type': productType!.toApiValue(),
        if (offering.isNotEmpty) 'offering': offering,
        if (seekingCommunities.isNotEmpty)
          'seeking_communities': seekingCommunities,
        if (minCommunitySize != null)
          'min_community_size': minCommunitySize,
        if (expects.isNotEmpty)
          'expects': expects.map((e) => e.toApiValue()).toList(),
        if (pastEvents.isNotEmpty)
          'past_events': pastEvents.map((e) => e.toJson()).toList(),
        if (publishedAt != null)
          'published_at': publishedAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  Kolab copyWith({
    String? id,
    IntentType? intentType,
    String? status,
    String? title,
    String? description,
    String? preferredCity,
    String? area,
    List<KolabMedia>? media,
    AvailabilityMode? availabilityMode,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
    TimeOfDay? selectedTime,
    List<int>? recurringDays,
    List<NeedType>? needs,
    List<String>? communityTypes,
    int? communitySize,
    int? typicalAttendance,
    List<DeliverableType>? offersInReturn,
    VenuePreference? venuePreference,
    String? venueName,
    VenueType? venueType,
    int? capacity,
    String? venueAddress,
    String? productName,
    ProductType? productType,
    List<String>? offering,
    List<String>? seekingCommunities,
    int? minCommunitySize,
    List<DeliverableType>? expects,
    List<PastEvent>? pastEvents,
    DateTime? publishedAt,
    DateTime? createdAt,
    bool clearId = false,
    bool clearArea = false,
    bool clearAvailabilityMode = false,
    bool clearAvailabilityStart = false,
    bool clearAvailabilityEnd = false,
    bool clearSelectedTime = false,
    bool clearCommunitySize = false,
    bool clearTypicalAttendance = false,
    bool clearVenuePreference = false,
    bool clearVenueName = false,
    bool clearVenueType = false,
    bool clearCapacity = false,
    bool clearVenueAddress = false,
    bool clearProductName = false,
    bool clearProductType = false,
    bool clearMinCommunitySize = false,
    bool clearPublishedAt = false,
    bool clearCreatedAt = false,
  }) =>
      Kolab(
        id: clearId ? null : (id ?? this.id),
        intentType: intentType ?? this.intentType,
        status: status ?? this.status,
        title: title ?? this.title,
        description: description ?? this.description,
        preferredCity: preferredCity ?? this.preferredCity,
        area: clearArea ? null : (area ?? this.area),
        media: media ?? this.media,
        availabilityMode: clearAvailabilityMode
            ? null
            : (availabilityMode ?? this.availabilityMode),
        availabilityStart: clearAvailabilityStart
            ? null
            : (availabilityStart ?? this.availabilityStart),
        availabilityEnd: clearAvailabilityEnd
            ? null
            : (availabilityEnd ?? this.availabilityEnd),
        selectedTime: clearSelectedTime
            ? null
            : (selectedTime ?? this.selectedTime),
        recurringDays: recurringDays ?? this.recurringDays,
        needs: needs ?? this.needs,
        communityTypes: communityTypes ?? this.communityTypes,
        communitySize: clearCommunitySize
            ? null
            : (communitySize ?? this.communitySize),
        typicalAttendance: clearTypicalAttendance
            ? null
            : (typicalAttendance ?? this.typicalAttendance),
        offersInReturn: offersInReturn ?? this.offersInReturn,
        venuePreference: clearVenuePreference
            ? null
            : (venuePreference ?? this.venuePreference),
        venueName: clearVenueName ? null : (venueName ?? this.venueName),
        venueType: clearVenueType ? null : (venueType ?? this.venueType),
        capacity: clearCapacity ? null : (capacity ?? this.capacity),
        venueAddress:
            clearVenueAddress ? null : (venueAddress ?? this.venueAddress),
        productName:
            clearProductName ? null : (productName ?? this.productName),
        productType:
            clearProductType ? null : (productType ?? this.productType),
        offering: offering ?? this.offering,
        seekingCommunities:
            seekingCommunities ?? this.seekingCommunities,
        minCommunitySize: clearMinCommunitySize
            ? null
            : (minCommunitySize ?? this.minCommunitySize),
        expects: expects ?? this.expects,
        pastEvents: pastEvents ?? this.pastEvents,
        publishedAt:
            clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
        createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
      );

  @override
  String toString() =>
      'Kolab(id: $id, intentType: $intentType, title: $title, status: $status)';

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static DateTime? _parseDateTimeNullable(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<int> _parseIntList(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    }
    final single = int.tryParse(value.toString());
    return single != null ? [single] : const [];
  }
}
