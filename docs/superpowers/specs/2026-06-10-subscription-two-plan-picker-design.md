# Subscription paywall — two-plan picker (monthly + 3-month)

> Date: 2026-06-10 · Owner: Volkan · Status: approved, implementing

## Goal

New pricing policy: **monthly €39.99** and **3-month €99.99** (≈ €33.33/mo, ~17 % off
vs 3× monthly). Update the subscription **modal** (`SubscriptionPaywall`) to offer both
plans with a selectable picker, **3-month selected by default** and badged as best value.

App Store Connect products already exist with these prices:
- `com.kolabing.kolabingApp.subscription.monthly` (existing, now €39.99)
- `com.kolabing.kolabingApp.subscription.three_months` (new, €99.99)

## Decisions (locked)

- **Two-plan picker, modal only.** The full `SubscriptionScreen` is NOT given the picker.
- **Default selected plan: 3-month** (highlighted, "best value").
- **iOS only matters.** Android/Stripe flow stays single-plan as today (fallback price
  text bumped 29 → 39.99). The picker renders on iOS where both products load.
- Prices/per-month/savings computed at runtime from `ProductDetails.rawPrice` +
  `currencySymbol` (no hardcoded numbers on iOS; ARB fallbacks only for non-iOS).
- Products created in App Store Connect manually — out of code scope. Code only queries IDs.

## Changes

### 1. `lib/features/subscription/services/iap_service.dart`
- Add `kBundleThreeMonthsSubscriptionId = 'com.kolabing.kolabingApp.subscription.three_months'`.
- Add `enum SubscriptionPlan { monthly, threeMonths }` with a product-id priority list +
  duration (months) per plan.
- Add `kSubscriptionProductIds` now includes monthly (existing variants) + three_months.
- Keep `monthlyProduct`; add `threeMonthsProduct` getter and `ProductDetails? productFor(plan)`.
- `purchaseSubscription({SubscriptionPlan plan = SubscriptionPlan.monthly, String? referralCode})`
  buys `productFor(plan)` instead of always `monthlyProduct`.

### 2. `lib/features/subscription/providers/iap_provider.dart`
- Expose `monthlyProduct` + `threeMonthsProduct` (+ availability) from state.
- `purchase({SubscriptionPlan plan = monthly, String? referralCode})` forwards the plan.
- Helper(s) for per-month-equivalent + savings-percent from rawPrice (nullable-safe).

### 3. `lib/features/subscription/widgets/subscription_paywall.dart`
- `SubscriptionPlan _selectedPlan = SubscriptionPlan.threeMonths;`
- Replace the single-price `Container` with a two-card plan picker (new private widget /
  helper in this file):
  - **Monthly**: `€39.99 / month`.
  - **3 months**: `€99.99 / 3 months`, "BEST VALUE" badge, `≈ €33.33/mo`, `Save 17%`.
  - Selected card highlighted (yellow border/fill); tap to select.
  - If only one product is available on iOS, fall back to single-plan display.
  - Non-iOS: single monthly display (fallback `39.99 EUR`) + existing Stripe flow.
- Subscribe button calls `purchase(plan: _selectedPlan)`; label may reflect selected price.

### 4. i18n — `lib/l10n/app_{en,es,ca}.arb` + `flutter gen-l10n`
New keys (en / es=Castilian / ca):
- `subscriptionPlanMonthlyLabel` — "Monthly" / "Mensual" / "Mensual"
- `subscriptionPlanThreeMonthsLabel` — "3 months" / "3 meses" / "3 mesos"
- `subscriptionPlanBestValueBadge` — "BEST VALUE" / "MEJOR PRECIO" / "MILLOR PREU"
- `subscriptionPlanPerMonthEq` (`{price}`) — "≈ {price}/mo" / "≈ {price}/mes" / "≈ {price}/mes"
- `subscriptionPlanSavePercent` (`{percent}`) — "Save {percent}%" / "Ahorra {percent}%" / "Estalvia {percent}%"
- `subscriptionPlanPer3Months` — "/ 3 months" / "/ 3 meses" / "/ 3 mesos"

Updated keys: `subscriptionPriceMonthly` 29→39.99 (also fixes the full screen's price
detail row); any "29" in subscribe-button strings → 39.99; the `'29 EUR'` literal
fallback in the paywall widget → `'39.99 EUR'`.

## Out of scope / notes
- `SubscriptionScreen` active-plan "Price" row shows the monthly price text regardless of
  the user's actual plan (plan not stored in the `Subscription` model / backend). Bumping
  the ARB string removes the stale €29; a true per-plan label needs a backend field — not
  done here.
- Analytics `subscription_started` already carries `product_id`, so plan is distinguishable
  with no extra work.

## Verification
- `flutter analyze` → 0 errors; `flutter test` green.
- iOS sim/device: modal shows both cards, 3-month preselected + badge + per-mo + savings;
  selecting monthly then subscribing buys the monthly product; restore still works.
- Confirm no remaining user-facing "29".
