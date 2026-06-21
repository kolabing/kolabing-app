/// Models for the Personal Rewards Screen, fed by `GET /me/rewards-overview`.
///
/// Contract: docs/tickets/2026-06-12-community-gamification-rewards-contract.md
/// (P3). Envelope: `{ xp, partner_rewards:[…], communities:[{community,
/// my_points, rewards:[…]}] }`.
///
/// Every field is parsed tolerantly so a partially-deployed backend (P1 ships in
/// parallel) never crashes the app. The per-community `rewards` reuse P2's
/// [CommunityReward] model (cost_points + affordable), so the redeem flow + tile
/// rendering stay consistent across the community Rewards tab and this screen.
library;

import '../../community/models/community_rewards.dart';

/// A global Kolabing partner reward, redeemable with XP. Read-only for now
/// ("Redeem your XP — coming soon"); [costXp] drives the muted/locked display.
class PartnerReward {
  const PartnerReward({
    required this.id,
    required this.title,
    this.description,
    this.partner,
    required this.costXp,
    this.isActive = true,
  });

  factory PartnerReward.fromJson(Map<String, dynamic> json) => PartnerReward(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        partner: json['partner'] as String?,
        costXp: (json['cost_xp'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  final String id;
  final String title;
  final String? description;

  /// Partner / brand name behind the reward (e.g. a sponsor).
  final String? partner;

  /// XP cost to redeem. Display only for now (redemption is "coming soon").
  final int costXp;
  final bool isActive;
}

/// One community block on the personal overview: which community, the viewer's
/// per-community [myPoints] balance, and that community's redeemable [rewards].
class CommunityRewardsSection {
  const CommunityRewardsSection({
    required this.communityId,
    required this.communityName,
    this.communityLogoUrl,
    required this.myPoints,
    this.rewards = const [],
  });

  factory CommunityRewardsSection.fromJson(Map<String, dynamic> json) {
    // `community` may be a nested object or the section may carry flat fields.
    final community = json['community'];
    final communityMap =
        community is Map<String, dynamic> ? community : const <String, dynamic>{};
    final id = (communityMap['id'] ?? json['community_id'] ?? '').toString();
    final name = (communityMap['name'] ??
            json['community_name'] ??
            json['name'] ??
            '') as String;
    final logo = (communityMap['avatar_url'] ??
            communityMap['logo_url'] ??
            json['community_logo_url']) as String?;

    return CommunityRewardsSection(
      communityId: id,
      communityName: name,
      communityLogoUrl: logo,
      myPoints: (json['my_points'] as num?)?.toInt() ?? 0,
      rewards: (json['rewards'] as List<dynamic>?)
              ?.map((e) => CommunityReward.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  final String communityId;
  final String communityName;
  final String? communityLogoUrl;
  final int myPoints;
  final List<CommunityReward> rewards;
}

/// `GET /me/rewards-overview` envelope: global [xp], global [partnerRewards]
/// (coming soon), and per-community [communities] sections.
class MeRewardsOverview {
  const MeRewardsOverview({
    required this.xp,
    this.partnerRewards = const [],
    this.communities = const [],
  });

  factory MeRewardsOverview.fromJson(Map<String, dynamic> json) =>
      MeRewardsOverview(
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        partnerRewards: (json['partner_rewards'] as List<dynamic>?)
                ?.map((e) => PartnerReward.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        communities: (json['communities'] as List<dynamic>?)
                ?.map((e) =>
                    CommunityRewardsSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  /// Empty overview used when the endpoint isn't deployed yet (self-gated).
  static const empty = MeRewardsOverview(xp: 0);

  final int xp;
  final List<PartnerReward> partnerRewards;
  final List<CommunityRewardsSection> communities;

  bool get hasCommunities => communities.isNotEmpty;
}
