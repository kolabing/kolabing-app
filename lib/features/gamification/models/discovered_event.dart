/// Event discovered via GPS location
class DiscoveredEvent {
  const DiscoveredEvent({
    required this.id,
    required this.name,
    required this.partnerName,
    required this.partnerType,
    required this.date,
    required this.attendeeCount,
    required this.locationLat,
    required this.locationLng,
    this.address,
    this.photos = const [],
    required this.distanceKm,
    required this.createdAt,
    required this.updatedAt,
    this.communityName,
    this.communityType,
  });

  factory DiscoveredEvent.fromJson(Map<String, dynamic> json) {
    // The host community's display name + 17-slug community_type (NF-19). The
    // backend exposes these on the event card; fall back to the legacy
    // partner_* fields when the new keys are absent (self-gate).
    final communityName = json['community_name'] as String?;
    final communityType = json['community_type'] as String?;
    return DiscoveredEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      partnerName: (json['partner_name'] ?? communityName) as String? ?? '',
      partnerType: (json['partner_type'] as String?) ?? 'community',
      date: json['date'] as String,
      attendeeCount: (json['attendee_count'] as int?) ?? 0,
      locationLat: (json['location_lat'] as num?)?.toDouble() ?? 0,
      locationLng: (json['location_lng'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String?,
      // Photos may be plain URL strings or photo objects ({id, url}). Handle both.
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e is String
                  ? e
                  : (e is Map<String, dynamic>
                      ? (e['url'] ?? e['photo_url'] ?? '').toString()
                      : ''))
              .where((u) => u.isNotEmpty)
              .toList() ??
          [],
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      communityName: communityName,
      communityType: communityType,
    );
  }

  final String id;
  final String name;
  final String partnerName;
  final String partnerType;
  final String date;
  final int attendeeCount;
  final double locationLat;
  final double locationLng;
  final String? address;
  final List<String> photos;
  final double distanceKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Host community's display name (NF-19). Falls back to [partnerName].
  final String? communityName;

  /// Host community's `community_type` slug (the unified 17-slug). May be null
  /// if the backend has not yet been deployed.
  final String? communityType;

  /// The host name to render on the card.
  String get hostName =>
      (communityName != null && communityName!.isNotEmpty)
          ? communityName!
          : partnerName;

  /// Check if organized by a business
  bool get isBusiness => partnerType == 'business';

  /// Check if organized by a community
  bool get isCommunity => partnerType == 'community';

  /// Get formatted distance string
  String get distanceDisplay {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Get event date as DateTime
  DateTime get eventDate => DateTime.parse(date);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'partner_name': partnerName,
        'partner_type': partnerType,
        'date': date,
        'attendee_count': attendeeCount,
        'location_lat': locationLat,
        'location_lng': locationLng,
        if (address != null) 'address': address,
        'photos': photos,
        'distance_km': distanceKm,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (communityName != null) 'community_name': communityName,
        if (communityType != null) 'community_type': communityType,
      };
}

/// Response for discovered events with pagination
class DiscoveredEventsResponse {
  const DiscoveredEventsResponse({
    required this.events,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory DiscoveredEventsResponse.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return DiscoveredEventsResponse(
      events: eventsJson
          .map((e) => DiscoveredEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      totalPages: pagination['total_pages'] as int,
      totalCount: pagination['total_count'] as int,
      perPage: pagination['per_page'] as int,
    );
  }

  final List<DiscoveredEvent> events;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  /// Check if there are more pages
  bool get hasMore => currentPage < totalPages;
}
