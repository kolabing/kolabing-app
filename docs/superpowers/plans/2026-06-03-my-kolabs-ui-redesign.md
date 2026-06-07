# My Kolabs UI Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the visual design of all My Kolabs sections (Offers, Requests, Active, Finished) into one coherent card system with shared sub-tab style, pastel chips, and a horizontal card layout with a square collab image on the right.

**Architecture:** Three new shared widgets (`KolabStatusBadge`, `KolabChip`, `MyKolabsSubTabs`) are created first. Then each of the four card types is restyled in place — same files, same props, same data logic — to use the shared widgets and the new horizontal layout. No routes, providers, or Supabase logic changes.

**Tech Stack:** Flutter · Dart · Riverpod (untouched) · `KolabingColors` / `KolabingTextStyles` / `KolabingRadius` / `KolabingSpacing` design tokens · `lucide_icons`

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/widgets/kolab_status_badge.dart` | Shared status pill — all sections |
| Create | `lib/widgets/kolab_chip.dart` | Shared pastel tag chip — all sections |
| Create | `lib/features/kolab/widgets/my_kolabs_sub_tabs.dart` | Shared underline sub-tab row |
| Modify | `lib/features/kolab/widgets/my_kolab_card.dart` | Restyle: horizontal layout, square image, shared chips |
| Modify | `lib/features/community/widgets/my_opportunity_card.dart` | Restyle: same layout, `offerPhoto` image |
| Modify | `lib/features/business/screens/my_kollabs_screen.dart` | Replace pill tabs with `MyKolabsSubTabs` |
| Modify | `lib/features/community/screens/my_opportunities_screen.dart` | Replace pill tabs with `MyKolabsSubTabs` |
| Modify | `lib/features/application/screens/applications_screen.dart` | Replace circular avatar with square image, use shared sub-tabs and badge |
| Modify | `lib/features/collaboration/widgets/collaborations_list_tab.dart` | Add square image, use shared badge |

---

## Task 1: Create `KolabStatusBadge`

**Files:**
- Create: `lib/widgets/kolab_status_badge.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/widgets/kolab_status_badge.dart
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

/// Shared pastel pill badge for status labels across all My Kolabs sections.
class KolabStatusBadge extends StatelessWidget {
  const KolabStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Text(
        label,
        style: KolabingTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static (Color, Color, String) _resolve(String status) =>
      switch (status.toLowerCase()) {
        'published' => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'PUBLISHED',
        ),
        'draft' => (
          KolabingColors.completedBg,
          KolabingColors.completedText,
          'DRAFT',
        ),
        'closed' => (
          KolabingColors.completedBg,
          KolabingColors.completedText,
          'CLOSED',
        ),
        'completed' => (
          KolabingColors.completedBg,
          KolabingColors.completedText,
          'COMPLETED',
        ),
        'scheduled' => (
          KolabingColors.secondaryContainer,
          KolabingColors.secondary,
          'SCHEDULED',
        ),
        'in_progress' || 'active' => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'IN PROGRESS',
        ),
        'pending_confirmation' => (
          KolabingColors.pendingBg,
          KolabingColors.pendingText,
          'WAITING CONFIRM',
        ),
        'pending' => (
          KolabingColors.pendingBg,
          KolabingColors.pendingText,
          'PENDING',
        ),
        'accepted' => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'ACCEPTED',
        ),
        'declined' => (
          KolabingColors.errorBg,
          KolabingColors.errorText,
          'DECLINED',
        ),
        'withdrawn' => (
          KolabingColors.surfaceVariant,
          KolabingColors.textTertiary,
          'WITHDRAWN',
        ),
        'cancelled' => (
          KolabingColors.errorBg,
          KolabingColors.errorText,
          'CANCELLED',
        ),
        _ => (
          KolabingColors.surfaceVariant,
          KolabingColors.textTertiary,
          status.toUpperCase(),
        ),
      };
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/widgets/kolab_status_badge.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/kolab_status_badge.dart
git commit -m "feat(ui): add KolabStatusBadge shared widget"
```

---

## Task 2: Create `KolabChip`

**Files:**
- Create: `lib/widgets/kolab_chip.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/widgets/kolab_chip.dart
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

