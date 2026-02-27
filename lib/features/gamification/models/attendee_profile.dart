/// Attendee profile model for gamification statistics
class AttendeeProfile {
  const AttendeeProfile({
    required this.id,
    required this.profileId,
    this.totalPoints = 0,
    this.totalChallengesCompleted = 0,
    this.totalEventsAttended = 0,
    this.globalRank,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendeeProfile.fromJson(Map<String, dynamic> json) {
    return AttendeeProfile(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      totalChallengesCompleted: json['total_challenges_completed'] as int? ?? 0,
      totalEventsAttended: json['total_events_attended'] as int? ?? 0,
      globalRank: json['global_rank'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String profileId;
  final int totalPoints;
  final int totalChallengesCompleted;
  final int totalEventsAttended;
  final int? globalRank;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'total_points': totalPoints,
        'total_challenges_completed': totalChallengesCompleted,
        'total_events_attended': totalEventsAttended,
        if (globalRank != null) 'global_rank': globalRank,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  AttendeeProfile copyWith({
    String? id,
    String? profileId,
    int? totalPoints,
    int? totalChallengesCompleted,
    int? totalEventsAttended,
    int? globalRank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AttendeeProfile(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        totalPoints: totalPoints ?? this.totalPoints,
        totalChallengesCompleted:
            totalChallengesCompleted ?? this.totalChallengesCompleted,
        totalEventsAttended: totalEventsAttended ?? this.totalEventsAttended,
        globalRank: globalRank ?? this.globalRank,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
