import 'event.dart';

/// A single item in the attendee `/events/discovery` public-events feed
/// (Batch 3). Lighter than [Event]: it carries only what a discovery card
/// needs plus the embedded [community] so the "Join community to RSVP" gate can
/// deep-link without a second fetch.
class PublicEvent {
  const PublicEvent({
    required this.id,
    required this.name,
    required this.date,
    this.partnerName,
    this.startsAt,
    this.endsAt,
    this.visibility = EventVisibility.public,
    this.location,
    this.address,
    this.capacity,
    this.goingCount = 0,
    this.photos = const <String>[],
    this.community,
  });

  final String id;
  final String name;
  final String? partnerName;
  final DateTime date;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final EventVisibility visibility;
  final String? location;
  final String? address;

  /// null = unlimited.
  final int? capacity;
  final int goingCount;
  final List<String> photos;

  /// Embedded community summary (id / name / slug / type / avatar).
  final PublicEventCommunity? community;

  bool get isPublic => visibility == EventVisibility.public;

  bool get isFull => capacity != null && goingCount >= capacity!;

  String? get coverPhotoUrl => photos.isNotEmpty ? photos.first : null;

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'] as List<dynamic>? ?? const <dynamic>[];
    final photos = <String>[];
    for (final p in photosRaw) {
      if (p is String) {
        photos.add(p);
      } else if (p is Map<String, dynamic>) {
        final url = p['url'] as String?;
        if (url != null) photos.add(url);
      }
    }

    return PublicEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      partnerName: json['partner_name'] as String?,
      date:
          _parseDate(json['date']) ??
          _parseDate(json['starts_at']) ??
          DateTime.now(),
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      visibility: EventVisibility.fromApi(json['visibility'] as String?),
      location: json['location'] as String?,
      address: json['address'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      goingCount: (json['going_count'] as num?)?.toInt() ?? 0,
      photos: photos,
      community: json['community'] is Map<String, dynamic>
          ? PublicEventCommunity.fromJson(
              json['community'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Returns formatted date string (e.g. "Jun 12, 2026").
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = startsAt ?? date;
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// Embedded community summary on a [PublicEvent].
class PublicEventCommunity {
  const PublicEventCommunity({
    required this.id,
    required this.name,
    this.slug,
    this.type,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? slug;
  final String? type;
  final String? avatarUrl;

  factory PublicEventCommunity.fromJson(Map<String, dynamic> json) =>
      PublicEventCommunity(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        slug: json['slug'] as String?,
        type: json['type'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

/// Paginated response for the public-events discovery feed.
class PublicEventsPage {
  const PublicEventsPage({
    required this.events,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  final List<PublicEvent> events;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  bool get hasMore => currentPage < totalPages;

  factory PublicEventsPage.fromJson(Map<String, dynamic> json) {
    final eventsRaw =
        json['events'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        const <dynamic>[];
    final events = eventsRaw
        .whereType<Map<String, dynamic>>()
        .map(PublicEvent.fromJson)
        .toList();

    final pagination = (json['pagination'] as Map<String, dynamic>?) ?? json;

    return PublicEventsPage(
      events: events,
      currentPage: _int(pagination['current_page']) ?? 1,
      totalPages: _int(pagination['total_pages']) ?? 1,
      totalCount: _int(pagination['total_count']) ?? events.length,
      perPage: _int(pagination['per_page']) ?? events.length,
    );
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
