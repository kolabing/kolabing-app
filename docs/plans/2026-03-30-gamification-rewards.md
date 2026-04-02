# Gamification & Rewards — Mobile Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add points wallet, badges, referrals, and withdrawal system for Community + Business users — embedded in dashboards as motivational cards.

**Architecture:** New `lib/features/rewards/` module (separate from existing `gamification/` which is attendee-specific). Models + mock service + Riverpod providers + widgets + screens. Dashboard screens get wallet/referral cards injected. BFF approach — mock service initially, real API when backend deploys.

**Tech Stack:** Flutter, Riverpod 2.4, GoRouter, GoogleFonts, LucideIcons, share_plus, confetti

**Backend spec:** `.agent/documentations/gamification-rewards-backend-spec.md`

**Design spec provided by user:** Full UX flows, component specs, implementation groups

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

Add:
```yaml
  share_plus: ^10.1.4
  confetti: ^0.8.0
```

Run: `flutter pub get`

Commit: `feat: add share_plus and confetti packages`

---

## Task 2: Create Models (3 files)

**Files:**
- Create: `lib/features/rewards/models/wallet_model.dart`
- Create: `lib/features/rewards/models/ledger_entry.dart`
- Create: `lib/features/rewards/models/reward_badge.dart`

### wallet_model.dart
```dart
@immutable class WalletModel {
  final int points, redeemedPoints;
  final bool pendingWithdrawal;
  int get availablePoints => points - redeemedPoints;
  double get eurValue => availablePoints * 0.20;
  double get progress => (availablePoints / 375).clamp(0.0, 1.0);
  bool get canWithdraw => availablePoints >= 375 && !pendingWithdrawal;
  static const int withdrawalThreshold = 375;
  // const constructor, fromJson, copyWith
}
```

### ledger_entry.dart
```dart
enum PointEventType { collaborationComplete, reviewPosted, ugcPosted, referral1m, referral4m, withdrawal }
// Each with: displayLabel, toApiValue(), fromString(), icon (LucideIcons)
@immutable class LedgerEntry {
  final String id, description;
  final int points;
  final PointEventType eventType;
  final DateTime createdAt;
  bool get isEarned => points > 0;
  // fromJson
}
```

### reward_badge.dart
```dart
enum RewardBadgeSlug { firstKolab, contentCreator, communityEarner, referralPioneer, powerPartner }
// Each with: name, shortName, description, requirement, icon (LucideIcons)
@immutable class RewardBadge {
  final RewardBadgeSlug slug;
  final bool isUnlocked;
  final DateTime? earnedAt;
  // fromJson
}
```

Follow patterns from `lib/features/kolab/enums/` and `lib/features/opportunity/models/opportunity.dart`.

Verify: `dart analyze lib/features/rewards/models/`

Commit: `feat(rewards): add wallet, ledger, badge models`

---

## Task 3: Create Mock RewardsService

**Files:**
- Create: `lib/features/rewards/services/rewards_service.dart`

Mock service matching the backend spec endpoints. All methods return mock data with 500ms delay.

```dart
class RewardsService {
  Future<WalletModel> getWallet();              // mock: 127 points
  Future<List<LedgerEntry>> getLedger({int page, int perPage});
  Future<List<RewardBadge>> getBadges();         // mock: 2 unlocked, 3 locked
  Future<String> getReferralCode();              // mock: "KOLAB-A3X9"
  Future<void> requestWithdrawal({required String iban, required String accountHolder});
}
final rewardsServiceProvider = Provider<RewardsService>((ref) => RewardsService());
```

Verify: `dart analyze lib/features/rewards/services/`

Commit: `feat(rewards): add mock RewardsService`

---

## Task 4: Create WalletProvider

**Files:**
- Create: `lib/features/rewards/providers/wallet_provider.dart`

