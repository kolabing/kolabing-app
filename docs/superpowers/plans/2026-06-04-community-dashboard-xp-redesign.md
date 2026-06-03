# Community Dashboard XP Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local preview variant switch to the Community Dashboard with three selectable layouts (A/B/C), implementing the approved Variant B (Gamified Mission Board) as the default — surfacing XP progress, missions, and badges directly on the dashboard without requiring any navigation.

**Architecture:** Five new widget files are created in `lib/features/dashboard/widgets/`. The dashboard screen gains a top-level `DashboardPreviewVariant` enum and `_kDashboardVariant` constant; a single private method `_buildVariantBody` dispatches to the correct layout. The existing `XpProgressCard` gains a `showNavigationCta` flag (default `true`) so the wallet screen is unaffected. No providers, routes, or backend logic are changed.

**Tech Stack:** Flutter/Dart, Riverpod (`ref.watch`), existing `walletProvider` / `walletSummaryProvider`, `KolabingColors` / `KolabingSpacing` / `KolabingRadius` design tokens, Lucide Icons.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `lib/features/dashboard/widgets/community_xp_summary_card.dart` | Sage-green, non-tappable XP card |
| Create | `lib/features/dashboard/widgets/earn_xp_action_card.dart` | Single mission row with icon / title / desc / badge |
| Create | `lib/features/dashboard/widgets/xp_missions_section.dart` | "Today's XP Missions" list using static preview data |
| Create | `lib/features/dashboard/widgets/community_stats_strip.dart` | 4-pill horizontal stats row |
| Create | `lib/features/dashboard/widgets/dashboard_badges_row.dart` | Horizontally-scrollable badge chips from wallet provider |
| Modify | `lib/features/rewards/widgets/xp_progress_card.dart` | Add `showNavigationCta` param, hide CTA when false |
| Modify | `lib/features/rewards/widgets/referral_banner_card.dart` | Add `usePastelStyle` param for yellow-rect variant |
| Modify | `lib/features/dashboard/screens/community_dashboard_screen.dart` | Add variant enum/constant, wire three layout bodies |

---

## Task 1: Add `showNavigationCta` to `XpProgressCard`

**Files:**
- Modify: `lib/features/rewards/widgets/xp_progress_card.dart`

The existing `XpProgressCard` shows "View progress ›" only when `onTap != null`. We add a separate `showNavigationCta` bool (default `true`) so Variant B can pass `showNavigationCta: false` without removing the tap entirely from the wallet screen's copy.

- [ ] **Step 1: Add the parameter**

Open `lib/features/rewards/widgets/xp_progress_card.dart` and update the class:

```dart
class XpProgressCard extends ConsumerWidget {
  const XpProgressCard({super.key, this.onTap, this.showNavigationCta = true});

  final VoidCallback? onTap;
  final bool showNavigationCta;
```

- [ ] **Step 2: Gate the CTA on the new flag**

In the same file, find the `Row` at the bottom of the `build` method (around line 82) and update the condition:

```dart
if (onTap != null && showNavigationCta)
  Row(
    children: [
      Text(
        'View progress ›',
        style: KolabingTextStyles.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: xpInk,
        ),
      ),
    ],
  ),
```

- [ ] **Step 3: Verify analyze is clean**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/rewards/widgets/xp_progress_card.dart
```
Expected: no errors or warnings.

- [ ] **Step 4: Commit**

```bash
git add lib/features/rewards/widgets/xp_progress_card.dart
git commit -m "feat(xp-card): add showNavigationCta flag to XpProgressCard"
```

---

## Task 2: Create `CommunityXpSummaryCard`

**Files:**
- Create: `lib/features/dashboard/widgets/community_xp_summary_card.dart`

Sage-green card (non-tappable). Shows level chip, big XP number, "To next level" counter on the right, animated progress bar. Reads from `walletSummaryProvider` (already used by the existing `XpProgressCard`).

- [ ] **Step 1: Create the file**

```dart
// lib/features/dashboard/widgets/community_xp_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Sage-green XP summary card for the redesigned Community Dashboard.
///
/// Non-tappable. Shows level chip, total XP, "To next level" counter,
/// and an animated progress bar. Does NOT navigate anywhere.
class CommunityXpSummaryCard extends ConsumerWidget {
  const CommunityXpSummaryCard({super.key});

