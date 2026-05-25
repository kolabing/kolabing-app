import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

// =============================================================================
// Reward Badge Slug
// =============================================================================

/// Badge types available in the XP system.
///
/// IMPORTANT: [toApiValue] slug strings are hardcoded in the PHP backend enum
/// (GamificationBadgeSlug). Never rename them here without a backend change.
enum RewardBadgeSlug {
  firstKolab,
  contentCreator,
  communityEarner,
  referralPioneer,
  powerPartner;

  String get displayName {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'First Kolab';
      case RewardBadgeSlug.contentCreator:
        return 'Storyteller';
      case RewardBadgeSlug.communityEarner:
        return 'Community Builder';
      case RewardBadgeSlug.referralPioneer:
        return 'Plugged In';
      case RewardBadgeSlug.powerPartner:
        return 'Momentum Club';
    }
  }

  String get shortName {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'First\nKolab';
      case RewardBadgeSlug.contentCreator:
        return 'Story-\nteller';
      case RewardBadgeSlug.communityEarner:
        return 'Community\nBuilder';
      case RewardBadgeSlug.referralPioneer:
        return 'Plugged\nIn';
      case RewardBadgeSlug.powerPartner:
        return 'Momentum\nClub';
    }
  }

  String get description {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'Complete your first collaboration';
      case RewardBadgeSlug.contentCreator:
        return 'Post 3 reviews or content pieces';
      case RewardBadgeSlug.communityEarner:
        return 'Earn 250 XP through community activity';
      case RewardBadgeSlug.referralPioneer:
        return 'Refer your first business to Kolabing';
      case RewardBadgeSlug.powerPartner:
        return 'Complete 10 collaborations';
    }
  }

  String get requirement {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return '1 collab needed';
      case RewardBadgeSlug.contentCreator:
        return '3 reviews needed';
      case RewardBadgeSlug.communityEarner:
        return '250 XP needed';
      case RewardBadgeSlug.referralPioneer:
        return '1 referral needed';
      case RewardBadgeSlug.powerPartner:
        return '10 collabs needed';
    }
  }

  IconData get icon {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return LucideIcons.heartHandshake;
      case RewardBadgeSlug.contentCreator:
        return LucideIcons.pencil;
      case RewardBadgeSlug.communityEarner:
        return LucideIcons.users;
      case RewardBadgeSlug.referralPioneer:
        return LucideIcons.userPlus;
      case RewardBadgeSlug.powerPartner:
        return LucideIcons.zap;
    }
  }

  String toApiValue() {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'first_kolab';
      case RewardBadgeSlug.contentCreator:
        return 'content_creator';
      case RewardBadgeSlug.communityEarner:
        return 'community_earner';
      case RewardBadgeSlug.referralPioneer:
        return 'referral_pioneer';
      case RewardBadgeSlug.powerPartner:
        return 'power_partner';
    }
  }

  static RewardBadgeSlug fromString(String value) {
    switch (value) {
      case 'first_kolab':
        return RewardBadgeSlug.firstKolab;
      case 'content_creator':
        return RewardBadgeSlug.contentCreator;
      case 'community_earner':
        return RewardBadgeSlug.communityEarner;
      case 'referral_pioneer':
        return RewardBadgeSlug.referralPioneer;
      case 'power_partner':
        return RewardBadgeSlug.powerPartner;
      default:
        return RewardBadgeSlug.firstKolab;
    }
  }
}

// =============================================================================
// Reward Badge
// =============================================================================

@immutable
class RewardBadge {
  const RewardBadge({
    required this.slug,
    required this.isUnlocked,
    this.earnedAt,
  });

  factory RewardBadge.fromJson(Map<String, dynamic> json) => RewardBadge(
        slug: RewardBadgeSlug.fromString(
            json['slug']?.toString() ?? 'first_kolab'),
        isUnlocked: json['is_unlocked'] == true,
        earnedAt: _parseDateTimeNullable(json['earned_at']),
      );

  final RewardBadgeSlug slug;
  final bool isUnlocked;
  final DateTime? earnedAt;

  String get earnedDateFormatted {
    if (earnedAt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[earnedAt!.month - 1]} ${earnedAt!.day}, ${earnedAt!.year}';
  }

  @override
  String toString() =>
      'RewardBadge(slug: ${slug.toApiValue()}, unlocked: $isUnlocked)';

  static DateTime? _parseDateTimeNullable(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
