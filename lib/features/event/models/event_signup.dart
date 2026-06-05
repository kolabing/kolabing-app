/// A single attendee row from `GET /events/{id}/signups`.
///
/// Wire shape (per NF-16 ticket):
/// `{ id, profile_id, status, waitlist_position, profile:{id,name,avatar_url} }`.
/// `status` is the backend enum: `going` | `waitlisted`.
class EventSignup {
  const EventSignup({
    required this.id,
    required this.profileId,
    required this.status,
    this.waitlistPosition,
    required this.name,
    this.avatarUrl,
  });

  factory EventSignup.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap =
        profile is Map<String, dynamic> ? profile : const <String, dynamic>{};
    return EventSignup(
      id: (json['id'] ?? '').toString(),
      profileId: (json['profile_id'] ?? profileMap['id'] ?? '').toString(),
      status: (json['status'] as String?) ?? 'going',
      waitlistPosition: (json['waitlist_position'] as num?)?.toInt(),
      name: (profileMap['name'] as String?) ?? '',
      avatarUrl: profileMap['avatar_url'] as String?,
    );
  }

  final String id;
  final String profileId;

  /// `going` | `waitlisted`.
  final String status;

  /// 1-based position when [status] is `waitlisted`; null when going.
  final int? waitlistPosition;
  final String name;
  final String? avatarUrl;

  bool get isWaitlisted => status == 'waitlisted';
}

/// The full attendee roster for an event: confirmed [going] + [waitlist].
class EventSignups {
  const EventSignups({this.going = const [], this.waitlist = const []});

  factory EventSignups.fromJson(Map<String, dynamic> data) {
    List<EventSignup> parse(String key) =>
        (data[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(EventSignup.fromJson)
            .toList();
    return EventSignups(
      going: parse('going'),
      waitlist: parse('waitlist'),
    );
  }

  final List<EventSignup> going;
  final List<EventSignup> waitlist;

  bool get isEmpty => going.isEmpty && waitlist.isEmpty;
}