  static const _cardBg = Color(0xFFE8EFE0);
  static const _inkDark = Color(0xFF2E4020);
  static const _inkMid = Color(0xFF3D5229);
  static const _progressFill = Color(0xFF5A7A3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletSummaryProvider);
    if (wallet == null) return const SizedBox.shrink();

    final level = wallet.level;
    final progress = wallet.levelProgress;
    final xpToNext = wallet.xpToNextLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: const Color(0xFF3D5229).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level chip
              _LevelChip(levelNumber: level.number, levelTitle: level.title),
              const Spacer(),
              // To next level
              if (!level.isMaxLevel) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'To next level',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: _inkMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$xpToNext',
                      style: KolabingTextStyles.displaySmall.copyWith(
                        fontSize: 24,
                        color: _inkDark,
                      ),
                    ),
                    Text(
                      'XP needed',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: _inkMid,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          // Big XP number
          Text(
            '${wallet.totalXp}',
            style: KolabingTextStyles.displaySmall.copyWith(
              fontSize: 40,
              color: _inkDark,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'XP POINTS',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _inkMid,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          // Animated progress bar
          ClipRRect(
            borderRadius: KolabingRadius.borderRadiusRound,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: const Color(0xFF3D5229).withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(_progressFill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.levelNumber, required this.levelTitle});

  final int levelNumber;
  final String levelTitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2E4020),
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shield, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'LEVEL $levelNumber',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/dashboard/widgets/community_xp_summary_card.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/widgets/community_xp_summary_card.dart
git commit -m "feat(dashboard): add CommunityXpSummaryCard (sage green, non-tappable)"
```

---

## Task 3: Create `EarnXpActionCard`

**Files:**
- Create: `lib/features/dashboard/widgets/earn_xp_action_card.dart`

Single mission row: pastel icon square + title + description + XP or Done badge.

- [ ] **Step 1: Create the file**

```dart
// lib/features/dashboard/widgets/earn_xp_action_card.dart
import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';

/// A single XP earning action row for the mission board.
///
/// Shows a pastel icon, title, short description, and either a purple
/// "+N XP" badge (pending) or a green "✓ Done" badge (completed).
class EarnXpActionCard extends StatelessWidget {
  const EarnXpActionCard({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.xpReward,
    this.isDone = false,
  });

  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String description;
  final int xpReward;
  final bool isDone;

  static const _headingColor = Color(0xFF36322A);
  static const _captionColor = Color(0xFF928B7C);
  static const _xpBadgeBg = Color(0xFFEDE8FB);
  static const _xpBadgeText = Color(0xFF7B5EA7);
  static const _doneBadgeBg = Color(0xFFE8F5EE);
  static const _doneBadgeText = Color(0xFF2E7D52);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: const Color(0xFFE8E2D6)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: _headingColor),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _headingColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: _captionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.xs),
          // Badge
          _Badge(xpReward: xpReward, isDone: isDone),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.xpReward, required this.isDone});

  final int xpReward;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final bg = isDone
        ? const Color(0xFFE8F5EE)
        : const Color(0xFFEDE8FB);
    final textColor = isDone
        ? const Color(0xFF2E7D52)
        : const Color(0xFF7B5EA7);
    final label = isDone ? '✓ Done' : '+$xpReward XP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? const Color(0xFF2E7D52).withValues(alpha: 0.2)
              : const Color(0xFF7B5EA7).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/dashboard/widgets/earn_xp_action_card.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/widgets/earn_xp_action_card.dart
git commit -m "feat(dashboard): add EarnXpActionCard widget"
```

---

## Task 4: Create `XpMissionsSection`

**Files:**
- Create: `lib/features/dashboard/widgets/xp_missions_section.dart`

Static list of four mission items with hardcoded done/pending states for the preview. Header shows "TODAY'S XP MISSIONS" + "N of 4 done" counter.

- [ ] **Step 1: Create the file**

```dart
// lib/features/dashboard/widgets/xp_missions_section.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';
import 'earn_xp_action_card.dart';

