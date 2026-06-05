import 'dart:ui' show Color;

/// Rich attendee profile aggregate returned by `GET /profiles/{id}/attendee`.
///
/// This is distinct from [AttendeeProfile] (the raw DB stats row). It bundles
/// identity, gamification (level/points/badges), communities, the events the
/// attendee has been checked in to, and an optional friends count.
class AttendeeProfileDetail {
  const AttendeeProfileDetail({
    required this.identity,
    required this.gamification,
    required this.communities,
    required this.eventsAttended,
    this.friendsCount,
  });

  factory AttendeeProfileDetail.fromJson(Map<String, dynamic> json) {
    return AttendeeProfileDetail(
      identity: AttendeeIdentity.fromJson(
        json['identity'] as Map<String, dynamic>,
      ),
      gamification: AttendeeGamification.fromJson(
        json['gamification'] as Map<String, dynamic>? ?? const {},
      ),
      communities: (json['communities'] as List<dynamic>? ?? const [])
          .map((e) => AttendeeCommunity.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventsAttended: AttendeeEventsAttended.fromJson(
        json['events_attended'] as Map<String, dynamic>? ?? const {},
      ),
      friendsCount: json['friends_count'] as int?,
    );
  }

  final AttendeeIdentity identity;
  final AttendeeGamification gamification;
  final List<AttendeeCommunity> communities;
  final AttendeeEventsAttended eventsAttended;

  /// Optional. When null, the friends lane (Batch 5) is not yet wired for this
  /// payload and the UI hides the friends affordances.
  final int? friendsCount;
}

/// Identity block: who the profile belongs to.
class AttendeeIdentity {
  const AttendeeIdentity({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory AttendeeIdentity.fromJson(Map<String, dynamic> json) {
    return AttendeeIdentity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
}

/// Gamification block: points, level and earned badges.
class AttendeeGamification {
  const AttendeeGamification({
    this.points = 0,
    this.level,
    this.badgeCount = 0,
    this.badges = const [],
  });

  factory AttendeeGamification.fromJson(Map<String, dynamic> json) {
    final badgesJson = json['badges'] as Map<String, dynamic>? ?? const {};
    return AttendeeGamification(
      points: json['points'] as int? ?? 0,
      level: json['level'] != null
          ? AttendeeLevel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
      badgeCount: badgesJson['count'] as int? ?? 0,
      badges: (badgesJson['items'] as List<dynamic>? ?? const [])
          .map((e) => AttendeeBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int points;
  final AttendeeLevel? level;
  final int badgeCount;
  final List<AttendeeBadge> badges;
}

/// Level descriptor with XP window and a display colour.
class AttendeeLevel {
  const AttendeeLevel({
    required this.number,
    required this.title,
    required this.minXp,
    required this.maxXp,
    this.colorHex,
  });

  factory AttendeeLevel.fromJson(Map<String, dynamic> json) {
    return AttendeeLevel(
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      minXp: json['min_xp'] as int? ?? 0,
      maxXp: json['max_xp'] as int? ?? 0,
      colorHex: json['color'] as String?,
    );
  }

  final int number;
  final String title;
  final int minXp;
  final int maxXp;
  final String? colorHex;

  /// Progress within the current level, clamped to 0..1. Returns 1.0 when the
  /// level window has no span (e.g. a max level).
  double progressFor(int points) {
    final span = maxXp - minXp;
    if (span <= 0) {
      return 1.0;
    }
    final raw = (points - minXp) / span;
    if (raw.isNaN) {
      return 0.0;
    }
    return raw.clamp(0.0, 1.0);
  }

  /// Parse [colorHex] (e.g. `#FFAA00` or `FFAA00`) into a [Color]. Returns null
  /// when absent or malformed so callers can fall back to a theme colour.
  Color? get color {
    final hex = colorHex;
    if (hex == null || hex.isEmpty) {
      return null;
    }
    var value = hex.replaceFirst('#', '').trim();
    if (value.length == 6) {
      value = 'FF$value';
    }
    if (value.length != 8) {
      return null;
    }
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}

/// A badge earned by the attendee (minimal shape from the aggregate endpoint).
class AttendeeBadge {
  const AttendeeBadge({required this.slug, this.earnedAt});

  factory AttendeeBadge.fromJson(Map<String, dynamic> json) {
    return AttendeeBadge(
      slug: json['slug'] as String? ?? '',
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse(json['earned_at'] as String)
          : null,
    );
  }

  final String slug;
  final DateTime? earnedAt;
}

/// A community the attendee belongs to, with their tier in it.
class AttendeeCommunity {
  const AttendeeCommunity({
    required this.id,
    required this.name,
    this.slug,
    this.avatarUrl,
    this.tierName,
    this.canManage = false,
  });

  factory AttendeeCommunity.fromJson(Map<String, dynamic> json) {
    return AttendeeCommunity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      tierName: json['tier_name'] as String?,
      canManage: json['can_manage'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String? slug;
  final String? avatarUrl;
  final String? tierName;
  final bool canManage;
}

/// Events-attended summary embedded in the profile aggregate.
class AttendeeEventsAttended {
  const AttendeeEventsAttended({this.total = 0, this.recent = const []});

  factory AttendeeEventsAttended.fromJson(Map<String, dynamic> json) {
    return AttendeeEventsAttended(
      total: json['total'] as int? ?? 0,
      recent: (json['recent'] as List<dynamic>? ?? const [])
          .map((e) => AttendedEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int total;
  final List<AttendedEvent> recent;
}

/// A single event the attendee was checked in to.
class AttendedEvent {
  const AttendedEvent({
    required this.eventId,
    required this.eventName,
    this.eventDate,
    this.checkedInAt,
    this.community,
  });

  factory AttendedEvent.fromJson(Map<String, dynamic> json) {
    return AttendedEvent(
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String? ?? '',
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String)
          : null,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'] as String)
          : null,
      community: json['community'] != null
          ? AttendedEventCommunity.fromJson(
              json['community'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String eventId;
  final String eventName;
  final DateTime? eventDate;
  final DateTime? checkedInAt;
  final AttendedEventCommunity? community;
}

/// Lightweight community reference attached to an attended event.
class AttendedEventCommunity {
  const AttendedEventCommunity({required this.id, required this.name});

  factory AttendedEventCommunity.fromJson(Map<String, dynamic> json) {
    return AttendedEventCommunity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String name;
}

/// One page of the paginated `GET /me/events-attended` history.
class AttendedEventsPage {
  const AttendedEventsPage({
    required this.events,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory AttendedEventsPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return AttendedEventsPage(
      events: (json['data'] as List<dynamic>? ?? const [])
          .map((e) => AttendedEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? 0,
      total: meta['total'] as int? ?? 0,
    );
  }

  final List<AttendedEvent> events;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