```dart
@immutable class WalletState {
  final WalletModel? wallet;
  final List<LedgerEntry> ledger;
  final List<RewardBadge> badges;
  final String? referralCode;
  final bool isLoading, isWithdrawing;
  final String? error;
  final List<RewardBadgeSlug> newlyEarnedBadges;  // triggers celebration
  // copyWith
}

class WalletNotifier extends Notifier<WalletState> {
  build() → load();
  Future<void> load();            // fetch wallet + badges + referral code
  Future<void> loadLedger();      // paginated
  Future<void> requestWithdrawal({iban, accountHolder});
  void clearNewBadges();
  Future<void> refresh();
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(...);
final walletSummaryProvider = Provider<WalletModel?>((ref) => ref.watch(walletProvider).wallet);
```

Verify: `dart analyze lib/features/rewards/providers/`

Commit: `feat(rewards): add WalletProvider`

---

## Task 5: Create Widgets (6 files)

**Files:**
- Create: `lib/features/rewards/widgets/points_progress_bar.dart`
- Create: `lib/features/rewards/widgets/points_wallet_card.dart`
- Create: `lib/features/rewards/widgets/reward_badge_card.dart`
- Create: `lib/features/rewards/widgets/referral_banner_card.dart`
- Create: `lib/features/rewards/widgets/badge_celebration_overlay.dart`
- Create: `lib/features/rewards/widgets/collaboration_reward_nudge.dart`

### points_progress_bar.dart
TweenAnimationBuilder, 8px height track, 600ms ease-out animation. Props: currentPoints, targetPoints (375), animate, showLabel, darkMode. Green at 100%.