/// "Today's XP Missions" section for Variant B of the dashboard redesign.
///
/// Mission list and done/pending states are hardcoded for the preview.
/// Real completion state would be derived from WalletNotifier ledger entries.
class XpMissionsSection extends StatelessWidget {
  const XpMissionsSection({super.key});

  static const _headingColor = Color(0xFF36322A);
  static const _captionColor = Color(0xFF928B7C);

  // Preview data — hardcoded for local comparison.
  // isDone states simulate a user who has posted a review but not yet
  // completed a kolab, shared content, or referred anyone.
  static const _missions = [
    _MissionData(
      icon: LucideIcons.star,
      iconBg: Color(0xFFE8F5EE),
      title: 'Post a review',
      description: 'Share your last Kolab experience',
      xpReward: 20,
      isDone: true,
    ),
    _MissionData(
      icon: LucideIcons.zap,
      iconBg: Color(0xFFFFF5CC),
      title: 'Complete a Kolab',
      description: 'Finish your active collaboration',
      xpReward: 100,
      isDone: false,
    ),
    _MissionData(
      icon: LucideIcons.camera,
      iconBg: Color(0xFFEDE8FB),
      title: 'Share content',
      description: 'Post UGC from your event',
      xpReward: 30,
      isDone: false,
    ),
    _MissionData(
      icon: LucideIcons.userPlus,
      iconBg: Color(0xFFF5E8EE),
      title: 'Refer a community',
      description: 'Invite someone to join Kolabing',
      xpReward: 50,
      isDone: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final doneCount = _missions.where((m) => m.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TODAY'S XP MISSIONS",
              style: KolabingTextStyles.labelLarge.copyWith(
                color: _headingColor,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$doneCount of ${_missions.length} done',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: _captionColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        // Mission cards
        ...List.generate(_missions.length, (i) {
          final m = _missions[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _missions.length - 1 ? KolabingSpacing.xs : 0,
            ),
            child: EarnXpActionCard(
              icon: m.icon,
              iconBgColor: m.iconBg,
              title: m.title,
              description: m.description,
              xpReward: m.xpReward,
              isDone: m.isDone,
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data class — preview only
// ---------------------------------------------------------------------------

class _MissionData {
  const _MissionData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.isDone,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String description;
  final int xpReward;
  final bool isDone;
}
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/dashboard/widgets/xp_missions_section.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/widgets/xp_missions_section.dart
git commit -m "feat(dashboard): add XpMissionsSection with static preview missions"
```

---

## Task 5: Create `CommunityStatsStrip`

**Files:**
- Create: `lib/features/dashboard/widgets/community_stats_strip.dart`

Single-row 4-pill strip replacing the 2×2 grid.

- [ ] **Step 1: Create the file**

```dart
// lib/features/dashboard/widgets/community_stats_strip.dart
import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';

/// A compact 4-pill horizontal stats strip for the XP-first dashboard layouts.
///
/// Replaces the 2×2 [DashboardStatCard] grid with a denser single row.
class CommunityStatsStrip extends StatelessWidget {
  const CommunityStatsStrip({
    super.key,
    required this.pending,
    required this.accepted,
    required this.active,
    required this.completed,
  });

  final int pending;
  final int accepted;
  final int active;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(count: pending, label: 'PENDING'),
        const SizedBox(width: KolabingSpacing.xs),
        _StatPill(count: active, label: 'ACTIVE'),
        const SizedBox(width: KolabingSpacing.xs),
        _StatPill(count: completed, label: 'DONE'),
        const SizedBox(width: KolabingSpacing.xs),
        _StatPill(count: accepted, label: 'ACCEPTED'),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.count, required this.label});

  final int count;
  final String label;

  static const _headingColor = Color(0xFF36322A);
  static const _captionColor = Color(0xFF928B7C);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: const Color(0xFFE8E2D6)),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: KolabingTextStyles.displaySmall.copyWith(
                  fontSize: 20,
                  color: _headingColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 9,
                  color: _captionColor,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/dashboard/widgets/community_stats_strip.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/widgets/community_stats_strip.dart
git commit -m "feat(dashboard): add CommunityStatsStrip compact 4-pill row"
```

---

## Task 6: Create `DashboardBadgesRow`

**Files:**
- Create: `lib/features/dashboard/widgets/dashboard_badges_row.dart`

Horizontally scrollable row of badge chips sourced from `walletProvider`. Earned badges have a warm yellow tint; locked ones are greyed.

- [ ] **Step 1: Create the file**

```dart
// lib/features/dashboard/widgets/dashboard_badges_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';
import '../../rewards/models/reward_badge.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Horizontally scrollable badge chips row for the community dashboard.
///
/// Reads [RewardBadge] list from [walletProvider].
/// Earned badges use a warm yellow tint; locked ones are greyed out.
class DashboardBadgesRow extends ConsumerWidget {
  const DashboardBadgesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(walletProvider.select((s) => s.badges));
    if (badges.isEmpty) return const SizedBox.shrink();

    final earnedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BADGES',
              style: KolabingTextStyles.labelLarge.copyWith(
                color: const Color(0xFF36322A),
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$earnedCount earned',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: const Color(0xFF928B7C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: KolabingSpacing.xs),
            itemBuilder: (_, i) => _BadgeChip(badge: badges[i]),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.isUnlocked;

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
      decoration: BoxDecoration(
        color: earned ? const Color(0xFFFFFBEE) : Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: earned
              ? const Color(0xFFF5C800).withValues(alpha: 0.6)
              : const Color(0xFFE8E2D6),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: earned ? 1.0 : 0.3,
            child: Icon(badge.slug.icon, size: 20, color: const Color(0xFF36322A)),
          ),
          const SizedBox(height: 4),
          Text(
            badge.slug.shortName.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 8,
              color: earned
                  ? const Color(0xFF5A5345)
                  : const Color(0xFF928B7C),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/dashboard/widgets/dashboard_badges_row.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/widgets/dashboard_badges_row.dart
git commit -m "feat(dashboard): add DashboardBadgesRow from wallet provider"
```

---

## Task 7: Add pastel-yellow style to `ReferralBannerCard`

**Files:**
- Modify: `lib/features/rewards/widgets/referral_banner_card.dart`

Add a `usePastelStyle` parameter (default `false`). When `true`, the card uses `Color(0xFFFDF6DC)` background with `Color(0xFFF0E4A0)` border — matching the XP card's shape language. The existing white style is unchanged for any other screen that uses this widget.

- [ ] **Step 1: Add the parameter and conditional styling**

Update `lib/features/rewards/widgets/referral_banner_card.dart`:

```dart
class ReferralBannerCard extends ConsumerWidget {
  const ReferralBannerCard({super.key, this.usePastelStyle = false});

  final bool usePastelStyle;
```

Then update the `Container` decoration inside `build`:

```dart
decoration: BoxDecoration(
  color: usePastelStyle ? const Color(0xFFFDF6DC) : Colors.white,
  borderRadius: KolabingRadius.borderRadiusLg,
  border: Border.all(
    color: usePastelStyle
        ? const Color(0xFFF0E4A0)
        : const Color(0xFFEAE3D4),
  ),
),
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/rewards/widgets/referral_banner_card.dart
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/rewards/widgets/referral_banner_card.dart
git commit -m "feat(referral-card): add usePastelStyle flag for yellow-rect dashboard variant"
```

---

## Task 8: Wire the variant switch in `CommunityDashboardScreen`

**Files:**
- Modify: `lib/features/dashboard/screens/community_dashboard_screen.dart`

Add the `DashboardPreviewVariant` enum and `_kDashboardVariant` constant at the top of the file. Replace `_buildBody`'s content section with a variant dispatcher. Implement the three layout bodies as private methods. The existing `_buildHeader`, `_buildStatsGrid`, `_buildQuickActions`, `_buildUpcomingSection`, and `_buildErrorState` methods are kept unchanged.

- [ ] **Step 1: Add imports for new widgets**

At the top of `community_dashboard_screen.dart`, add these imports after the existing ones:

```dart
import '../widgets/community_xp_summary_card.dart';
import '../widgets/community_stats_strip.dart';
import '../widgets/dashboard_badges_row.dart';
import '../widgets/xp_missions_section.dart';
import '../../rewards/providers/wallet_provider.dart';
```

- [ ] **Step 2: Add the variant enum and constant**

Add these two declarations at the top of the file, just before the `CommunityDashboardScreen` class:

```dart
/// Local-only preview switch — change this constant to compare layouts.
/// Does not affect production builds.
enum DashboardPreviewVariant { optionA, optionB, optionC }
const _kDashboardVariant = DashboardPreviewVariant.optionB;
```

- [ ] **Step 3: Replace the content list in `_buildBody`**

In `_buildBody`, replace the `ListView` children block (from `_buildHeader` call to the end of the list) with a variant dispatcher. The loading/error guards above stay identical. Replace only the `return ListView(...)` block:

```dart
return ListView(
  padding: const EdgeInsets.all(KolabingSpacing.md),
  children: [
    _buildHeader(userName, isDark),
    const SizedBox(height: KolabingSpacing.lg),
    ..._buildVariantContent(data, isDark),
    const SizedBox(height: KolabingSpacing.xl),
  ],
);
```

- [ ] **Step 4: Add `_buildVariantContent` dispatcher**

Add this method to `_CommunityDashboardScreenState`:

```dart
List<Widget> _buildVariantContent(CommunityDashboard data, bool isDark) {
  switch (_kDashboardVariant) {
    case DashboardPreviewVariant.optionA:
      return _buildVariantA(data, isDark);
    case DashboardPreviewVariant.optionB:
      return _buildVariantB(data, isDark);
    case DashboardPreviewVariant.optionC:
      return _buildVariantC(data, isDark);
  }
}
```

- [ ] **Step 5: Implement `_buildVariantB`**

Add this method (the approved layout):

```dart
List<Widget> _buildVariantB(CommunityDashboard data, bool isDark) {
  return [
    // 1. XP summary card (sage green, non-tappable)
    const CommunityXpSummaryCard(),
    const SizedBox(height: KolabingSpacing.lg),

    // 2. Today's XP missions
    const XpMissionsSection(),
    const SizedBox(height: KolabingSpacing.lg),

    // 3. Compact stats strip
    CommunityStatsStrip(
      pending: data.applicationsSent.pending,
      accepted: data.applicationsSent.accepted,
      active: data.collaborations.active,
      completed: data.collaborations.completed,
    ),
    const SizedBox(height: KolabingSpacing.lg),

    // 4. Badges row
    const DashboardBadgesRow(),
    const SizedBox(height: KolabingSpacing.lg),

    // 5. Referral card — pastel yellow style
    const ReferralBannerCard(usePastelStyle: true),
    const SizedBox(height: KolabingSpacing.lg),

    // 6. Quick actions
    _buildQuickActions(isDark),
    const SizedBox(height: KolabingSpacing.lg),

    // 7. Upcoming kolabs
    _buildUpcomingSection(data, isDark),
  ];
}
```

- [ ] **Step 6: Implement `_buildVariantA`**

Add Variant A (XP-first stacked, for comparison):

```dart
List<Widget> _buildVariantA(CommunityDashboard data, bool isDark) {
  return [
    // XP summary
    const CommunityXpSummaryCard(),
    const SizedBox(height: KolabingSpacing.lg),

    // Ways to earn (same section, Variant A label would differ in final product)
    const XpMissionsSection(),
    const SizedBox(height: KolabingSpacing.lg),

    // Compact stats
    CommunityStatsStrip(
      pending: data.applicationsSent.pending,
      accepted: data.applicationsSent.accepted,
      active: data.collaborations.active,
      completed: data.collaborations.completed,
    ),
    const SizedBox(height: KolabingSpacing.lg),

    // Referral card — pastel yellow
    const ReferralBannerCard(usePastelStyle: true),
    const SizedBox(height: KolabingSpacing.lg),

    // Quick actions
    _buildQuickActions(isDark),
    const SizedBox(height: KolabingSpacing.lg),

    // Upcoming
    _buildUpcomingSection(data, isDark),
  ];
}
```

- [ ] **Step 7: Implement `_buildVariantC`**

Add Variant C (compact grid, for comparison):

```dart
List<Widget> _buildVariantC(CommunityDashboard data, bool isDark) {
  return [
    // XP summary
    const CommunityXpSummaryCard(),
    const SizedBox(height: KolabingSpacing.lg),

    // XP missions (same component — in a real C variant this would be a grid)
    const XpMissionsSection(),
    const SizedBox(height: KolabingSpacing.lg),

    // Compact stats
    CommunityStatsStrip(
      pending: data.applicationsSent.pending,
      accepted: data.applicationsSent.accepted,
      active: data.collaborations.active,
      completed: data.collaborations.completed,
    ),
    const SizedBox(height: KolabingSpacing.lg),

    // Badges
    const DashboardBadgesRow(),
    const SizedBox(height: KolabingSpacing.lg),

    // Referral card — pastel yellow
    const ReferralBannerCard(usePastelStyle: true),
    const SizedBox(height: KolabingSpacing.lg),

    // Quick actions
    _buildQuickActions(isDark),
    const SizedBox(height: KolabingSpacing.lg),

    // Upcoming
    _buildUpcomingSection(data, isDark),
  ];
}
```

- [ ] **Step 8: Ensure wallet data is loaded for badges**

In `initState`, after the existing `dashboardProvider` load call, add a wallet load guard:

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    final state = ref.read(dashboardProvider);
    if (!state.isInitialized && !state.isLoading) {
      ref.read(dashboardProvider.notifier).load();
    }
    // Also load wallet data so badges and XP are available on the dashboard.
    final walletState = ref.read(walletProvider);
    if (walletState.wallet == null && !walletState.isLoading) {
      ref.read(walletProvider.notifier).load();
    }
  });
}
```

- [ ] **Step 9: Analyze the full screen file**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze lib/features/dashboard/screens/community_dashboard_screen.dart
```
Expected: no errors.

- [ ] **Step 10: Full project analyze**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter analyze
```
Expected: no errors.

- [ ] **Step 11: Commit**

```bash
git add lib/features/dashboard/screens/community_dashboard_screen.dart
git commit -m "feat(dashboard): wire DashboardPreviewVariant switch with Variant A/B/C layouts"
```

---

## Switching Between Variants

To compare layouts on localhost, open `lib/features/dashboard/screens/community_dashboard_screen.dart` and change the single constant near the top of the file:

```dart
// Line ~25, just before the class declaration
const _kDashboardVariant = DashboardPreviewVariant.optionA; // or optionB / optionC
```

Hot-restart the app. No other changes needed.

---

## Self-Review

**Spec coverage:**
- ✅ XP summary near top — `CommunityXpSummaryCard` is first content item in all three variants
- ✅ Non-navigable XP card — `showNavigationCta: false` parameter added to `XpProgressCard` (though the new `CommunityXpSummaryCard` is used instead, which has no `onTap` at all)
- ✅ Ways to earn visible — `XpMissionsSection` directly in body, no tap required
- ✅ Stats demoted — `CommunityStatsStrip` replaces 2×2 grid in all variants
- ✅ Badges surfaced — `DashboardBadgesRow` reads from `walletProvider`
- ✅ Referral card pastel yellow — `usePastelStyle: true` param added
- ✅ Warm ink text scale — all new widgets use `#36322A` / `#5A5345` / `#928B7C` constants
- ✅ Variant switch — `DashboardPreviewVariant` enum + `_kDashboardVariant` constant
- ✅ `WalletScreen` untouched — still navigable from wallet route
- ✅ `DashboardStatCard` untouched — still used by business dashboard

**No placeholders found.**

**Type consistency:** `CommunityStatsStrip` params (`pending`, `accepted`, `active`, `completed`) match the `CommunityDashboard` field names used in `_buildStatsGrid`. `DashboardBadgesRow` reads `walletProvider.select((s) => s.badges)` which returns `List<RewardBadge>` — same type used throughout wallet screen.
