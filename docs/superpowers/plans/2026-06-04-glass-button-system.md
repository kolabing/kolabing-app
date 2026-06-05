# Glass Button System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace solid CTA buttons with a translucent "clear glass" button system and re-layout the My Kolabs / My Opportunities card action rows into one primary pill + round icon-only secondary buttons.

**Architecture:** Two new shared widgets (`GlassButton`, `GlassIconButton`) live under `lib/widgets/`. Two new colour tokens are added to `KolabingColors`. Each call-site file is then updated to swap its `ElevatedButton`/`OutlinedButton` usages for the new widgets; no handlers, routes, providers, or models change.

**Tech Stack:** Flutter (Dart), Riverpod 2.4, Lucide Icons, `dart:ui` (BackdropFilter), google_fonts (Inter already in use)

---

## File Map

| Action | File | What changes |
|---|---|---|
| Modify | `lib/config/theme/colors.dart` | Add `glassInk`, `glassDestructiveInk` tokens |
| Create | `lib/widgets/glass_button.dart` | New `GlassButton` widget + `GlassButtonIntent` enum |
| Create | `lib/widgets/glass_icon_button.dart` | New `GlassIconButton` widget |
| Modify | `lib/features/kolab/widgets/my_kolab_card.dart` | Replace `_ActionBtn` + `_buildActions` |
| Modify | `lib/features/community/widgets/my_opportunity_card.dart` | Same |
| Modify | `lib/features/business/widgets/opportunity_card.dart` | Replace VIEW + APPLY buttons |
| Modify | `lib/features/dashboard/screens/business_dashboard_screen.dart` | Replace `_buildQuickActions` + error RETRY |
| Modify | `lib/features/dashboard/screens/community_dashboard_screen.dart` | Replace `_buildQuickActions` + error RETRY |
| Modify | `lib/features/rewards/widgets/referral_banner_card.dart` | Replace banner SHARE REFERRAL CODE button |
| Modify | `lib/features/business/screens/business_profile_screen.dart` | Replace TRY AGAIN, MANAGE SUBSCRIPTION, UPGRADE TO PREMIUM, SIGN OUT |
| Modify | `lib/features/community/screens/community_profile_screen.dart` | Replace TRY AGAIN, SIGN OUT |

---

## Task 1: Add colour tokens

**Files:**
- Modify: `lib/config/theme/colors.dart`

- [ ] **Step 1: Add the two new tokens after the `glassWhite14` constant**

In `lib/config/theme/colors.dart`, find the line:
```dart
  /// 14% white — glass/frosted effect on dark surfaces
  static const Color glassWhite14 = Color(0x24FFFFFF);
```
Add immediately after it:
```dart

  // ---------------------------------------------------------------------------
  // Glass button ink
  // ---------------------------------------------------------------------------

  /// Warm dark ink used on all glass button intents
  static const Color glassInk = Color(0xFF57534B);

  /// Destructive ink for glass buttons
  static const Color glassDestructiveInk = Color(0xFF9B3B3B);
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/config/theme/colors.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/config/theme/colors.dart
git commit -m "feat(design): add glassInk and glassDestructiveInk colour tokens"
```

---

## Task 2: Create `GlassButton`

**Files:**
- Create: `lib/widgets/glass_button.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/widgets/glass_button.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme/colors.dart';

enum GlassButtonIntent { primary, neutral, destructive }

class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.intent = GlassButtonIntent.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonIntent intent;
  final IconData? icon;

  Color get _fill => switch (intent) {
        GlassButtonIntent.primary =>
          const Color(0xFFFFF4C2).withOpacity(0.34),
        GlassButtonIntent.neutral => Colors.white.withOpacity(0.30),
        GlassButtonIntent.destructive =>
          const Color(0xFF9B3B3B).withOpacity(0.10),
      };

  Color get _border => switch (intent) {
        GlassButtonIntent.primary || GlassButtonIntent.neutral =>
          Colors.white.withOpacity(0.78),
        GlassButtonIntent.destructive =>
          const Color(0xFF9B3B3B).withOpacity(0.35),
      };

  Color get _ink => switch (intent) {
        GlassButtonIntent.primary || GlassButtonIntent.neutral =>
          KolabingColors.glassInk,
        GlassButtonIntent.destructive => KolabingColors.glassDestructiveInk,
      };

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: _ink),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label.toLowerCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: _ink,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: _fill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A96781E),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.12],
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/widgets/glass_button.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/widgets/glass_button.dart
git commit -m "feat(widgets): add GlassButton with primary/neutral/destructive intents"
```