### points_wallet_card.dart
Yellow gradient card (#FFD861 → #FFE082). Shows: points (Rubik 40px bold), EUR value chip, embedded PointsProgressBar (darkMode: true), withdraw button when >= 375 pts. Shimmer loading state. Full spec in user's component spec.

### reward_badge_card.dart
Supports compact (80x96) and grid (160x180) modes. Locked = grey + dashed border + 0.5 opacity. Unlocked = white + yellow border + shadow. Icon in circle + name + description.

### referral_banner_card.dart
surfaceVariant background, gift icon in yellow circle, "EARN BY SHARING" header, share button using `Share.share()` from share_plus.

### badge_celebration_overlay.dart
OverlayEntry (not a route). Black scrim + confetti + animated badge icon (spring scale) + "New Badge Unlocked!" text + CTA button. Uses confetti package.

### collaboration_reward_nudge.dart
Small yellow card: "+1 point earned" + "Post a review to earn another" + "Post review →" button. Shown when collaboration status == completed.

Verify: `dart analyze lib/features/rewards/widgets/`

Commit: `feat(rewards): add all reward widgets`

---

## Task 6: Create WalletScreen

**Files:**
- Create: `lib/features/rewards/screens/wallet_screen.dart`

Route: `/community/wallet`

Scaffold with AppBar "MY WALLET". SingleChildScrollView body:
1. PointsWalletCard (expanded, no tap)
2. "BADGES" section — GridView.count 2 columns with all 5 RewardBadge cards
3. "REFER & EARN" section — referral code display + share button + tier explanation
4. "POINTS HISTORY" section — ListView of LedgerEntry items (shrinkWrap)

Each ledger entry: Row with event icon + description + date + points (green positive, red negative).

Reads from `walletProvider`.

Commit: `feat(rewards): add WalletScreen`

---

## Task 7: Create WithdrawalRequestScreen

**Files:**
- Create: `lib/features/rewards/screens/withdrawal_request_screen.dart`

Route: `/community/wallet/withdraw`

Simple form:
- "You have €XX.XX available to withdraw" summary
- IBAN text field with validation
- Account holder name field
- Confirm button → `walletProvider.requestWithdrawal()`
- Success state: "Request submitted. Processing within 5-7 business days."
- Error state: inline error

Commit: `feat(rewards): add WithdrawalRequestScreen`

---

## Task 8: Create ReferralScreen

**Files:**
- Create: `lib/features/rewards/screens/referral_screen.dart`

Route: `/community/referrals` (replace existing placeholder)

Props: `UserType userType` (community or business, different copy).

Content:
- Large copyable referral code
- Share button → native share sheet
- "How it works" 3-step explainer
- Referral tier table (community: 50/100 pts, business: 1 free month)

Commit: `feat(rewards): add ReferralScreen`

---

## Task 9: Dashboard Integration

**Files:**
- Modify: Community dashboard screen (find via `lib/features/community/` or `lib/features/dashboard/`)
- Modify: Business dashboard screen (find via `lib/features/business/`)

### Community Dashboard
Insert between stats grid and upcoming collaborations:
```dart
// PointsWalletCard
Consumer(builder: (context, ref, _) {
  final wallet = ref.watch(walletSummaryProvider);
  if (wallet == null) return const SizedBox.shrink();
  return PointsWalletCard(
    points: wallet.availablePoints,
    onTap: () => context.push('/community/wallet'),
    onWithdraw: wallet.canWithdraw ? () => context.push('/community/wallet/withdraw') : null,
  );
}),
// ReferralBannerCard below
```

### Business Dashboard
Insert ReferralBannerCard only (no wallet card):
- Copy: "Refer a business → earn 1 free month"

### Badge celebration listener in CommunityMainScreen
```dart
ref.listen<WalletState>(walletProvider, (prev, next) {
  if (next.newlyEarnedBadges.isNotEmpty) {
    _showBadgeCelebration(context, next.newlyEarnedBadges.first);
    ref.read(walletProvider.notifier).clearNewBadges();
  }
});
```

Commit: `feat(rewards): integrate wallet and referral cards into dashboards`

---

## Task 10: Collaboration Detail Nudge

**Files:**
- Modify: `lib/features/collaboration/screens/collaboration_detail_screen.dart`

At bottom of detail content, when `collaboration.status == completed`:
```dart
const CollaborationRewardNudge()
```

Only for community user type.

Commit: `feat(rewards): add reward nudge to collaboration detail`

---

## Task 11: Route Updates

**Files:**
- Modify: `lib/config/routes/routes.dart`

Add route constants:
```dart
static const communityWallet = '/community/wallet';
static const communityWalletWithdraw = '/community/wallet/withdraw';
```

Add GoRoute entries:
```dart
GoRoute(
  path: '/community/wallet',
  builder: (context, state) => const WalletScreen(),
  routes: [
    GoRoute(
      path: 'withdraw',
      builder: (context, state) => const WithdrawalRequestScreen(),
    ),
  ],
),
```

Replace `/community/referrals` placeholder with `ReferralScreen`.
Add `/business/referrals` route.

Commit: `feat(rewards): add wallet and referral routes`

---

## Task 12: Full Verification

- Run: `dart analyze lib/features/rewards/`
- Run: `dart analyze lib/` (full project)
- Fix any issues
- Verify file structure:

```
lib/features/rewards/
├── models/
│   ├── wallet_model.dart
│   ├── ledger_entry.dart
│   └── reward_badge.dart
├── services/
│   └── rewards_service.dart
├── providers/
│   └── wallet_provider.dart
├── screens/
│   ├── wallet_screen.dart
│   ├── withdrawal_request_screen.dart
│   └── referral_screen.dart
└── widgets/
    ├── points_progress_bar.dart
    ├── points_wallet_card.dart
    ├── reward_badge_card.dart
    ├── referral_banner_card.dart
    ├── badge_celebration_overlay.dart
    └── collaboration_reward_nudge.dart
```

Final commit: `feat(rewards): complete gamification rewards system`

---

## Summary

| Task | Files | Type |
|------|-------|------|
| 1 | pubspec.yaml | Modify |
| 2 | 3 model files | Create |
| 3 | 1 service file | Create |
| 4 | 1 provider file | Create |
| 5 | 6 widget files | Create |
| 6 | 1 screen file | Create |
| 7 | 1 screen file | Create |
| 8 | 1 screen file | Create |
| 9 | 2 dashboard files | Modify |
| 10 | 1 collaboration file | Modify |
| 11 | routes.dart | Modify |
| 12 | — | Verify |
| **Total** | **13 new, 5 modified** | |
