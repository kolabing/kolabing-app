/// Models for the community gamification "Rewards" tab: goals, rewards, badges,
/// and the member-facing rewards-hub envelope.
///
/// Contract: docs/tickets/2026-06-12-community-gamification-rewards-contract.md.
/// All wire enum values (`earn_type`, `criteria_type`) are the backend strings —
/// never rename without a backend change. Every field is parsed tolerantly so a
/// partially-deployed backend (P1 ships in parallel) never crashes the app.

// -----------------------------------------------------------------------------
// Goal
// -----------------------------------------------------------------------------

/// How a [CommunityGoal] is progressed/earned.
enum GoalEarnType {
  eventCheckIns,
  challenge,
  daysInCommunity;

  static GoalEarnType fromString(String? value) {
    switch (value) {
      case 'event_check_ins':
        return GoalEarnType.eventCheckIns;
      case 'challenge':
        return GoalEarnType.challenge;
      case 'days_in_community':
        return GoalEarnType.daysInCommunity;
      default:
        return GoalEarnType.eventCheckIns;
    }
  }

  String toApiValue() {
    switch (this) {
      case GoalEarnType.eventCheckIns:
        return 'event_check_ins';
      case GoalEarnType.challenge:
        return 'challenge';
      case GoalEarnType.daysInCommunity:
        return 'days_in_community';
    }
  }
}

/// A community goal: earn [rewardPoints] by reaching [target] of [earnType].
/// Member payloads also carry [progress] (0..target) when the rewards-hub
/// resolves the viewer's standing.
class CommunityGoal {
  const CommunityGoal({
    required this.id,
    required this.title,
    required this.earnType,
    required this.target,
    required this.rewardPoints,
    this.challengeId,
    this.isActive = true,
    this.progress,
  });

  factory CommunityGoal.fromJson(Map<String, dynamic> json) => CommunityGoal(
    id: json['id'].toString(),
    title: json['title'] as String? ?? '',
    earnType: GoalEarnType.fromString(json['earn_type'] as String?),
    target: (json['target'] as num?)?.toInt() ?? 0,
    rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
    challengeId: json['challenge_id']?.toString(),
    isActive: json['is_active'] as bool? ?? true,
    progress: (json['progress'] as num?)?.toInt(),
  );

  final String id;
  final String title;
  final GoalEarnType earnType;
  final int target;
  final int rewardPoints;
  final String? challengeId;
  final bool isActive;

  /// Viewer's current progress toward [target] (member view only); null on the
  /// leader CRUD payload.
  final int? progress;

  /// 0..1 completion ratio, clamped. 0 when target is unset.
  double get progressRatio {
    if (target <= 0) return 0;
    return ((progress ?? 0) / target).clamp(0, 1).toDouble();
  }

  bool get isCompleted => (progress ?? 0) >= target && target > 0;

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'earn_type': earnType.toApiValue(),
    'target': target,
    'reward_points': rewardPoints,
    if (earnType == GoalEarnType.challenge && challengeId != null)
      'challenge_id': challengeId,
  };
}

// -----------------------------------------------------------------------------
// Reward
// -----------------------------------------------------------------------------

/// A redeemable community reward costing [costPoints]. [stock] null = unlimited.
class CommunityReward {
  const CommunityReward({
    required this.id,
    required this.title,
    this.description,
    required this.costPoints,
    this.stock,
    this.isActive = true,
    this.affordable,
  });

  factory CommunityReward.fromJson(Map<String, dynamic> json) =>
      CommunityReward(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        costPoints: (json['cost_points'] as num?)?.toInt() ?? 0,
        stock: (json['stock'] as num?)?.toInt(),
        isActive: json['is_active'] as bool? ?? true,
        affordable: json['affordable'] as bool?,
      );

  final String id;
  final String title;
  final String? description;
  final int costPoints;

  /// Remaining stock; null = unlimited.
  final int? stock;
  final bool isActive;

  /// Whether the viewer can afford it (member view); null on leader payloads.
  final bool? affordable;

