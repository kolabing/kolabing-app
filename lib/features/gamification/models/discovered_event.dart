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
  });

  factory DiscoveredEvent.fromJson(Map<String, dynamic> json) {
    return DiscoveredEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      partnerName: json['partner_name'] as String,
      partnerType: json['partner_type'] as String,
      date: json['date'] as String,
      attendeeCount: json['attendee_count'] as int,
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      address: json['address'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      distanceKm: (json['distance_km'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
