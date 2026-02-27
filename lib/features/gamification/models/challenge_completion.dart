import 'challenge.dart';

/// Challenge completion status
enum ChallengeCompletionStatus {
  pending,
  verified,
  rejected;

  /// Parse status from string
  static ChallengeCompletionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ChallengeCompletionStatus.pending;
      case 'verified':
        return ChallengeCompletionStatus.verified;
      case 'rejected':
        return ChallengeCompletionStatus.rejected;
      default:
        return ChallengeCompletionStatus.pending;
    }
  }

  /// Convert to API string value
  String toApiValue() => name;

  /// Display label for UI
  String get label {
    switch (this) {
      case ChallengeCompletionStatus.pending:
        return 'PENDING';
      case ChallengeCompletionStatus.verified:
        return 'VERIFIED';
      case ChallengeCompletionStatus.rejected:
        return 'REJECTED';
    }
  }
}

/// Challenge completion model
class ChallengeCompletion {
  const ChallengeCompletion({
    required this.id,
    this.challenge,
    required this.eventId,
    required this.challengerProfileId,
    required this.verifierProfileId,
    required this.status,
    required this.pointsEarned,
    this.completedAt,
    required this.createdAt,
    this.challengeName,
    this.challengeDifficulty,
    this.eventName,
    this.challengerName,
    this.verifierName,
  });

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletion(
      id: json['id'] as String,
      challenge: json['challenge'] != null
          ? Challenge.fromJson(json['challenge'] as Map<String, dynamic>)
          : null,
      eventId: json['event_id'] as String,
      challengerProfileId: json['challenger_profile_id'] as String,
      verifierProfileId: json['verifier_profile_id'] as String,
      status:
          ChallengeCompletionStatus.fromString(json['status'] as String),
      pointsEarned: json['points_earned'] as int,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      challengeName: json['challenge_name'] as String?,
      challengeDifficulty: json['challenge_difficulty'] != null
          ? ChallengeDifficulty.fromString(json['challenge_difficulty'] as String)
          : null,
      eventName: json['event_name'] as String?,
      challengerName: json['challenger_name'] as String?,
      verifierName: json['verifier_name'] as String?,
    );
  }

  final String id;
  final Challenge? challenge;
  final String eventId;
  final String challengerProfileId;
  final String verifierProfileId;
  final ChallengeCompletionStatus status;
  final int pointsEarned;
  final DateTime? completedAt;
  final DateTime createdAt;

  /// Challenge name (included in list responses)
  final String? challengeName;

  /// Challenge difficulty (included in list responses)
  final ChallengeDifficulty? challengeDifficulty;

  /// Event name (included in list responses)
  final String? eventName;

  /// Challenger name (included in list responses)
  final String? challengerName;

  /// Verifier name (included in list responses)
  final String? verifierName;

  /// Check if this completion is pending
  bool get isPending => status == ChallengeCompletionStatus.pending;

  /// Check if this completion is verified
  bool get isVerified => status == ChallengeCompletionStatus.verified;

  /// Check if this completion is rejected
  bool get isRejected => status == ChallengeCompletionStatus.rejected;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (challenge != null) 'challenge': challenge!.toJson(),
        'event_id': eventId,
        'challenger_profile_id': challengerProfileId,
        'verifier_profile_id': verifierProfileId,
        'status': status.toApiValue(),
        'points_earned': pointsEarned,
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  ChallengeCompletion copyWith({
    String? id,
    Challenge? challenge,
    String? eventId,
    String? challengerProfileId,
    String? verifierProfileId,
    ChallengeCompletionStatus? status,
    int? pointsEarned,
    DateTime? completedAt,
    DateTime? createdAt,
  }) =>
      ChallengeCompletion(
        id: id ?? this.id,
        challenge: challenge ?? this.challenge,
        eventId: eventId ?? this.eventId,
        challengerProfileId: challengerProfileId ?? this.challengerProfileId,
        verifierProfileId: verifierProfileId ?? this.verifierProfileId,
        status: status ?? this.status,
        pointsEarned: pointsEarned ?? this.pointsEarned,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