---

## Task 3: Create `GlassIconButton`

**Files:**
- Create: `lib/widgets/glass_icon_button.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/widgets/glass_icon_button.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../config/theme/colors.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          label: semanticsLabel ?? tooltip,
          button: true,
          child: GestureDetector(
            onTap: onPressed,
            child: Opacity(
              opacity: onPressed == null ? 0.45 : 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.78),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14785A28),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 18, color: KolabingColors.glassInk),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
```

- [ ] **Step 2: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/widgets/glass_icon_button.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/widgets/glass_icon_button.dart
git commit -m "feat(widgets): add GlassIconButton with tooltip and semantics"
```

---

## Task 4: Update `my_kolab_card.dart`

**Files:**
- Modify: `lib/features/kolab/widgets/my_kolab_card.dart`

The current card has a private `_ActionBtn` class and `_buildActions()` that renders a flat 4-up row of equally-expanded buttons. Replace both with a pill + icon-button row.

- [ ] **Step 1: Add imports**

At the top of `lib/features/kolab/widgets/my_kolab_card.dart`, add after the existing imports:
```dart
import '../../../widgets/glass_button.dart';
import '../../../widgets/glass_icon_button.dart';
```

- [ ] **Step 2: Replace `_buildActions()`**

Find and replace the entire `_buildActions()` method (from `Widget _buildActions() {` to the closing `}` that ends it) with:

```dart
  Widget _buildActions() {
    // Determine the primary (pill) action and the secondary (icon) actions.
    // Primary is the most important action for the current status.
    // All existing onPressed handlers are preserved unchanged.

    Widget? pill;
    final iconBtns = <Widget>[];

    if (kolab.status == 'published') {
      if (onView != null) {
        pill = GlassButton(
          label: 'view',
          onPressed: onView,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.eye,
        );
      }
      if (kolab.canEdit && onEdit != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.edit,
          onPressed: onEdit,
          tooltip: 'Edit',
        ));
      }
      if (kolab.canClose && onClose != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.xCircle,
          onPressed: onClose,
          tooltip: 'Close',
        ));
      }
    } else if (kolab.canEdit) {
      if (onEdit != null) {
        pill = GlassButton(
          label: 'edit',
          onPressed: onEdit,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.edit,
        );
      }
      if (kolab.canPublish && onPublish != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.upload,
          onPressed: onPublish,
          tooltip: 'Publish',
        ));
      }
    } else if (kolab.canPublish) {
      if (onPublish != null) {
        pill = GlassButton(
          label: 'publish',
          onPressed: onPublish,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.upload,
        );
      }
    }

    if (kolab.canDelete && onDelete != null) {
      if (pill == null) {
        pill = GlassButton(
          label: 'delete',
          onPressed: onDelete,
          intent: GlassButtonIntent.destructive,
          icon: LucideIcons.trash2,
        );
      } else {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.trash2,
          onPressed: onDelete,
          tooltip: 'Delete',
        ));
      }
    }

    if (pill == null && iconBtns.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (pill != null) Expanded(child: pill),
        ...iconBtns.expand((btn) => [
          const SizedBox(width: 9),
          btn,
        ]),
      ],
    );
  }
```

- [ ] **Step 3: Delete the private `_ActionBtn` class**

Remove the entire `class _ActionBtn extends StatelessWidget { ... }` block at the bottom of the file (it is no longer used).

- [ ] **Step 4: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/kolab/widgets/my_kolab_card.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/kolab/widgets/my_kolab_card.dart
git commit -m "feat(kolab): replace action row with GlassButton pill + GlassIconButton"
```

---

## Task 5: Update `my_opportunity_card.dart`

**Files:**
- Modify: `lib/features/community/widgets/my_opportunity_card.dart`

Identical structural change to Task 4.

- [ ] **Step 1: Add imports**

```dart
import '../../../widgets/glass_button.dart';
import '../../../widgets/glass_icon_button.dart';
```

- [ ] **Step 2: Replace `_buildActions()`**

Replace the entire `_buildActions()` method with:

```dart
  Widget _buildActions() {
    final status = opportunity.status;
    Widget? pill;
    final iconBtns = <Widget>[];

    if (status == OpportunityStatus.published) {
      if (onView != null) {
        pill = GlassButton(
          label: 'view',
          onPressed: onView,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.eye,
        );
      }
      if (status.canEdit && onEdit != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.edit,
          onPressed: onEdit,
          tooltip: 'Edit',
        ));
      }
      if (onShare != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.share2,
          onPressed: onShare,
          tooltip: 'Share',
        ));
      }
      if (status.canClose && onClose != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.xCircle,
          onPressed: onClose,
          tooltip: 'Close',
        ));
      }
    } else if (status.canEdit) {
      if (onEdit != null) {
        pill = GlassButton(
          label: 'edit',
          onPressed: onEdit,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.edit,
        );
      }
      if (status.canPublish && onPublish != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.upload,
          onPressed: onPublish,
          tooltip: 'Publish',
        ));
      }
    } else if (status.canPublish) {
      if (onPublish != null) {
        pill = GlassButton(
          label: 'publish',
          onPressed: onPublish,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.upload,
        );
      }
    }

    if (status.canDelete &&
        (opportunity.applicationsCount ?? 0) == 0 &&
        onDelete != null) {
      if (pill == null) {
        pill = GlassButton(
          label: 'delete',
          onPressed: onDelete,
          intent: GlassButtonIntent.destructive,
          icon: LucideIcons.trash2,
        );
      } else {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.trash2,
          onPressed: onDelete,
          tooltip: 'Delete',
        ));
      }
    }

    if (pill == null && iconBtns.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (pill != null) Expanded(child: pill),
        ...iconBtns.expand((btn) => [
          const SizedBox(width: 9),
          btn,
        ]),
      ],
    );
  }
```

- [ ] **Step 3: Delete the private `_ActionBtn` class** at the bottom of the file.