enum KolabChipVariant {
  neutral,   // surfaceVariant — generic meta
  amber,     // amberChipContainer — city, discount, promo
  sage,      // tertiaryContainer — date ranges, wellness, nature
  lavender,  // secondaryContainer — community, lifestyle
  blueGrey,  // categoryBlueGrey — music, art, culture, film
  peach,     // #FFE9D9 — food & drink, bars, restaurants
}

/// Shared pastel tag chip used in Explore cards and all My Kolabs cards.
class KolabChip extends StatelessWidget {
  const KolabChip({
    required this.label,
    this.variant = KolabChipVariant.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final KolabChipVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(variant);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _colors(KolabChipVariant v) => switch (v) {
    KolabChipVariant.amber => (
      KolabingColors.amberChipContainer,
      KolabingColors.amberChipText,
    ),
    KolabChipVariant.sage => (
      KolabingColors.tertiaryContainer,
      KolabingColors.tertiary,
    ),
    KolabChipVariant.lavender => (
      KolabingColors.secondaryContainer,
      KolabingColors.secondary,
    ),
    KolabChipVariant.blueGrey => (
      KolabingColors.categoryBlueGrey,
      KolabingColors.categoryBlueGreyText,
    ),
    KolabChipVariant.peach => (
      const Color(0xFFFFE9D9),
      const Color(0xFFB05A2A),
    ),
    KolabChipVariant.neutral => (
      KolabingColors.surfaceVariant,
      KolabingColors.onSurfaceVariant,
    ),
  };
}

/// Pick a [KolabChipVariant] from a raw category/tag string.
KolabChipVariant kolabChipVariantFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('food') ||
      c.contains('drink') ||
      c.contains('bar') ||
      c.contains('restaurant') ||
      c.contains('cafe')) {
    return KolabChipVariant.peach;
  }
  if (c.contains('wellness') ||
      c.contains('yoga') ||
      c.contains('health') ||
      c.contains('fitness') ||
      c.contains('sport')) {
    return KolabChipVariant.sage;
  }
  if (c.contains('music') ||
      c.contains('art') ||
      c.contains('film') ||
      c.contains('culture') ||
      c.contains('photo')) {
    return KolabChipVariant.blueGrey;
  }
  if (c.contains('community') ||
      c.contains('event') ||
      c.contains('social')) {
    return KolabChipVariant.lavender;
  }
  if (c.contains('discount') || c.contains('promo')) {
    return KolabChipVariant.amber;
  }
  return KolabChipVariant.neutral;
}
```

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/widgets/kolab_chip.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/kolab_chip.dart
git commit -m "feat(ui): add KolabChip shared pastel tag widget"
```

---

## Task 3: Create `MyKolabsSubTabs`

**Files:**
- Create: `lib/features/kolab/widgets/my_kolabs_sub_tabs.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/features/kolab/widgets/my_kolabs_sub_tabs.dart
import 'package:flutter/material.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// Shared underline sub-tab row for all My Kolabs sections.
///
/// Use for Published/Draft (Offers) and Sent/Received (Requests).
/// Replaces the pill-style horizontal ListView in MyKollabsScreen and
/// MyOpportunitiesScreen.
class MyKolabsSubTabs extends StatelessWidget {
  const MyKolabsSubTabs({
    required this.controller,
    required this.labels,
    super.key,
  });

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TabBar(
        controller: controller,
        labelStyle: KolabingTextStyles.button.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: KolabingTextStyles.button.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        labelColor: KolabingColors.onSurface,
        unselectedLabelColor: KolabingColors.textTertiary,
        indicatorColor: KolabingColors.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        tabs: labels.map((l) => Tab(text: l)).toList(),
      ),
      const Divider(height: 1, thickness: 1, color: KolabingColors.hairline),
    ],
  );
}
```

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/features/kolab/widgets/my_kolabs_sub_tabs.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/kolab/widgets/my_kolabs_sub_tabs.dart
git commit -m "feat(ui): add MyKolabsSubTabs shared underline sub-tab component"
```

---

## Task 4: Shared image widget `_KolabSquareImage`

This private helper widget will be duplicated inline in `my_kolab_card.dart` and `my_opportunity_card.dart` (it is a layout detail, not a public API). Copy-paste is fine here — it's 30 lines.

**Files:**
- No new file — defined as a private class inside each card file.

The widget code to use in Tasks 5 and 6:

```dart
class _KolabSquareImage extends StatelessWidget {
  const _KolabSquareImage({required this.initials, this.imageUrl});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    const radius = 14.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size, radius),
        ),
      );
    }
    return _placeholder(size, radius);
  }

  Widget _placeholder(double size, double radius) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C4A12),
      ),
    ),
  );
}
```

No step here — this is reference code used in Tasks 5 and 6.

---

## Task 5: Restyle `MyKolabCard` (business offers)

**Files:**
- Modify: `lib/features/kolab/widgets/my_kolab_card.dart`

- [ ] **Step 1: Replace the entire file**

```dart
// lib/features/kolab/widgets/my_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';