  bool get isOutOfStock => stock != null && stock! <= 0;

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    if (description != null) 'description': description,
    'cost_points': costPoints,
    if (stock != null) 'stock': stock,
  };
}

// -----------------------------------------------------------------------------
// Badge
// -----------------------------------------------------------------------------

/// What a member must do to earn a [CommunityBadge].
enum BadgeCriteriaType {
  pointsThreshold,
  eventCheckIns,
  daysInCommunity,
  challengesCompleted;

  static BadgeCriteriaType fromString(String? value) {
    switch (value) {
      case 'points_threshold':
        return BadgeCriteriaType.pointsThreshold;
      case 'event_check_ins':
        return BadgeCriteriaType.eventCheckIns;
      case 'days_in_community':
        return BadgeCriteriaType.daysInCommunity;
      case 'challenges_completed':
        return BadgeCriteriaType.challengesCompleted;
      default:
        return BadgeCriteriaType.pointsThreshold;
    }
  }

  String toApiValue() {
    switch (this) {
      case BadgeCriteriaType.pointsThreshold:
        return 'points_threshold';
      case BadgeCriteriaType.eventCheckIns:
        return 'event_check_ins';
      case BadgeCriteriaType.daysInCommunity:
        return 'days_in_community';
      case BadgeCriteriaType.challengesCompleted:
        return 'challenges_completed';
    }
  }
}

/// A community badge. [earned] is set on member payloads (locked vs unlocked).
class CommunityBadge {
  const CommunityBadge({
    required this.id,
    required this.title,
    this.icon,
    required this.criteriaType,
    required this.criteriaValue,
    this.challengeIds = const [],
    this.isActive = true,
    this.earned,
  });

  factory CommunityBadge.fromJson(Map<String, dynamic> json) => CommunityBadge(
    id: json['id'].toString(),
    title: json['title'] as String? ?? '',
    icon: json['icon'] as String?,
    criteriaType: BadgeCriteriaType.fromString(
      json['criteria_type'] as String?,
    ),
    criteriaValue: (json['criteria_value'] as num?)?.toInt() ?? 0,
    challengeIds:
        (json['challenge_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    isActive: json['is_active'] as bool? ?? true,
    earned: json['earned'] as bool?,
  );

  final String id;
  final String title;
  final String? icon;
  final BadgeCriteriaType criteriaType;
  final int criteriaValue;
  final List<String> challengeIds;
  final bool isActive;

  /// Whether the viewer has earned it (member view); null on leader payloads.
  final bool? earned;

  bool get isEarned => earned ?? false;

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    if (icon != null) 'icon': icon,
    'criteria_type': criteriaType.toApiValue(),
    'criteria_value': criteriaValue,
    if (criteriaType == BadgeCriteriaType.challengesCompleted)
      'challenge_ids': challengeIds,
  };
}

// -----------------------------------------------------------------------------
// Rewards hub (member envelope)
// -----------------------------------------------------------------------------

/// Member-facing `GET /communities/{id}/rewards-hub` envelope:
/// `{ my_points, my_tier, goals, badges, rewards }`.
class CommunityRewardsHub {
  const CommunityRewardsHub({
    required this.myPoints,
    this.myTierName,
    this.goals = const [],
    this.badges = const [],
    this.rewards = const [],
  });

  factory CommunityRewardsHub.fromJson(Map<String, dynamic> json) {
    final tier = json['my_tier'];
    final tierName = tier is Map<String, dynamic>
        ? tier['name'] as String?
        : tier as String?;
    return CommunityRewardsHub(
      myPoints: (json['my_points'] as num?)?.toInt() ?? 0,
      myTierName: tierName,
      goals:
          (json['goals'] as List<dynamic>?)
              ?.map((e) => CommunityGoal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => CommunityBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rewards:
          (json['rewards'] as List<dynamic>?)
              ?.map((e) => CommunityReward.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Empty hub used when the endpoint isn't deployed yet (self-gated).
  static const empty = CommunityRewardsHub(myPoints: 0);

  final int myPoints;
  final String? myTierName;
  final List<CommunityGoal> goals;
  final List<CommunityBadge> badges;
  final List<CommunityReward> rewards;
}
