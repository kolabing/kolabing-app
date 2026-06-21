/// Max photos that can be picked in a single "add photos" action.
const int kEventGalleryMaxPerAdd = 5;

/// Hard cap on the total number of photos an event gallery can hold.
const int kEventGalleryMaxTotal = 20;

/// Event model representing a past collaboration event
class Event {
  final String id;
  final String name;
  final EventPartner partner;
  final DateTime date;
  final int attendeeCount;
  final List<EventPhoto> photos;
  final List<EventVideo> videos;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Phase-3 (upcoming events / RSVP). Null/0 for legacy past-showcase events.
  final DateTime? startsAt;
  final String? location;
  final int? capacity; // null = unlimited
  final int goingCount;
  final int waitlistCount;
  final String? mySignupStatus; // 'going' | 'waitlisted' | null
  final int? waitlistPosition;
  final bool isUpcoming;
  final String? communityId;

  /// Viewer-scoped gate (`can_access` from the API). False when this member's
  /// tier is not in the event's `tier_gate` — the app then locks the event
  /// (no open into details). Defaults to true (legacy/ungated events stay open).
  final bool canAccess;

  /// Set when this event is an occurrence of a recurring series.
  final String? seriesId;
  final int? occurrenceIndex;

  /// Who can see this event (#1): `public` | `members` | `tier`. `public`
  /// events surface in city discovery. Null for legacy events (treated as
  /// members by the backend default).
  final String? visibility;

  const Event({
    required this.id,
    required this.name,
    required this.partner,
    required this.date,
    required this.attendeeCount,
    required this.photos,
    this.videos = const [],
    required this.createdAt,
    this.updatedAt,
    this.startsAt,
    this.location,
    this.capacity,
    this.goingCount = 0,
    this.waitlistCount = 0,
    this.mySignupStatus,
    this.waitlistPosition,
    this.isUpcoming = false,
    this.communityId,
    this.canAccess = true,
    this.seriesId,
    this.occurrenceIndex,
    this.visibility,
  });

  /// True when this event belongs to a recurring series.
  bool get isRecurring => seriesId != null;

  /// True when the viewer has a confirmed 'going' sign-up.
  bool get isGoing => mySignupStatus == 'going';

  /// True when the viewer is on the waitlist.
  bool get isWaitlisted => mySignupStatus == 'waitlisted';

  /// True when capacity is set and the going count has reached it.
  bool get isFull => capacity != null && goingCount >= capacity!;