- [ ] **Step 4: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/community/widgets/my_opportunity_card.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/community/widgets/my_opportunity_card.dart
git commit -m "feat(community): replace opportunity card action row with glass buttons"
```

---

## Task 6: Update `opportunity_card.dart` (Explore card)

**Files:**
- Modify: `lib/features/business/widgets/opportunity_card.dart`

- [ ] **Step 1: Add imports**

```dart
import '../../../widgets/glass_button.dart';
```

- [ ] **Step 2: Replace `_buildActionButtons()`**

Find and replace the entire `_buildActionButtons()` method with:

```dart
  Widget _buildActionButtons(bool isDark) => Row(
        children: [
          Expanded(
            child: GlassButton(
              label: 'view',
              onPressed: onView,
              intent: GlassButtonIntent.neutral,
              icon: LucideIcons.eye,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: GlassButton(
              label: 'apply',
              onPressed: onApply,
              intent: GlassButtonIntent.primary,
              icon: LucideIcons.send,
            ),
          ),
        ],
      );
```

Note the `isDark` parameter is kept in the signature to avoid changing the call site, even though the glass buttons are theme-agnostic.

- [ ] **Step 3: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/business/widgets/opportunity_card.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/business/widgets/opportunity_card.dart
git commit -m "feat(explore): replace VIEW/APPLY buttons with GlassButton"
```

---

## Task 7: Update `business_dashboard_screen.dart`

**Files:**
- Modify: `lib/features/dashboard/screens/business_dashboard_screen.dart`

Two locations: `_buildQuickActions` (the primary row) and the error-state RETRY button.

- [ ] **Step 1: Add import**

```dart
import '../../../widgets/glass_button.dart';
```

- [ ] **Step 2: Replace `_buildQuickActions()`**

Find the entire `Widget _buildQuickActions(bool isDark) => Row(` block and replace with:

```dart
  Widget _buildQuickActions(bool isDark) => Row(
    children: [
      Expanded(
        child: GlassButton(
          label: 'create kolab request',
          onPressed: () async {
            final allowed = await SubscriptionPaywall.checkAndShow(
              context,
              ref,
            );
            if (!allowed || !mounted) return;
            await context.push(KolabingRoutes.kolabNew);
            if (mounted) {
              await Future<void>.delayed(const Duration(milliseconds: 300));
              if (mounted) ref.invalidate(dashboardProvider);
            }
          },
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.plus,
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: GlassButton(
          label: 'find a kolab',
          onPressed: () => widget.onSwitchTab?.call(1),
          intent: GlassButtonIntent.neutral,
          icon: LucideIcons.search,
        ),
      ),
    ],
  );
```

- [ ] **Step 3: Replace the error-state RETRY button**

Find:
```dart
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(dashboardProvider.notifier).refresh();
              },
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(
                'RETRY',
                style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
```

Replace with:
```dart
            GlassButton(
              label: 'retry',
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              intent: GlassButtonIntent.primary,
              icon: LucideIcons.refreshCw,
            ),
```

- [ ] **Step 4: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/dashboard/screens/business_dashboard_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/dashboard/screens/business_dashboard_screen.dart
git commit -m "feat(business-dashboard): replace quick-action and retry buttons with GlassButton"
```

---

## Task 8: Update `community_dashboard_screen.dart`

**Files:**
- Modify: `lib/features/dashboard/screens/community_dashboard_screen.dart`

- [ ] **Step 1: Add import**

```dart
import '../../../widgets/glass_button.dart';
```

- [ ] **Step 2: Replace `_buildQuickActions()`**

Find the entire `Widget _buildQuickActions(bool isDark)` block and replace with:

```dart
  Widget _buildQuickActions(bool isDark) => Row(
    children: [
      Expanded(
        child: GlassButton(
          label: 'find a kolab',
          onPressed: () => widget.onSwitchTab?.call(1),
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.search,
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: GlassButton(
          label: 'my applications',
          onPressed: () => widget.onSwitchTab?.call(3),
          intent: GlassButtonIntent.neutral,
        ),
      ),
    ],
  );
```

- [ ] **Step 3: Replace the error-state RETRY button**

Find the `ElevatedButton.icon` in the error-state builder (around line 417). It looks like:
```dart
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(dashboardProvider.notifier).refresh();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 18),
```

Replace the full `ElevatedButton.icon(...)` widget with:
```dart
              GlassButton(
                label: 'retry',
                onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
                intent: GlassButtonIntent.primary,
                icon: LucideIcons.refreshCw,
              ),
```

- [ ] **Step 4: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/dashboard/screens/community_dashboard_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/dashboard/screens/community_dashboard_screen.dart
git commit -m "feat(community-dashboard): replace quick-action and retry buttons with GlassButton"
```

---

## Task 9: Update `referral_banner_card.dart`

**Files:**
- Modify: `lib/features/rewards/widgets/referral_banner_card.dart`

Only the banner's `OutlinedButton` "SHARE REFERRAL CODE" changes. The bottom-sheet copy/share buttons are out of scope (Phase B).

- [ ] **Step 1: Add import**

```dart
import '../../../widgets/glass_button.dart';
```

- [ ] **Step 2: Replace the SHARE REFERRAL CODE button**

Find:
```dart
                OutlinedButton(
                  onPressed: () =>
                      _showReferralCodeSheet(context, referralCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KolabingColors.onSurface,
                    side: const BorderSide(color: Color(0xFFEAE3D4), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.md,
                      vertical: KolabingSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'SHARE REFERRAL CODE',
                    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                  ),
                ),
```

Replace with:
```dart
                GlassButton(
                  label: 'share referral code',
                  onPressed: () =>
                      _showReferralCodeSheet(context, referralCode),
                  intent: GlassButtonIntent.primary,
                  icon: LucideIcons.share2,
                ),
```

- [ ] **Step 3: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/rewards/widgets/referral_banner_card.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/rewards/widgets/referral_banner_card.dart
git commit -m "feat(referral): replace share referral code button with GlassButton"
```

---

## Task 10: Update `business_profile_screen.dart`

**Files:**
- Modify: `lib/features/business/screens/business_profile_screen.dart`

Four buttons change: TRY AGAIN (error state), MANAGE SUBSCRIPTION, UPGRADE TO PREMIUM, SIGN OUT. The `TextButton` instances inside `AlertDialog` actions (Cancel / Sign Out / Delete) are **not** changed — those are modal chrome, out of scope.

- [ ] **Step 1: Add import**

```dart
import '../../../widgets/glass_button.dart';
```

- [ ] **Step 2: Replace the TRY AGAIN button (error state, ~line 427)**

Find:
```dart
          ElevatedButton.icon(
            onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('TRY AGAIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.lg,
                vertical: KolabingSpacing.sm,
              ),
            ),
          ),
```

Replace with:
```dart
          GlassButton(
            label: 'try again',
            onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
            intent: GlassButtonIntent.primary,
            icon: LucideIcons.rotateCcw,
          ),
