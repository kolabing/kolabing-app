/// The People Layer (#183) — a ledger of the people you met, alongside the
/// existing ledger of what you did.
///
/// The distinction matters. `challenge_completions` records an **action**; an
/// [Encounter] records a **person**. Everything that makes the challenge system
/// worth coming back to reads off this: the pair level, the night recap, the
/// quests, and the ghost invite.
library;

/// How many separate events you and this person have both turned up to and
/// completed a challenge at.
///
/// The server counts DISTINCT events, never challenges — ten challenges with
/// the same person in one night is still one. That is enforced by a unique
/// index on `(profile_id, other_profile_id, event_id)`, so farming is closed by
/// the schema rather than by a rule someone has to remember, and the number
/// means the right thing: *how many times were we in the same room*.
///
/// The ladder itself is **backend-authored** — the app never decides where a
/// level starts or what it pays. [PairLevel] carries what the server sent.
class PairLevel {
  const PairLevel({
    required this.timesMet,
    required this.key,
    this.nextAt,
    this.justLevelledUp = false,
    this.bonusAwarded = 0,
  });

  factory PairLevel.fromJson(Map<String, dynamic> json) => PairLevel(
    timesMet: json['times_met'] as int? ?? 1,
    key: json['key'] as String? ?? 'met',
    nextAt: json['next_at'] as int?,
    justLevelledUp: json['just_levelled_up'] as bool? ?? false,
    bonusAwarded: json['bonus_awarded'] as int? ?? 0,
  );

  final int timesMet;

  /// The server's slug for this rung (`met`, `regulars`, …), never a display
  /// string: the ladder is configured in the backend and localized here, in
  /// three languages, so the API has no business picking English.
  final String key;

  /// How many meetings the next rung needs, or null at the top.
  final int? nextAt;

  /// True only on the response that crossed a threshold, so the reveal can say
  /// so once and never again.
  final bool justLevelledUp;

  /// The one-time XP the crossing paid. Server truth; never computed here.
  final int bonusAwarded;

  /// The first time counts as meeting someone, not as levelling up.
  bool get isFirstMeeting => timesMet <= 1;
}

/// One person you have met, from the viewer's side.
///
/// The row is one-directional on purpose: the server writes both directions
/// when both sides are real profiles, and only one when the other side is still
/// a [isGhost] — someone who does not have the app yet.
class Encounter {
  const Encounter({
    required this.id,
    this.otherProfileId,
    this.otherName,
    this.otherAvatarUrl,
    this.ghostName,
    this.communityId,
    this.communityName,
    this.firstMetEventId,
    this.firstMetEventName,
    required this.firstMetAt,
    required this.lastMetAt,
    required this.timesMet,
    this.photoUrl,
    this.claimedAt,
    this.pendingPoints = 0,
  });

  factory Encounter.fromJson(Map<String, dynamic> json) => Encounter(
    id: json['id'] as String,
    otherProfileId: json['other_profile_id'] as String?,
    otherName: json['other_name'] as String?,
    otherAvatarUrl: json['other_avatar_url'] as String?,
    ghostName: json['ghost_name'] as String?,
    communityId: json['community_id'] as String?,
    communityName: json['community_name'] as String?,
    firstMetEventId: json['first_met_event_id'] as String?,
    firstMetEventName: json['first_met_event_name'] as String?,
    firstMetAt: DateTime.parse(json['first_met_at'] as String),
    lastMetAt: DateTime.parse(
      (json['last_met_at'] ?? json['first_met_at']) as String,
    ),
    timesMet: json['times_met'] as int? ?? 1,
    photoUrl: json['photo_url'] as String?,
    claimedAt: json['claimed_at'] != null
        ? DateTime.parse(json['claimed_at'] as String)
        : null,
    pendingPoints: json['pending_points'] as int? ?? 0,
  );

  final String id;

  /// Null while this is still a ghost — the person has not joined yet.
  final String? otherProfileId;
  final String? otherName;
  final String? otherAvatarUrl;

