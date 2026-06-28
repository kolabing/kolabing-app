import '../../../l10n/app_localizations.dart';

/// Maps a backend mission `category` string to a [CategoryIcon] `name` keyword
/// that resolves to one of the bundled personalised category SVGs
/// (`assets/icons/categories/`), and to a localized header label.
///
/// Categories are: onboarding / attendance / engagement / content / referral /
/// growth / social / milestone. Unknown categories fall back to a generic
/// keyword (→ `category-default.svg`) and the localized "Other" header.
///
/// We pass the keyword as `CategoryIcon(name: ...)` so resolution flows through
/// the existing `categoryIconAsset` keyword map (docs/ICONS-AND-IMAGES.md §1) —
/// no Lucide picker, no hardcoded icon list.
class MissionCategory {
  const MissionCategory._();

  /// The bundled-SVG keyword for a category. The returned string is fed to
  /// `CategoryIcon(name:)`, which keyword-matches it to an asset.
  ///
  /// - onboarding → `education`   (learning the ropes)
  /// - attendance → `social`      (showing up to events)
  /// - engagement → `gaming`      (active participation)
  /// - content    → `art`         (creating things)
  /// - referral   → `social`      (bringing people in)
  /// - growth     → `outdoor`     (expanding / leveling up)
  /// - social     → `social`
  /// - milestone  → `sports`      (achievement / trophy-like)
  static String iconKeyword(String category) {
    switch (category.trim().toLowerCase()) {
      case 'onboarding':
        return 'education';
      case 'attendance':
        return 'social';
      case 'engagement':
        return 'gaming';
      case 'content':
        return 'art';
      case 'referral':
        return 'social';
      case 'growth':
        return 'outdoor';
      case 'social':
        return 'social';
      case 'milestone':
        return 'sports';
      default:
        return 'default';
    }
  }

  /// Localized header label for a category.
  static String label(AppLocalizations l10n, String category) {
    switch (category.trim().toLowerCase()) {
      case 'onboarding':
        return l10n.missionsCategoryOnboarding;
      case 'attendance':
        return l10n.missionsCategoryAttendance;
      case 'engagement':
        return l10n.missionsCategoryEngagement;
      case 'content':
        return l10n.missionsCategoryContent;
      case 'referral':
        return l10n.missionsCategoryReferral;
      case 'growth':
        return l10n.missionsCategoryGrowth;
      case 'social':
        return l10n.missionsCategorySocial;
      case 'milestone':
        return l10n.missionsCategoryMilestone;
      default:
        return l10n.missionsCategoryOther;
    }
  }

  /// Stable display order for category groups. Lower sorts first; unknown
  /// categories sort last (alphabetically among themselves).
  static int order(String category) {
    const ordered = <String>[
      'onboarding',
      'attendance',
      'engagement',
      'content',
      'social',
      'referral',
      'growth',
      'milestone',
    ];
    final index = ordered.indexOf(category.trim().toLowerCase());
    return index == -1 ? ordered.length : index;
  }
}
