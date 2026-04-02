import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

// =============================================================================
// Reward Badge Slug
// =============================================================================

/// Badge types available in the rewards system.
enum RewardBadgeSlug {
  firstKolab,
  contentCreator,
  communityEarner,
  referralPioneer,
  powerPartner;

  /// Full display name for the badge.
  String get displayName {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'First Kolab';
      case RewardBadgeSlug.contentCreator:
        return 'Content Creator';
      case RewardBadgeSlug.communityEarner:
        return 'Community Earner';
      case RewardBadgeSlug.referralPioneer:
        return 'Referral Pioneer';
      case RewardBadgeSlug.powerPartner:
        return 'Power Partner';
    }
  }

  /// Short name with line break for compact card display.
  String get shortName {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'First\nKolab';
      case RewardBadgeSlug.contentCreator:
        return 'Content\nCreator';
      case RewardBadgeSlug.communityEarner:
        return 'Community\nEarner';
      case RewardBadgeSlug.referralPioneer:
        return 'Referral\nPioneer';
      case RewardBadgeSlug.powerPartner:
        return 'Power\nPartner';
    }
  }

  /// Longer description of what the badge represents.
  String get description {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return 'Complete your first collaboration';
      case RewardBadgeSlug.contentCreator:
        return 'Post 3 reviews for collaborations';
      case RewardBadgeSlug.communityEarner:
        return 'Earn 100 points through activities';
      case RewardBadgeSlug.referralPioneer:
        return 'Refer your first user to Kolabing';
      case RewardBadgeSlug.powerPartner:
        return 'Complete 5 collaborations';
    }
  }

  /// Short requirement text shown on the badge card.
  String get requirement {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return '1 collab needed';
      case RewardBadgeSlug.contentCreator:
        return '3 reviews needed';
      case RewardBadgeSlug.communityEarner:
        return '100 pts needed';
      case RewardBadgeSlug.referralPioneer:
        return '1 referral needed';
      case RewardBadgeSlug.powerPartner:
        return '5 collabs needed';
    }
  }

  /// Icon representing this badge.
  IconData get icon {
    switch (this) {
      case RewardBadgeSlug.firstKolab:
        return LucideIcons.heartHandshake;
      case RewardBadgeSlug.contentCreator:
        return LucideIcons.camera;
      case RewardBadgeSlug.communityEarner:
        return LucideIcons.coins;
      case RewardBadgeSlug.referralPioneer:
        return LucideIcons.userPlus;
      case RewardBadgeSlug.powerPartner:
        return LucideIcons.zap;
    }
  }

  /// Snake-case value for API serialization.
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

  /// Parse an API string back to the enum value.
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

/// A badge in the rewards system, possibly unlocked by the user.
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

  /// Which badge this is.
  final RewardBadgeSlug slug;

  /// Whether the user has unlocked this badge.
  final bool isUnlocked;

  /// When the badge was earned, if unlocked.
  final DateTime? earnedAt;

  /// Formatted date string for display (e.g. "Mar 15, 2026").
  String get earnedDateFormatted {
    if (earnedAt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[earnedAt!.month - 1]} ${earnedAt!.day}, ${earnedAt!.year}';
  }

  @override
  String toString() =>
      'RewardBadge(slug: ${slug.toApiValue()}, unlocked: $isUnlocked)';

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static DateTime? _parseDateTimeNullable(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