  /// The name the inviter typed for someone who is not on Kolabing.
  final String? ghostName;

  final String? communityId;
  final String? communityName;
  final String? firstMetEventId;
  final String? firstMetEventName;
  final DateTime firstMetAt;
  final DateTime lastMetAt;
  final int timesMet;

  /// The co-frame, when the challenge asked for one.
  final String? photoUrl;

  /// When a ghost became a real profile.
  final DateTime? claimedAt;

  /// XP waiting on a ghost to join. Named on screen precisely because it is
  /// *not* paid yet — that is the whole pull of the invite.
  final int pendingPoints;

  /// Nobody is on the other end of this yet.
  bool get isGhost => otherProfileId == null;

  /// What to call them, whichever side of the claim they are on.
  String get displayName => otherName ?? ghostName ?? '';

  /// First letter for the avatar fallback, never an empty string. Same shape as
  /// `Friendship.initial`, so an avatar reads the same wherever it is drawn.
  String get initial =>
      displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';

  Encounter copyWith({String? otherProfileId, DateTime? claimedAt}) =>
      Encounter(
        id: id,
        otherProfileId: otherProfileId ?? this.otherProfileId,
        otherName: otherName,
        otherAvatarUrl: otherAvatarUrl,
        ghostName: ghostName,
        communityId: communityId,
        communityName: communityName,
        firstMetEventId: firstMetEventId,
        firstMetEventName: firstMetEventName,
        firstMetAt: firstMetAt,
        lastMetAt: lastMetAt,
        timesMet: timesMet,
        photoUrl: photoUrl,
        claimedAt: claimedAt ?? this.claimedAt,
        pendingPoints: pendingPoints,
      );
}

/// What the ghost flow hands back so the inviter can actually send the invite.
///
/// Two ways in, one token. A Universal Link alone cannot do this job: tapping
/// `https://kolabing.com/i/<token>` on a phone **without** the app opens a web
/// page, and the token does not survive the trip through the App Store. So the
/// same token is also rendered as a short [claimCode] the new attendee types
/// during onboarding.
class GhostInvite {
  const GhostInvite({
    required this.encounter,
    required this.claimCode,
    required this.inviteUrl,
    required this.expiresAt,
  });

  factory GhostInvite.fromJson(Map<String, dynamic> json) => GhostInvite(
    encounter: Encounter.fromJson(json['encounter'] as Map<String, dynamic>),
    claimCode: json['claim_code'] as String,
    inviteUrl: json['invite_url'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );

  final Encounter encounter;

  /// Short, human-typeable. The path that survives an install.
  final String claimCode;

  /// The https link. Opens the app when it is installed, the landing page when
  /// it is not.
  final String inviteUrl;

  final DateTime expiresAt;
}

/// One night, summarised — what the recap sheet draws and what gets shared.
class NightRecap {
  const NightRecap({
    required this.eventId,
    this.eventName,
    this.communityName,
    required this.peopleMet,
    required this.newPeopleMet,
    required this.pointsEarned,
    required this.photoUrls,
  });

  factory NightRecap.fromJson(Map<String, dynamic> json) => NightRecap(
    eventId: json['event_id'] as String,
    eventName: json['event_name'] as String?,
    communityName: json['community_name'] as String?,
    peopleMet: json['people_met'] as int? ?? 0,
    newPeopleMet: json['new_people_met'] as int? ?? 0,
    pointsEarned: json['points_earned'] as int? ?? 0,
    photoUrls: ((json['photo_urls'] as List<dynamic>?) ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );

  final String eventId;
  final String? eventName;
  final String? communityName;
  final int peopleMet;
  final int newPeopleMet;
  final int pointsEarned;
  final List<String> photoUrls;

  /// A night where nothing happened is not worth a sheet.
  bool get isWorthShowing => peopleMet > 0 || photoUrls.isNotEmpty;
}