class MyKolabCard extends StatelessWidget {
  const MyKolabCard({
    required this.kolab,
    super.key,
    this.onView,
    this.onEdit,
    this.onPublish,
    this.onClose,
    this.onDelete,
  });

  final Kolab kolab;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  String? get _imageUrl =>
      kolab.media.isNotEmpty ? kolab.media.first.url : null;

  String get _initials {
    final t = kolab.title.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : 'K';
  }

  String get _availabilityLabel {
    final start = kolab.availabilityStart;
    final end = kolab.availabilityEnd;
    if (start == null) return '';
    final fmt = DateFormat('MMM d');
    return end != null
        ? '${fmt.format(start)} – ${fmt.format(end)}'
        : fmt.format(start);
  }

  String get _secondaryLabel {
    if (kolab.intentType == IntentType.communitySeeking) {
      return kolab.communityTypeLabels.take(2).join(', ');
    }
    if (kolab.intentType == IntentType.venuePromotion) {
      return kolab.venueName ?? '';
    }
    return kolab.productName ?? '';
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: KolabingRadius.borderRadiusLg,
      border: Border.all(color: KolabingColors.hairline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KolabStatusBadge(status: kolab.status),
                const SizedBox(height: 6),
                Text(
                  kolab.title.isNotEmpty ? kolab.title : 'Untitled Kolab',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: KolabingSpacing.xs,
                  runSpacing: KolabingSpacing.xs,
                  children: [
                    if (kolab.preferredCity.isNotEmpty)
                      KolabChip(
                        label: kolab.preferredCity,
                        variant: KolabChipVariant.amber,
                        icon: LucideIcons.mapPin,
                      ),
                    if (_availabilityLabel.isNotEmpty)
                      KolabChip(
                        label: _availabilityLabel,
                        variant: KolabChipVariant.sage,
                        icon: LucideIcons.calendar,
                      ),
                    if (_secondaryLabel.isNotEmpty)
                      KolabChip(
                        label: _secondaryLabel,
                        variant: KolabChipVariant.lavender,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActions(),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          _KolabSquareImage(imageUrl: _imageUrl, initials: _initials),
        ],
      ),
    ),
  );

  Widget _buildActions() {
    final actions = <Widget>[];

    if (kolab.status == 'published' && onView != null) {
      actions.add(
        _ActionBtn(
          label: 'VIEW',
          icon: LucideIcons.eye,
          onTap: onView!,
          primary: true,
        ),
      );
    }
    if (kolab.canEdit && onEdit != null) {
      actions.add(
        _ActionBtn(
          label: 'EDIT',
          icon: LucideIcons.edit,
          onTap: onEdit!,
          outlined: true,
        ),
      );
    }
    if (kolab.canPublish && onPublish != null) {
      actions.add(
        _ActionBtn(
          label: 'PUBLISH',
          icon: LucideIcons.upload,
          onTap: onPublish!,
          primary: true,
        ),
      );
    }
    if (kolab.canClose && onClose != null) {
      actions.add(
        _ActionBtn(
          label: 'CLOSE',
          icon: LucideIcons.xCircle,
          onTap: onClose!,
          outlined: true,
        ),
      );
    }
    if (kolab.canDelete && onDelete != null) {
      actions.add(
        _ActionBtn(
          label: 'DELETE',
          icon: LucideIcons.trash2,
          onTap: onDelete!,
          danger: true,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .expand(
            (w) => [
              Expanded(child: w),
              const SizedBox(width: KolabingSpacing.xs),
            ],
          )
          .toList()
        ..removeLast(),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _KolabSquareImage extends StatelessWidget {
  const _KolabSquareImage({required this.initials, this.imageUrl});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    const radius = 14.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size, radius),
        ),
      );
    }
    return _placeholder(size, radius);
  }

  Widget _placeholder(double size, double radius) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C4A12),
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fgColor = primary
        ? KolabingColors.onYellowButton
        : danger
        ? KolabingColors.error
        : KolabingColors.onSurface;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: fgColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );

    if (primary) {
      return SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onYellowButton,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: danger ? KolabingColors.errorBg : KolabingColors.hairline,
          ),
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart analyze lib/features/kolab/widgets/my_kolab_card.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/kolab/widgets/my_kolab_card.dart
git commit -m "feat(ui): restyle MyKolabCard — horizontal layout, square image, pastel chips"
```

---

## Task 6: Restyle `MyOpportunityCard` (community offers)

**Files:**
- Modify: `lib/features/community/widgets/my_opportunity_card.dart`

- [ ] **Step 1: Replace the entire file**

```dart
// lib/features/community/widgets/my_opportunity_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../opportunity/models/opportunity.dart';

