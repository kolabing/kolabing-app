/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy,
  medium,
  hard;

  /// Parse difficulty from string
  static ChallengeDifficulty fromString(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return ChallengeDifficulty.easy;
      case 'medium':
        return ChallengeDifficulty.medium;
      case 'hard':
        return ChallengeDifficulty.hard;
      default:
        return ChallengeDifficulty.easy;
    }
  }

  /// Convert to API string value
  String toApiValue() => name;

  /// Display label for UI
  String get label {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'EASY';
      case ChallengeDifficulty.medium:
        return 'MEDIUM';
      case ChallengeDifficulty.hard:
        return 'HARD';
    }
  }

  /// Default points for this difficulty
  int get defaultPoints {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 5;
      case ChallengeDifficulty.medium:
        return 15;
      case ChallengeDifficulty.hard:
        return 30;
    }
  }
}

/// How a challenge is played — the backend's `proof_type` (kolabing-v2#216).
///
/// This is what turns the app from a receipt printer into part of the moment:
/// [photo] opens the camera, and the frame lands on the completion and on the
/// meeting, so meeting someone acquires a face.
///
/// It is an **engine selector, not a gate**. The server does not refuse a
/// verification that arrives without a photo, and neither does this app. A hard
/// requirement would mean a pair who cannot get a photo up — no signal in a
/// basement gym, a denied permission, a failed upload — lose what they just did
/// together. The person confirming is the check on honesty; the photo is a
/// memento.
enum ChallengeProofType {
  /// The instruction is the game. What every challenge that predates the
  /// column reports, and the default.
  text,

  /// Open the camera as soon as the pair agrees.
  photo;

  /// Anything this build does not recognise degrades to [text], so a challenge
  /// authored against a newer backend still WORKS here — it just works without
  /// a camera. Never a dead end.
  static ChallengeProofType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'photo':
        return ChallengeProofType.photo;
      default:
        return ChallengeProofType.text;
    }
  }

  String toApiValue() => name;

  bool get needsCamera => this == ChallengeProofType.photo;
}

/// Challenge model
class Challenge {
  const Challenge({
    required this.id,
    required this.name,
    this.description,
    required this.difficulty,
    required this.points,
    required this.isSystem,
    this.eventId,
    required this.createdAt,
    required this.updatedAt,
    this.proofType = ChallengeProofType.text,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      difficulty: ChallengeDifficulty.fromString(json['difficulty'] as String),
      points: json['points'] as int,
      isSystem: json['is_system'] as bool,
      eventId: json['event_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      proofType: ChallengeProofType.fromString(json['proof_type'] as String?),
    );
  }

  final String id;
  final String name;
  final String? description;
  final ChallengeDifficulty difficulty;
  final int points;
  final bool isSystem;
  final String? eventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// How it is played. Defaults to [ChallengeProofType.text] so every
  /// challenge that predates the column is unchanged.
  final ChallengeProofType proofType;

  /// Check if this is a custom (non-system) challenge
  bool get isCustom => !isSystem;

  /// The camera opens for this one.
  bool get needsCamera => proofType.needsCamera;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'difficulty': difficulty.toApiValue(),
    'points': points,
    'is_system': isSystem,
    if (eventId != null) 'event_id': eventId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'proof_type': proofType.toApiValue(),
  };

  Challenge copyWith({
    String? id,
    String? name,
    String? description,
    ChallengeDifficulty? difficulty,
    int? points,
    bool? isSystem,
    String? eventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChallengeProofType? proofType,
  }) => Challenge(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    difficulty: difficulty ?? this.difficulty,
    points: points ?? this.points,
    isSystem: isSystem ?? this.isSystem,
    eventId: eventId ?? this.eventId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    proofType: proofType ?? this.proofType,
  );
}
