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

/// What the app has to do while the challenge happens (#183).
///
/// This is what turns the app from a receipt printer into part of the moment:
/// [photo] opens the camera, and the frame lands on the event wall and on the
/// encounter, so meeting someone acquires a face.
enum ChallengeCaptureType {
  /// Nothing to capture — the challenge happens in the room and the app only
  /// settles it. Every challenge that shipped before #183 is this.
  none,

  /// The camera opens and the challenge produces one photo.
  photo;

  /// Anything this build does not recognise degrades to [none], so a challenge
  /// authored against a newer backend still WORKS here — it just works without
  /// a camera. Never a dead end.
  static ChallengeCaptureType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'photo':
        return ChallengeCaptureType.photo;
      default:
        return ChallengeCaptureType.none;
    }
  }

  String toApiValue() => name;

  bool get needsCamera => this == ChallengeCaptureType.photo;
}

/// Whether a challenge needs a second person at all (#183).
///
/// [solo] is the reason this exists: before it, the whole system was dead until
/// you had *spoken* to someone. A solo camera task works in the first ten
/// minutes, for the person who came alone, and for the person too shy to open
/// with a stranger.
enum ChallengeParticipation {
  /// Two people, one challenge — the original shape.
  pair,

  /// One person. Settled without a partner.
  solo;

  /// Unknown values fall back to [pair], which is how every challenge behaved
  /// before this field existed.
  static ChallengeParticipation fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'solo':
        return ChallengeParticipation.solo;
      default:
        return ChallengeParticipation.pair;
    }
  }

  String toApiValue() => name;

  bool get isSolo => this == ChallengeParticipation.solo;
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
    this.captureType = ChallengeCaptureType.none,
    this.participation = ChallengeParticipation.pair,
    this.captureHint,
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
      captureType: ChallengeCaptureType.fromString(
        json['capture_type'] as String?,
      ),
      participation: ChallengeParticipation.fromString(
        json['participation'] as String?,
      ),
      captureHint: json['capture_hint'] as String?,
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

  /// What the app must capture while this happens. Defaults to
  /// [ChallengeCaptureType.none] so every pre-#183 challenge is unchanged.
  final ChallengeCaptureType captureType;

  /// Whether it needs a partner at all.
  final ChallengeParticipation participation;

  /// Backend-authored line telling the camera step what to shoot ("find
  /// something yellow in the venue"). Dynamic server copy, so it is passed
  /// through rather than localized — same rule as backend error text.
  final String? captureHint;

  /// Check if this is a custom (non-system) challenge
  bool get isCustom => !isSystem;

  /// The camera opens for this one.
  bool get needsCamera => captureType.needsCamera;

  /// No partner needed — playable the moment you walk in.
  bool get isSolo => participation.isSolo;

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
    'capture_type': captureType.toApiValue(),
    'participation': participation.toApiValue(),
    if (captureHint != null) 'capture_hint': captureHint,
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
    ChallengeCaptureType? captureType,
    ChallengeParticipation? participation,
    String? captureHint,
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
    captureType: captureType ?? this.captureType,
    participation: participation ?? this.participation,
    captureHint: captureHint ?? this.captureHint,
  );
}