class MyOpportunityCard extends StatelessWidget {
  const MyOpportunityCard({
    required this.opportunity,
    super.key,
    this.onView,
    this.onEdit,
    this.onPublish,
    this.onShare,
    this.onClose,
    this.onDelete,
  });

  final Opportunity opportunity;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onShare;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  String? get _imageUrl {
    final p = opportunity.offerPhoto;
    return (p != null && p.isNotEmpty) ? p : null;
  }

  String get _initials {
    final t = opportunity.title.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : 'O';
  }

  String get _dateLabel {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(opportunity.availabilityStart)} – ${fmt.format(opportunity.availabilityEnd)}';
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: KolabingRadius.borderRadiusLg,
      border: Border.all(color: KolabingColors.hairline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KolabStatusBadge(status: opportunity.status.name),
                    if (opportunity.applicationsCount != null &&
                        opportunity.applicationsCount! > 0) ...[
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.users,
                            size: 12,
                            color: KolabingColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${opportunity.applicationsCount} app${opportunity.applicationsCount == 1 ? '' : 's'}',
                            style: KolabingTextStyles.labelSmall.copyWith(
                              color: KolabingColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  opportunity.title.isNotEmpty
                      ? opportunity.title
                      : 'Untitled Opportunity',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: KolabingSpacing.xs,
                  runSpacing: KolabingSpacing.xs,
                  children: [
                    KolabChip(
                      label: _dateLabel,
                      variant: KolabChipVariant.sage,
                      icon: LucideIcons.calendar,
                    ),
                    if (opportunity.preferredCity.isNotEmpty)
                      KolabChip(
                        label: opportunity.preferredCity,
                        variant: KolabChipVariant.amber,
                        icon: LucideIcons.mapPin,
                      ),
                    ...opportunity.categories.take(2).map(
                      (c) => KolabChip(
                        label: c,
                        variant: kolabChipVariantFor(c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActions(),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          _KolabSquareImage(imageUrl: _imageUrl, initials: _initials),
        ],
      ),
    ),
  );

  Widget _buildActions() {
    final status = opportunity.status;
    final actions = <Widget>[];

    if (status == OpportunityStatus.published && onView != null) {
      actions.add(
        _ActionBtn(label: 'VIEW', icon: LucideIcons.eye, onTap: onView!, primary: true),
      );
    }
    if (status.canEdit && onEdit != null) {
      actions.add(
        _ActionBtn(label: 'EDIT', icon: LucideIcons.edit, onTap: onEdit!, outlined: true),
      );
    }
    if (status.canPublish && onPublish != null) {
      actions.add(
        _ActionBtn(label: 'PUBLISH', icon: LucideIcons.upload, onTap: onPublish!, primary: true),
      );
    }
    if (status == OpportunityStatus.published && onShare != null) {
      actions.add(
        _ActionBtn(label: 'SHARE', icon: LucideIcons.share2, onTap: onShare!, outlined: true),
      );
    }
    if (status.canClose && onClose != null) {
      actions.add(
        _ActionBtn(label: 'CLOSE', icon: LucideIcons.xCircle, onTap: onClose!, outlined: true),
      );
    }
    if (status.canDelete &&
        (opportunity.applicationsCount ?? 0) == 0 &&
        onDelete != null) {
      actions.add(
        _ActionBtn(label: 'DELETE', icon: LucideIcons.trash2, onTap: onDelete!, danger: true),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .expand(
            (w) => [
              Expanded(child: w),
              const SizedBox(width: KolabingSpacing.xs),
            ],
          )
          .toList()
        ..removeLast(),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets — identical layout helpers as MyKolabCard
// ---------------------------------------------------------------------------

class _KolabSquareImage extends StatelessWidget {
  const _KolabSquareImage({required this.initials, this.imageUrl});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    const radius = 14.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size, radius),
        ),
      );
    }
    return _placeholder(size, radius);
  }

  Widget _placeholder(double size, double radius) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C4A12),
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fgColor = primary
        ? KolabingColors.onYellowButton
        : danger
        ? KolabingColors.error
        : KolabingColors.onSurface;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: fgColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );

    if (primary) {
      return SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onYellowButton,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: danger ? KolabingColors.errorBg : KolabingColors.hairline,
          ),
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart analyze lib/features/community/widgets/my_opportunity_card.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/widgets/my_opportunity_card.dart
git commit -m "feat(ui): restyle MyOpportunityCard — horizontal layout, offerPhoto image, pastel chips"
```

---

## Task 7: Wire `MyKolabsSubTabs` into Offers screens

Replace the `_buildStatusTabs()` pill-list in both screens with `MyKolabsSubTabs`.

**Files:**
- Modify: `lib/features/business/screens/my_kollabs_screen.dart`
- Modify: `lib/features/community/screens/my_opportunities_screen.dart`

### 7a — `MyKollabsScreen`

- [ ] **Step 1: Add import at top of `my_kollabs_screen.dart`**

Add this import alongside existing ones:
```dart
import '../../kolab/widgets/my_kolabs_sub_tabs.dart';
```

- [ ] **Step 2: Add `TabController` field and init/dispose**

The screen is already a `ConsumerStatefulWidget`. Add inside `_MyKollabsScreenState`:

```dart
late final TabController _statusTabController;
```

In `initState()` add **after** the scroll controller listener line:
```dart
_statusTabController = TabController(
  length: _statusTabs.length,
  vsync: this,
)..addListener(_onStatusTabChange);
```

Add the mixin `SingleTickerProviderStateMixin` to the state class if not already present (check — it may already have it from the scroll controller):
```dart
class _MyKollabsScreenState extends ConsumerState<MyKollabsScreen>
    with SingleTickerProviderStateMixin {
```

Add `_onStatusTabChange`:
```dart
void _onStatusTabChange() {
  if (!_statusTabController.indexIsChanging) {
    ref
        .read(myKolabsStatusProvider.notifier)
        .setStatus(_statusTabs[_statusTabController.index].value);
  }
}
```

In `dispose()` add before `super.dispose()`:
```dart
_statusTabController
  ..removeListener(_onStatusTabChange)
  ..dispose();
```

- [ ] **Step 3: Replace `_buildStatusTabs()` body**

Find the existing `_buildStatusTabs` method and replace the entire method body:

```dart
Widget _buildStatusTabs(String? currentStatus, bool isDark) {
  // Sync controller index when provider changes externally
  final selectedIndex = _statusTabs.indexWhere((t) => t.value == currentStatus);
  if (selectedIndex >= 0 &&
      _statusTabController.index != selectedIndex &&
      !_statusTabController.indexIsChanging) {
    _statusTabController.index = selectedIndex;
  }

  return MyKolabsSubTabs(
    controller: _statusTabController,
    labels: _statusTabs.map((t) => t.label.toUpperCase()).toList(),
  );
}
```

- [ ] **Step 4: Analyze**

```bash
dart analyze lib/features/business/screens/my_kollabs_screen.dart
```

Expected: no errors.

### 7b — `MyOpportunitiesScreen`

- [ ] **Step 5: Add import at top of `my_opportunities_screen.dart`**

```dart
import '../../kolab/widgets/my_kolabs_sub_tabs.dart';
```

- [ ] **Step 6: Add `TabController` and wire it**

Add field:
```dart
late final TabController _statusTabController;
```

In `initState()`:
```dart
_statusTabController = TabController(
  length: _statusTabs.length,
  vsync: this,
)..addListener(_onStatusTabChange);
```

Add `SingleTickerProviderStateMixin` to the state class if not already present.

Add listener:
```dart
void _onStatusTabChange() {
  if (!_statusTabController.indexIsChanging) {
    ref.read(myOpportunitiesStatusProvider.notifier).status =
        _statusTabs[_statusTabController.index].value;
  }
}
```

In `dispose()`:
```dart
_statusTabController
  ..removeListener(_onStatusTabChange)
  ..dispose();
```

- [ ] **Step 7: Replace `_buildStatusTabs()` body**

```dart
Widget _buildStatusTabs(String? currentStatus) {
  final selectedIndex = _statusTabs.indexWhere((t) => t.value == currentStatus);
  if (selectedIndex >= 0 &&
      _statusTabController.index != selectedIndex &&
      !_statusTabController.indexIsChanging) {
    _statusTabController.index = selectedIndex;
  }

  return MyKolabsSubTabs(
    controller: _statusTabController,
    labels: _statusTabs.map((t) => t.label.toUpperCase()).toList(),
  );
}
```

- [ ] **Step 8: Analyze**

```bash
dart analyze lib/features/community/screens/my_opportunities_screen.dart
```

Expected: no errors.

- [ ] **Step 9: Commit**

```bash
git add lib/features/business/screens/my_kollabs_screen.dart \
        lib/features/community/screens/my_opportunities_screen.dart
git commit -m "feat(ui): replace pill tabs with MyKolabsSubTabs in Offers screens"
```

---

## Task 8: Restyle `_ApplicationCard` (Requests tab)

Replace the circular avatar with the opportunity cover photo and switch to `KolabStatusBadge`. The sub-tab row inside `ApplicationsScreen` already uses the correct underline `TabBar` style — no change needed there.

**Files:**
- Modify: `lib/features/application/screens/applications_screen.dart`

- [ ] **Step 1: Add imports**

Add at the top of the file alongside existing imports:
```dart
import '../../../widgets/kolab_status_badge.dart';
```

- [ ] **Step 2: Replace `_ApplicationCard.build` method**

Find the `_ApplicationCard` class and replace its `build` method and the two private helper methods `_buildAvatar` and `_buildStatusBadge` with the following. The constructor and fields remain identical.

```dart
@override
Widget build(BuildContext context) => InkWell(
  onTap: onTap,
  borderRadius: KolabingRadius.borderRadiusMd,
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark ? KolabingColors.darkSurface : Colors.white,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: isDark
          ? null
          : Border.all(color: KolabingColors.hairline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KolabStatusBadge(status: application.status.name),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                application.opportunityTitle,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isReceived
                    ? 'From: ${application.applicantName}'
                    : 'To: ${application.recipientName}',
                style: KolabingTextStyles.captionSecondary.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                application.message,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 12,
                    color: KolabingColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    application.createdAtDisplay,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  if (application.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KolabingColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${application.unreadCount}',
                        style: KolabingTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: KolabingColors.textTertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        _buildSquareImage(),
      ],
    ),
  ),
);

Widget _buildSquareImage() {
  const size = 68.0;
  const radius = 14.0;

  final imageUrl = application.opportunity?.offerPhoto;
  final initials = application.opportunityTitle.isNotEmpty
      ? application.opportunityTitle[0].toUpperCase()
      : 'K';

  if (imageUrl != null && imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(size, radius, initials),
      ),
    );
  }
  return _imagePlaceholder(size, radius, initials);
}