  factory Event.fromJson(Map<String, dynamic> json) {
    // Partner can be a full object or null (when partner_name text is used)
    EventPartner partner;
    if (json['partner'] != null && json['partner'] is Map<String, dynamic>) {
      partner = EventPartner.fromJson(json['partner'] as Map<String, dynamic>);
    } else {
      partner = EventPartner(
        name: (json['partner_name'] as String?) ?? '',
        type: PartnerType.values.firstWhere(
          (e) => e.name == (json['partner_type'] as String?),
          orElse: () => PartnerType.community,
        ),
      );
    }

    // my_signup is null, a string, or { status, waitlist_position }.
    final sig = json['my_signup'];
    String? mySignupStatus;
    int? waitlistPosition;
    if (sig is Map<String, dynamic>) {
      mySignupStatus = sig['status'] as String?;
      waitlistPosition = (sig['waitlist_position'] as num?)?.toInt();
    } else if (sig is String) {
      mySignupStatus = sig;
    }

    return Event(
      id: json['id'] as String,
      name: json['name'] as String,
      partner: partner,
      date: DateTime.parse(json['date'] as String),
      attendeeCount: (json['attendee_count'] as num?)?.toInt() ?? 0,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'] as String)
          : null,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      goingCount: (json['going_count'] as num?)?.toInt() ?? 0,
      waitlistCount: (json['waitlist_count'] as num?)?.toInt() ?? 0,
      mySignupStatus: mySignupStatus,
      waitlistPosition: waitlistPosition,
      isUpcoming: json['is_upcoming'] as bool? ?? false,
      communityId: json['community_id'] as String?,
      canAccess: json['can_access'] as bool? ?? true,
      seriesId: json['series_id'] as String?,
      occurrenceIndex: (json['occurrence_index'] as num?)?.toInt(),
      visibility: json['visibility'] as String?,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => EventPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos:
          (json['videos'] as List<dynamic>?)
              ?.map((e) => EventVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'partner': partner.toJson(),
    'date': date.toIso8601String().split('T').first,
    'attendee_count': attendeeCount,
    'photos': photos.map((e) => e.toJson()).toList(),
    if (videos.isNotEmpty) 'videos': videos.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  Event copyWith({
    String? id,
    String? name,
    EventPartner? partner,
    DateTime? date,
    int? attendeeCount,
    List<EventPhoto>? photos,
    List<EventVideo>? videos,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    String? location,
    int? capacity,
    int? goingCount,
    int? waitlistCount,
    String? mySignupStatus,
    int? waitlistPosition,
    bool? isUpcoming,
    String? communityId,
    bool? canAccess,
    String? seriesId,
    int? occurrenceIndex,
    String? visibility,
  }) => Event(
    id: id ?? this.id,
    name: name ?? this.name,
    partner: partner ?? this.partner,
    date: date ?? this.date,
    attendeeCount: attendeeCount ?? this.attendeeCount,
    photos: photos ?? this.photos,
    videos: videos ?? this.videos,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    startsAt: startsAt ?? this.startsAt,
    location: location ?? this.location,
    capacity: capacity ?? this.capacity,
    goingCount: goingCount ?? this.goingCount,
    waitlistCount: waitlistCount ?? this.waitlistCount,
    mySignupStatus: mySignupStatus ?? this.mySignupStatus,
    waitlistPosition: waitlistPosition ?? this.waitlistPosition,
    isUpcoming: isUpcoming ?? this.isUpcoming,
    communityId: communityId ?? this.communityId,
    canAccess: canAccess ?? this.canAccess,
    seriesId: seriesId ?? this.seriesId,
    occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
    visibility: visibility ?? this.visibility,
  );

  /// Returns the best available cover media thumbnail.
  String? get coverPhotoUrl => photos.isNotEmpty
      ? photos.first.url
      : (videos.isNotEmpty ? videos.first.thumbnailUrl : null);

  /// Returns formatted date string
  String get formattedDate {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns formatted attendee count (e.g., "1.2K")
  String get formattedAttendeeCount {
    if (attendeeCount >= 1000) {
      final k = attendeeCount / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return attendeeCount.toString();
  }
}

/// Partner information for an event
class EventPartner {
  final String? id;
  final String name;
  final String? profilePhoto;
  final PartnerType type;

  const EventPartner({
    this.id,
    required this.name,
    this.profilePhoto,
    required this.type,
  });

  factory EventPartner.fromJson(Map<String, dynamic> json) => EventPartner(
    id: json['id'] as String?,
    name: (json['name'] as String?) ?? '',
    profilePhoto: json['profile_photo'] as String?,
    type: PartnerType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => PartnerType.community,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profile_photo': profilePhoto,
    'type': type.name,
  };
}

/// Type of partner (business or community)
enum PartnerType { business, community }

/// Photo associated with an event
class EventPhoto {
  final String id;
  final String url;
  final String? thumbnailUrl;

  const EventPhoto({required this.id, required this.url, this.thumbnailUrl});

  factory EventPhoto.fromJson(Map<String, dynamic> json) => EventPhoto(
    id: (json['id'] as String?) ?? '',
    url: json['url'] as String,
    thumbnailUrl: json['thumbnail_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'thumbnail_url': thumbnailUrl,
  };
}

/// Video associated with an event
class EventVideo {
  final String id;
  final String url;
  final String? thumbnailUrl;

  const EventVideo({required this.id, required this.url, this.thumbnailUrl});

  factory EventVideo.fromJson(Map<String, dynamic> json) => EventVideo(
    id: (json['id'] as String?) ?? '',
    url: json['url'] as String,
    thumbnailUrl: json['thumbnail_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'thumbnail_url': thumbnailUrl,
  };
}

/// Request model for creating an event (with photo files)
class EventCreateRequest {
  final String name;
  final String partnerName;
  final PartnerType partnerType;
  final DateTime date;
  final int attendeeCount;
  final List<String> photoPaths;
  final List<String> videoPaths;

  const EventCreateRequest({
    required this.name,
    required this.partnerName,
    required this.partnerType,
    required this.date,
    required this.attendeeCount,
    required this.photoPaths,
    this.videoPaths = const [],
  });
}

/// Request model for updating an event (no photo updates supported)
class EventUpdateRequest {
  final String? name;
  final String? partnerName;
  final String? partnerType;
  final String? date;
  final int? attendeeCount;

  const EventUpdateRequest({
    this.name,
    this.partnerName,
    this.partnerType,
    this.date,
    this.attendeeCount,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (partnerName != null) data['partner_name'] = partnerName;
    if (partnerType != null) data['partner_type'] = partnerType;
    if (date != null) data['date'] = date;
    if (attendeeCount != null) data['attendee_count'] = attendeeCount;
    return data;
  }
}

/// Pagination metadata from the API
class EventPagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  const EventPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory EventPagination.fromJson(Map<String, dynamic> json) =>
      EventPagination(
        currentPage: json['current_page'] as int,
        totalPages: json['total_pages'] as int,
        totalCount: json['total_count'] as int,
        perPage: json['per_page'] as int,
      );

  bool get hasMore => currentPage < totalPages;
}
