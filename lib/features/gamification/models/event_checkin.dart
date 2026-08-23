/// Event check-in model
class EventCheckin {
  const EventCheckin({
    required this.id,
    required this.eventId,
    required this.profileId,
    required this.checkedInAt,
    required this.createdAt,
    this.eventName,
    this.profileName,
    this.pointsEarned,
    this.communityId,
    this.communityName,
    this.isMember,
  });

  factory EventCheckin.fromJson(Map<String, dynamic> json) {
    return EventCheckin(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      profileId: json['profile_id'] as String,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      eventName: json['event_name'] as String?,
      profileName: json['profile_name'] as String?,
      pointsEarned: json['points_earned'] as int?,
      communityId:
          (json['community'] as Map<String, dynamic>?)?['id'] as String?,
      communityName:
          (json['community'] as Map<String, dynamic>?)?['name'] as String?,
      isMember: json['is_member'] as bool?,
    );
  }

  final String id;
  final String eventId;
  final String profileId;
  final DateTime checkedInAt;
  final DateTime createdAt;

  /// Event name (included in response)
  final String? eventName;

  /// Profile name (included in list responses)
  final String? profileName;

  /// Points earned from check-in
  final int? pointsEarned;

  /// The host community, when the event has one (#148).
  final String? communityId;
  final String? communityName;

  /// Whether the person who just checked in already belongs to that community.
  /// Null when there is no community to belong to — and null is NOT "no": an
  /// older backend does not send this, and inventing a `false` would ask
  /// everyone to join something the app cannot name.
  final bool? isMember;

  /// Whether there is a membership worth offering after this check-in.
  bool get canOfferMembership =>
      communityId != null && communityName != null && isMember == false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'profile_id': profileId,
    'checked_in_at': checkedInAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    if (eventName != null) 'event_name': eventName,
    if (profileName != null) 'profile_name': profileName,
    if (pointsEarned != null) 'points_earned': pointsEarned,
    if (communityId != null)
      'community': {'id': communityId, 'name': communityName},
    if (isMember != null) 'is_member': isMember,
  };

  EventCheckin copyWith({
    String? id,
    String? eventId,
    String? profileId,
    DateTime? checkedInAt,
    DateTime? createdAt,
    String? eventName,
    String? profileName,
    int? pointsEarned,
    String? communityId,
    String? communityName,
    bool? isMember,
  }) => EventCheckin(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    profileId: profileId ?? this.profileId,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    createdAt: createdAt ?? this.createdAt,
    eventName: eventName ?? this.eventName,
    profileName: profileName ?? this.profileName,
    pointsEarned: pointsEarned ?? this.pointsEarned,
    communityId: communityId ?? this.communityId,
    communityName: communityName ?? this.communityName,
    isMember: isMember ?? this.isMember,
  );
}