Widget _imagePlaceholder(double size, double radius, String initials) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5C4A12),
        ),
      ),
    );
```

Also **delete** the old `_buildAvatar`, `_avatarPlaceholder`, and `_buildStatusBadge` methods from `_ApplicationCard` — they are fully replaced by the above.

- [ ] **Step 3: Analyze**

```bash
dart analyze lib/features/application/screens/applications_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/application/screens/applications_screen.dart
git commit -m "feat(ui): restyle ApplicationCard — square opportunity image, shared status badge"
```

---

## Task 9: Restyle `_CollaborationCard` (Active/Finished tabs)

**Files:**
- Modify: `lib/features/collaboration/widgets/collaborations_list_tab.dart`

- [ ] **Step 1: Add import**

```dart
import '../../../widgets/kolab_status_badge.dart';
```

- [ ] **Step 2: Replace `_CollaborationCard.build` method**

Find `_CollaborationCard` and replace its `build` method. The constructor and `collaboration`/`isDark` fields are unchanged.

```dart
@override
Widget build(BuildContext context) {
  final partner = collaboration.businessPartner.name.isNotEmpty
      ? '${collaboration.businessPartner.name} × ${collaboration.communityPartner.name}'
      : collaboration.communityPartner.name;

  final imageUrl = collaboration.opportunity?.offerPhoto;
  final initials = partner.isNotEmpty ? partner[0].toUpperCase() : 'K';

  return Material(
    color: isDark ? KolabingColors.darkSurface : Colors.white,
    borderRadius: KolabingRadius.borderRadiusLg,
    child: InkWell(
      borderRadius: KolabingRadius.borderRadiusLg,
      onTap: () => context.push('/collaboration/${collaboration.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: isDark
            ? null
            : BoxDecoration(
                border: Border.all(color: KolabingColors.hairline),
                borderRadius: KolabingRadius.borderRadiusLg,
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KolabStatusBadge(status: collaboration.status.toApiValue()),
                  const SizedBox(height: 6),
                  Text(
                    partner,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        collaboration.formattedDate,
                        style: KolabingTextStyles.captionSecondary.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                      if (collaboration.scheduledTime != null &&
                          collaboration.scheduledTime!.isNotEmpty) ...[
                        const SizedBox(width: KolabingSpacing.sm),
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: KolabingColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            collaboration.scheduledTime!,
                            style: KolabingTextStyles.captionSecondary.copyWith(
                              color: KolabingColors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: KolabingColors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            _buildSquareImage(imageUrl, initials),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSquareImage(String? imageUrl, String initials) {
  const size = 68.0;
  const radius = 14.0;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(size, radius, initials),
      ),
    );
  }
  return _placeholder(size, radius, initials);
}

Widget _placeholder(double size, double radius, String initials) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
    ),
  ),
  alignment: Alignment.center,
  child: Text(
    initials,
    style: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Color(0xFF5C4A12),
    ),
  ),
);
```

Also **delete** the old `_StatusBadge` private class at the bottom of `collaborations_list_tab.dart` — it is replaced by `KolabStatusBadge`.

- [ ] **Step 3: Analyze**

```bash
dart analyze lib/features/collaboration/widgets/collaborations_list_tab.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/collaboration/widgets/collaborations_list_tab.dart
git commit -m "feat(ui): restyle CollaborationCard — horizontal layout, opportunity image, shared badge"
```

---

## Task 10: Full build verification

- [ ] **Step 1: Run full analysis**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/
```

Expected: no errors. Warnings about deprecated tokens are fine — do not fix them.

- [ ] **Step 2: Build for iOS simulator to catch widget-tree issues**

```bash
flutter build ios --simulator --no-codesign 2>&1 | tail -20
```

Expected: `Build complete.` If build fails, fix the error and re-analyze before committing.

- [ ] **Step 3: Final commit if any lint fixes were needed**

```bash
git add -p
git commit -m "fix(ui): lint fixes from full analysis pass"
```

---

## Self-Review Checklist

- [x] **KolabStatusBadge** covers all status strings used across all four card types: published, draft, closed, completed, scheduled, in_progress/active, pending_confirmation, pending, accepted, declined, withdrawn, cancelled.
- [x] **KolabChip** variant helper `kolabChipVariantFor` is exported from `kolab_chip.dart` and used in `MyOpportunityCard` for `categories`.
- [x] **MyKolabsSubTabs** replaces `_buildStatusTabs` in both `MyKollabsScreen` and `MyOpportunitiesScreen`. The `TabController` is owned by the state class and disposed correctly.
- [x] **Image sources**: `kolab.media.first.url` (MyKolabCard), `opportunity.offerPhoto` (MyOpportunityCard), `application.opportunity?.offerPhoto` (ApplicationCard), `collaboration.opportunity?.offerPhoto` (CollaborationCard).
- [x] **Old private widgets deleted**: `_StatusBadge` in `collaborations_list_tab.dart`, `_buildAvatar`/`_buildStatusBadge` in `applications_screen.dart`, `_InfoPill`/`_ActionButton`/`_ActionButtonContent` in both card files.
- [x] No routes, providers, or data logic touched.
- [x] Empty states and shimmer skeletons untouched.
- [x] `embedded` prop behavior on `MyKollabsScreen` and `MyOpportunitiesScreen` untouched.
