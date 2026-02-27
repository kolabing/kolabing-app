import 'badge.dart';

/// Gamification stats for a user
class GamificationStats {
  const GamificationStats({
    required this.totalPoints,
    required this.totalChallengesCompleted,
    required this.totalEventsAttended,
    this.globalRank,
    required this.badgesCount,
    required this.rewardsCount,
    this.totalBadgesEarned = 0,
    this.totalRewardsWon = 0,
    this.totalRewardsRedeemed = 0,
    this.totalEventsDiscovered = 0,
    this.totalSpins = 0,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      totalPoints: json['total_points'] as int,
      totalChallengesCompleted: json['total_challenges_completed'] as int,
      totalEventsAttended: json['total_events_attended'] as int,
      globalRank: json['global_rank'] as int?,
      badgesCount: json['badges_count'] as int,
      rewardsCount: json['rewards_count'] as int,
      totalBadgesEarned: json['total_badges_earned'] as int? ?? json['badges_count'] as int? ?? 0,
      totalRewardsWon: json['total_rewards_won'] as int? ?? 0,
      totalRewardsRedeemed: json['total_rewards_redeemed'] as int? ?? 0,
      totalEventsDiscovered: json['total_events_discovered'] as int? ?? 0,
      totalSpins: json['total_spins'] as int? ?? 0,
    );
  }

  final int totalPoints;
  final int totalChallengesCompleted;
  final int totalEventsAttended;
  final int? globalRank;
  final int badgesCount;
  final int rewardsCount;
  final int totalBadgesEarned;
  final int totalRewardsWon;
  final int totalRewardsRedeemed;
  final int totalEventsDiscovered;
  final int totalSpins;

  /// Check if user has a global rank
  bool get hasGlobalRank => globalRank != null;

  /// Get formatted rank string
  String get rankDisplay => globalRank != null ? '#$globalRank' : '--';

  Map<String, dynamic> toJson() => {
        'total_points': totalPoints,
        'total_challenges_completed': totalChallengesCompleted,
        'total_events_attended': totalEventsAttended,
        if (globalRank != null) 'global_rank': globalRank,
        'badges_count': badgesCount,
        'rewards_count': rewardsCount,
        'total_badges_earned': totalBadgesEarned,
        'total_rewards_won': totalRewardsWon,
        'total_rewards_redeemed': totalRewardsRedeemed,
        'total_events_discovered': totalEventsDiscovered,
        'total_spins': totalSpins,
      };
}

/// Profile data for game card
class GameCardProfile {
  const GameCardProfile({
    required this.id,
    required this.email,
    this.avatarUrl,
    required this.userType,
  });

  factory GameCardProfile.fromJson(Map<String, dynamic> json) {
    return GameCardProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      userType: json['user_type'] as String,
    );
  }

  final String id;
  final String email;
  final String? avatarUrl;
  final String userType;

  /// Get display name (email without domain)
  String get displayName {
    final atIndex = email.indexOf('@');
    return atIndex > 0 ? email.substring(0, atIndex) : email;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'user_type': userType,
      };
}

/// Public game card for a user
class GameCard {
  const GameCard({
    required this.profile,
    required this.stats,
    required this.recentBadges,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      profile:
          GameCardProfile.fromJson(json['profile'] as Map<String, dynamic>),
      stats: GamificationStats.fromJson(json['stats'] as Map<String, dynamic>),
      recentBadges: (json['recent_badges'] as List<dynamic>)
          .map((e) => BadgeAward.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final GameCardProfile profile;
  final GamificationStats stats;
  final List<BadgeAward> recentBadges;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'stats': stats.toJson(),
        'recent_badges': recentBadges.map((e) => e.toJson()).toList(),
      };
}