```

- [ ] **Step 3: Replace MANAGE SUBSCRIPTION button (~line 786)**

Find:
```dart
            OutlinedButton.icon(
              onPressed: _handleManageSubscription,
              icon: const Icon(LucideIcons.settings, size: 18),
              label: const Text('MANAGE SUBSCRIPTION'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.onSurface,
                side: const BorderSide(color: KolabingColors.darkBorder),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
              ),
            )
```

Replace with:
```dart
            GlassButton(
              label: 'manage subscription',
              onPressed: _handleManageSubscription,
              intent: GlassButtonIntent.neutral,
              icon: LucideIcons.settings,
            )
```

- [ ] **Step 4: Replace UPGRADE TO PREMIUM button (~line 799)**

Find:
```dart
            ElevatedButton.icon(
              onPressed: _handleViewPlans,
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: const Text('UPGRADE TO PREMIUM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
              ),
            ),
```

Replace with:
```dart
            GlassButton(
              label: 'upgrade to premium',
              onPressed: _handleViewPlans,
              intent: GlassButtonIntent.primary,
              icon: LucideIcons.sparkles,
            ),
```

- [ ] **Step 5: Replace SIGN OUT button (~line 1004)**

Find:
```dart
        OutlinedButton.icon(
          onPressed: isUpdating ? null : _handleSignOut,
          icon: const Icon(LucideIcons.logOut, size: 18),
          label: const Text('SIGN OUT'),
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.error,
            side: const BorderSide(color: KolabingColors.error),
            padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
          ),
        ),
```

Replace with:
```dart
        GlassButton(
          label: 'sign out',
          onPressed: isUpdating ? null : _handleSignOut,
          intent: GlassButtonIntent.destructive,
          icon: LucideIcons.logOut,
        ),
```

- [ ] **Step 6: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/business/screens/business_profile_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/business/screens/business_profile_screen.dart
git commit -m "feat(business-profile): replace CTA and sign-out buttons with GlassButton"
```

---

## Task 11: Update `community_profile_screen.dart`

**Files:**
- Modify: `lib/features/community/screens/community_profile_screen.dart`

Two buttons change: TRY AGAIN (error state) and SIGN OUT.

- [ ] **Step 1: Add import**

```dart
import '../../../widgets/glass_button.dart';
```

- [ ] **Step 2: Replace TRY AGAIN button (~line 424)**

Find:
```dart
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
```
(Look for the `ElevatedButton.icon` in the error-state widget near line 424.)

Replace the full `ElevatedButton.icon(...)` block with:
```dart
              GlassButton(
                label: 'try again',
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                intent: GlassButtonIntent.primary,
                icon: LucideIcons.rotateCcw,
              ),
```

- [ ] **Step 3: Replace SIGN OUT button (~line 855)**

Find:
```dart
            OutlinedButton.icon(
              onPressed: isUpdating ? null : _handleSignOut,
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('SIGN OUT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.error,
                side: const BorderSide(color: KolabingColors.error),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
              ),
            ),
```

Replace with:
```dart
            GlassButton(
              label: 'sign out',
              onPressed: isUpdating ? null : _handleSignOut,
              intent: GlassButtonIntent.destructive,
              icon: LucideIcons.logOut,
            ),
```

- [ ] **Step 4: Verify**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/features/community/screens/community_profile_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add lib/features/community/screens/community_profile_screen.dart
git commit -m "feat(community-profile): replace CTA and sign-out buttons with GlassButton"
```

---

## Task 12: Full analysis pass

- [ ] **Step 1: Run full project analysis**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && dart analyze lib/
```
Expected: `No issues found!`

Fix any remaining issues before proceeding.

- [ ] **Step 2: Run the app and do a quick visual smoke-test**

```bash
cd /Users/macbook/kolabing-app/kolabing-app && flutter run
```

Check these surfaces in order:
1. Business dashboard → quick-action row (glass primary + neutral pill)
2. Community dashboard → quick-action row
3. Explore card → VIEW + APPLY glass pills
4. My Kolabs screen → published card (view pill + edit/close icons) + draft card (edit pill + publish icon)
5. Business profile → manage subscription / sign out
6. Community profile → sign out
7. Referral banner → share referral code pill

- [ ] **Step 3: Final commit if any minor tweaks were needed**

```bash
cd /Users/macbook/kolabing-app/kolabing-app
git add -p   # stage only the visual fixes
git commit -m "fix(glass-buttons): visual tweaks after smoke-test"
```
