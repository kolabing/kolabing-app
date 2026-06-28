# Business Kolab Flow — Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the business Kolab creation flow (venue & product promotion) so it's goal-first and offer-first, with dynamic admin-managed chip options instead of hardcoded lists, lighter media/availability requirements, and a listing-style review card — without touching the community-seeking flow's logic.

**Architecture:** Follows the existing `OfferOption`/`offerOptionServiceProvider` pattern exactly (`lib/features/kolab/services/offer_option_service.dart` + `lib/features/kolab/providers/offer_option_provider.dart` + `lib/features/kolab/models/offer_option.dart`) for every new dynamic chip list. The wizard gains one new step (Goal) inserted after the type-specific Details step; all later business-flow step indices shift by +1.

**Tech Stack:** Flutter, Riverpod (`Notifier`/`FutureProvider.autoDispose`), `http` package (no Dio in this codebase).

**Companion plan:** `docs/superpowers/plans/2026-06-24-business-kolab-flow-backend.md` in the `kolabing-v2` repo. Tasks 1, 6, and parts of 4/5/7 below depend on that plan's Tasks 1-8 (new `goal`/`highlights` columns, 4 new `OfferOption` kinds + lookup endpoints, expanded `deliverable` taxonomy, immediate-availability validation fix) being merged and deployed first — or at minimum running locally against a backend branch with those changes, since `OfferOptionService` self-gates to a 404 fallback only for *existing* slugs, not new ones.

## Global Constraints

- Do not change the community-seeking flow's screens or step count (stays 6 steps) — only shared widgets (`MultiSelectChips`, `_ToggleCard`-style patterns) may be reused, never modified in a way that changes community-flow behavior.
- Never hardcode a new chip option list in Dart when a backend lookup endpoint exists for it — follow the `offeringsProvider`/`venueTypesProvider` pattern (`FutureProvider.autoDispose<List<OfferOption>>` backed by a service method with a hardcoded fallback identical to the backend seeder defaults, per existing convention).
- `seeking_communities`, `expects`, `offering`, `past_events` payload keys are unchanged — only `goal` and `highlights` are new wire fields (additive).
- `venue_fit` and `product_interaction` selections are informational only — composed into the existing `description` text field client-side, never sent as their own payload key (per the backend plan's Task 4 decision).
- Run `flutter analyze` after each task; it must report no new issues in changed files.
- Do not run `flutter test` for the whole suite mid-plan unless a task specifically says to — run only the tests relevant to the task you just finished.

---

### Task 1: Extend `OfferOptionService`/`OfferOption` provider layer with the 4 new lookup kinds

**Files:**
- Modify: `lib/features/kolab/services/offer_option_service.dart`
- Modify: `lib/features/kolab/providers/offer_option_provider.dart`
- Test: `test/features/kolab/services/offer_option_service_test.dart` (create if no such test file exists yet — check first with `find test -iname "*offer_option*"`)

**Interfaces:**
- Produces: `OfferOptionService.getGoals()`, `.getProductInteractions()`, `.getVenueFits()`, `.getKolabHighlights()` — each `Future<List<OfferOption>>`. `goalsProvider`, `productInteractionsProvider`, `venueFitsProvider`, `kolabHighlightsProvider` — each `FutureProvider.autoDispose<List<OfferOption>>`.

- [ ] **Step 1: Add the 4 service methods + fallback constants** to `offer_option_service.dart`, mirroring `getVenueTypes()`/`_fallbackVenueTypes` exactly:

```dart
  Future<List<OfferOption>> getGoals() =>
      _fetch('lookup/goals', _fallbackGoals);

  Future<List<OfferOption>> getProductInteractions() =>
      _fetch('lookup/product-interactions', _fallbackProductInteractions);

  Future<List<OfferOption>> getVenueFits() =>
      _fetch('lookup/venue-fits', _fallbackVenueFits);

  Future<List<OfferOption>> getKolabHighlights() =>
      _fetch('lookup/kolab-highlights', _fallbackKolabHighlights);
```

Add these fallback lists in the "Hardcoded fallbacks" section, slugs identical to the backend `OfferOptionSeeder` additions from the companion backend plan's Task 6:

```dart
  static const List<OfferOption> _fallbackGoals = [
    OfferOption(id: 'more_visits', slug: 'more_visits', name: 'More Visits'),
    OfferOption(id: 'product_awareness', slug: 'product_awareness', name: 'Product Awareness'),
    OfferOption(id: 'content_tagged_posts', slug: 'content_tagged_posts', name: 'Content / Tagged Posts'),
    OfferOption(id: 'reviews', slug: 'reviews', name: 'Reviews'),
    OfferOption(id: 'sales_revenue', slug: 'sales_revenue', name: 'Sales / Revenue'),
    OfferOption(id: 'community_event', slug: 'community_event', name: 'Community Event'),
    OfferOption(id: 'product_testing', slug: 'product_testing', name: 'Product Testing'),
    OfferOption(id: 'recurring_partnership', slug: 'recurring_partnership', name: 'Recurring Partnership'),
    OfferOption(id: 'community_perk', slug: 'community_perk', name: 'Community Perk / Member Discount'),
    OfferOption(id: 'open_to_ideas', slug: 'open_to_ideas', name: 'Open to Ideas'),
  ];

  static const List<OfferOption> _fallbackProductInteractions = [
    OfferOption(id: 'try_samples', slug: 'try_samples', name: 'Try Samples'),
    OfferOption(id: 'review_it', slug: 'review_it', name: 'Review It'),
    OfferOption(id: 'create_content', slug: 'create_content', name: 'Create Content'),
    OfferOption(id: 'use_during_event', slug: 'use_during_event', name: 'Use During an Event'),
    OfferOption(id: 'give_feedback', slug: 'give_feedback', name: 'Give Feedback'),
    OfferOption(id: 'giveaway', slug: 'giveaway', name: 'Offer as a Giveaway'),
    OfferOption(id: 'discount_code', slug: 'discount_code', name: 'Promote a Discount Code'),
    OfferOption(id: 'sell_during_event', slug: 'sell_during_event', name: 'Sell During an Event'),
    OfferOption(id: 'open_to_ideas', slug: 'open_to_ideas', name: 'Open to Ideas'),
  ];

  static const List<OfferOption> _fallbackVenueFits = [
    OfferOption(id: 'coffee', slug: 'coffee', name: 'Coffee'),
    OfferOption(id: 'brunch', slug: 'brunch', name: 'Brunch'),
    OfferOption(id: 'dinner', slug: 'dinner', name: 'Dinner'),
    OfferOption(id: 'drinks', slug: 'drinks', name: 'Drinks'),
    OfferOption(id: 'wellness', slug: 'wellness', name: 'Wellness'),
    OfferOption(id: 'shopping', slug: 'shopping', name: 'Shopping'),
    OfferOption(id: 'workshops', slug: 'workshops', name: 'Workshops'),
    OfferOption(id: 'content', slug: 'content', name: 'Content'),
    OfferOption(id: 'after_run', slug: 'after_run', name: 'After-Run'),
    OfferOption(id: 'after_work', slug: 'after_work', name: 'After-Work'),
    OfferOption(id: 'networking', slug: 'networking', name: 'Networking'),
    OfferOption(id: 'pop_ups', slug: 'pop_ups', name: 'Pop-Ups'),
    OfferOption(id: 'recurring_plans', slug: 'recurring_plans', name: 'Recurring Plans'),
  ];

  static const List<OfferOption> _fallbackKolabHighlights = [
    OfferOption(id: 'good_location', slug: 'good_location', name: 'Good Location'),
    OfferOption(id: 'nice_space_for_groups', slug: 'nice_space_for_groups', name: 'Nice Space for Groups'),
    OfferOption(id: 'great_photo_spot', slug: 'great_photo_spot', name: 'Great Photo Spot'),
    OfferOption(id: 'healthy_sporty_offer', slug: 'healthy_sporty_offer', name: 'Healthy / Sporty Offer'),
    OfferOption(id: 'free_samples', slug: 'free_samples', name: 'Free Samples'),
    OfferOption(id: 'discount_for_members', slug: 'discount_for_members', name: 'Discount for Members'),
    OfferOption(id: 'good_for_after_work', slug: 'good_for_after_work', name: 'Good for After-Work Plans'),
    OfferOption(id: 'good_after_workout', slug: 'good_after_workout', name: 'Good After a Workout'),
    OfferOption(id: 'recurring_kolabs', slug: 'recurring_kolabs', name: 'Can Host Recurring Kolabs'),
    OfferOption(id: 'unique_experience', slug: 'unique_experience', name: 'Unique Experience'),
    OfferOption(id: 'new_product_to_try', slug: 'new_product_to_try', name: 'New Product to Try'),
    OfferOption(id: 'premium_experience', slug: 'premium_experience', name: 'Premium Experience'),
    OfferOption(id: 'easy_public_transport', slug: 'easy_public_transport', name: 'Easy to Reach by Public Transport'),
    OfferOption(id: 'outdoor_friendly', slug: 'outdoor_friendly', name: 'Outdoor-Friendly'),
    OfferOption(id: 'cozy_indoor_space', slug: 'cozy_indoor_space', name: 'Cozy Indoor Space'),
    OfferOption(id: 'good_for_content', slug: 'good_for_content', name: 'Good for Content'),
  ];
```

- [ ] **Step 2: Add the 4 providers** to `offer_option_provider.dart`:

```dart
/// "Goal" options — what a business Kolab is meant to achieve. From
/// `GET /lookup/goals`.
final goalsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getGoals(),
);

/// "Product interaction" options — how communities can engage with a product
/// promotion. From `GET /lookup/product-interactions`.
final productInteractionsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getProductInteractions(),
);

/// "Venue fit" options — the venue-promotion "Best for:" chips. From
/// `GET /lookup/venue-fits`.
final venueFitsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getVenueFits(),
);

/// "Kolab highlight" options — "Why communities will like this" chips. From
/// `GET /lookup/kolab-highlights`.
final kolabHighlightsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getKolabHighlights(),
);
```

- [ ] **Step 3: Check for an existing service test file**

Run: `find test -iname "*offer_option*"`

If a test file exists, read it and add 4 parameterized cases for the new methods following its exact existing pattern (likely mocking `http.Client` and asserting fallback-on-404 + happy-path parsing). If none exists, skip writing a new one — this mirrors the existing untested-service convention; do not introduce a new test pattern unilaterally for this one file.

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze lib/features/kolab/services/offer_option_service.dart lib/features/kolab/providers/offer_option_provider.dart`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/features/kolab/services/offer_option_service.dart lib/features/kolab/providers/offer_option_provider.dart
git commit -m "feat: add goal, product-interaction, venue-fit, kolab-highlight lookup providers"
```

---

### Task 2: Extend the `Kolab` model with `goal` and `highlights`

**Files:**
- Modify: `lib/features/kolab/models/kolab.dart` (constructor, fields, `fromJson`, `toJson`, `copyWith`, `empty()`)
- Test: `test/features/kolab/models/kolab_test.dart` (check `find test -iname "kolab_test.dart"` first; extend if it exists, otherwise add assertions inline in whichever existing model test covers `offerHeadline`/`baseOffer` round-tripping)

**Interfaces:**
- Produces: `Kolab.goal` (`String?`), `Kolab.highlights` (`List<String>`, defaults to `const []`) — both serialized to/from `goal`/`highlights` JSON keys, both included in `copyWith`.

- [ ] **Step 1: Read the current `Kolab` class in full**

Run: `grep -n "offerHeadline\|baseOffer\|clearOfferHeadline\|clearBaseOffer" lib/features/kolab/models/kolab.dart`

This locates every place `offerHeadline`/`baseOffer` appear (constructor param, field declaration, `fromJson` parse, `toJson` emit, `copyWith` param + `clear*` flag, `empty()` default) — `goal` and `highlights` must be added in the exact same positions, following the exact same nullable-string-with-`clear*`-flag pattern for `goal`, and the exact same `List<String>`-defaulting-to-`const []` pattern already used for `seekingCommunities`/`offering` for `highlights` (no `clear*` flag needed for a list field — confirm by checking how `offering`/`seekingCommunities` are handled in `copyWith`, which take a plain `List<String>?` with `?? this.offering` fallback, no separate clear flag).

- [ ] **Step 2: Add the field declarations** (next to `offerHeadline`/`baseOffer`, in the "Phase 5 discovery & matching" section per `kolab.dart:469-475`):

```dart
  final String? offerHeadline;
  final String? baseOffer;
  final String? goal;
  final List<String> highlights;
  final List<NegotiationTrigger> negotiationTriggers;
```

- [ ] **Step 3: Add to the constructor** (mirroring how `offerHeadline`/`baseOffer` are declared as named constructor params, and `highlights` mirroring `offering`'s `this.offering = const []` default):

```dart
    this.offerHeadline,
    this.baseOffer,
    this.goal,
    this.highlights = const [],
```

- [ ] **Step 4: Add to `fromJson`** (next to `offerHeadline`/`baseOffer` parsing, `kolab.dart:395-396`):

```dart
    offerHeadline: json['offer_headline']?.toString(),
    baseOffer: json['base_offer']?.toString(),
    goal: json['goal']?.toString(),
    highlights: json['highlights'] is List
        ? (json['highlights'] as List).map((e) => e.toString()).toList()
        : const [],
```

- [ ] **Step 5: Add to `toJson`** (next to `offer_headline`/`base_offer` emission, `kolab.dart:532-534`):

```dart
    if (offerHeadline != null && offerHeadline!.isNotEmpty)
      'offer_headline': offerHeadline,
    if (baseOffer != null && baseOffer!.isNotEmpty) 'base_offer': baseOffer,
    if (goal != null && goal!.isNotEmpty) 'goal': goal,
    if (highlights.isNotEmpty) 'highlights': highlights,
```

- [ ] **Step 6: Add to `copyWith`** — find the `copyWith` method signature and body (it will have a `String? offerHeadline`, `bool clearOfferHeadline = false` pair). Add:

```dart
    String? goal,
    bool clearGoal = false,
    List<String>? highlights,
```

and in the body's returned `Kolab(...)`:

```dart
      goal: clearGoal ? null : (goal ?? this.goal),
      highlights: highlights ?? this.highlights,
```

- [ ] **Step 7: Check `Kolab.empty()` factory** — if it explicitly lists every field (vs. relying on constructor defaults), add `goal: null, highlights: const [],` there too; if it just calls the constructor with minimal required args, no change needed since Step 3's defaults cover it.

- [ ] **Step 8: Write/extend a round-trip test**

```dart
test('goal and highlights round-trip through toJson/fromJson', () {
  final kolab = Kolab.empty(IntentType.venuePromotion).copyWith(
    goal: 'more_visits',
    highlights: ['good_location', 'free_samples'],
  );

  final json = kolab.toJson();
  expect(json['goal'], 'more_visits');
  expect(json['highlights'], ['good_location', 'free_samples']);

  final parsed = Kolab.fromJson(json);
  expect(parsed.goal, 'more_visits');
  expect(parsed.highlights, ['good_location', 'free_samples']);
});

test('goal and highlights default to null/empty and are omitted from toJson', () {
  final kolab = Kolab.empty(IntentType.venuePromotion);

  expect(kolab.goal, isNull);
  expect(kolab.highlights, isEmpty);
  expect(kolab.toJson().containsKey('goal'), isFalse);
  expect(kolab.toJson().containsKey('highlights'), isFalse);
});
```

Add these to whichever existing test file covers `Kolab` serialization (found via Step-0 search); if none exists, create `test/features/kolab/models/kolab_test.dart` with a minimal `group('Kolab goal/highlights', () { ... })` wrapping just these two tests — do not write a full new `Kolab` test suite as part of this task.

- [ ] **Step 9: Run the test**

Run: `flutter test test/features/kolab/models/kolab_test.dart` (or whatever file Step 8 targeted)
Expected: PASS

- [ ] **Step 10: Run static analysis + commit**

```bash
flutter analyze lib/features/kolab/models/kolab.dart
git add lib/features/kolab/models/kolab.dart test/features/kolab/models/
git commit -m "feat: add goal and highlights fields to Kolab model"
```

---

### Task 3: Insert the new Goal step into the business wizard

**Files:**
- Create: `lib/features/kolab/screens/business/goal_screen.dart`
- Modify: `lib/features/kolab/enums/intent_type.dart:45-54` (`totalSteps`)
- Modify: `lib/features/kolab/screens/kolab_flow_screen.dart:248-269` (`_buildStepContent` switch cases)
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (`updateGoal` method + step-index shift in `_validateVenuePromotionStep`/`_validateProductPromotionStep`)
- Test: `test/features/kolab/screens/business/goal_screen_test.dart` (new — follow the widget-test pattern of an existing screen test if one exists; check `find test -path "*kolab*" -iname "*_test.dart"` first)

**Interfaces:**
- Consumes: `goalsProvider` (Task 1), `Kolab.goal`/`KolabFormNotifier` (Task 2).
- Produces: `KolabFormNotifier.updateGoal(String? goal)`. New step is index 1 in both venue and product flows (after Details at index 0, before Media which moves from index 1 to index 2). `IntentType.venuePromotion`/`.productPromotion` `totalSteps` becomes 8 (was 7); `communitySeeking` stays 6.

- [ ] **Step 1: Bump `totalSteps`**

```dart
  /// Total number of steps in the creation flow for this intent type.
  int get totalSteps {
    switch (this) {
      case IntentType.communitySeeking:
        return 6;
      case IntentType.venuePromotion:
        return 8;
      case IntentType.productPromotion:
        return 8;
    }
  }
```

- [ ] **Step 2: Create the Goal screen**, following `IdealCommunityScreen`'s structure (`ConsumerStatefulWidget`, `ListView`, section header, `MultiSelectChips`-style single-select). Since this is a single-select (not multi), build it directly rather than misusing `MultiSelectChips` (which has no single-select mode):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/category_icon.dart';
import '../../models/offer_option.dart';
import '../../providers/kolab_form_provider.dart';
import '../../providers/offer_option_provider.dart';

/// Step 1 (venue / product flows): "WHAT DO YOU WANT THIS KOLAB TO ACHIEVE?"
///
/// Single-select goal chip list, admin-managed via /lookup/goals. Helps
/// communities understand the opportunity and is shown as a badge on Review.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(kolabFormProvider);
    final notifier = ref.read(kolabFormProvider.notifier);
    final goalOptionsAsync = ref.watch(goalsProvider);
    final selectedGoal = formState.kolab.goal;
    final errors = formState.fieldErrors;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        Text(
          'GOAL',
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'What do you want this Kolab to achieve?',
          style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.onSurface),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Pick the main goal. This helps communities understand the opportunity.',
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (errors.containsKey('goal'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['goal']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
            ),
          ),

        ...goalOptionsAsync
            .when(
              data: (options) => options,
              loading: () => const <OfferOption>[],
              error: (_, _) => const <OfferOption>[],
            )
            .map((option) {
          final isSelected = selectedGoal == option.slug;
          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: GestureDetector(
              onTap: () => notifier.updateGoal(option.slug),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(KolabingSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.softYellow : context.colors.surface,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? context.colors.primary : context.colors.darkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? context.colors.primary : context.colors.darkBorder,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(LucideIcons.check, size: 14, color: context.colors.onPrimary)
                          : null,
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    CategoryIcon(name: option.name, iconUrl: option.iconUrl, size: 24),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Text(
                        option.name,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        if (goalOptionsAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
```

(Verify `CategoryIcon`'s exact constructor params by checking its use in `offering_screen.dart:507` — it's used there as `CategoryIcon(name: iconName, iconUrl: iconUrl, size: 24)`, matching what's used above.)

- [ ] **Step 3: Add `updateGoal` to `KolabFormNotifier`** (next to `updateOfferHeadline`/`updateBaseOffer` in `kolab_form_provider.dart`, around line 277-289):

```dart
  /// New goal step: what the Kolab is meant to achieve, shown as a badge on
  /// Review.
  void updateGoal(String? goal) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        goal: goal,
        clearGoal: goal == null,
      ),
      clearError: true,
    );
  }
```

- [ ] **Step 4: Wire the screen into `KolabFlowScreen._buildStepContent`** — insert as the new index 1, shifting every subsequent business-flow case by +1:

```dart
      case IntentType.venuePromotion:
        return switch (step) {
          0 => const VenueDetailsScreen(),
          1 => const GoalScreen(),
          2 => const MediaScreen(),
          3 => const OfferingScreen(),
          4 => const IdealCommunityScreen(),
          5 => const PastEventsScreen(),
          6 => const AvailabilityScreen(),
          7 => const business_review.ReviewScreen(),
          _ => const SizedBox(),
        };
      case IntentType.productPromotion:
        return switch (step) {
          0 => const ProductDetailsScreen(),
          1 => const GoalScreen(),
          2 => const MediaScreen(),
          3 => const OfferingScreen(),
          4 => const IdealCommunityScreen(),
          5 => const PastEventsScreen(),
          6 => const AvailabilityScreen(),
          7 => const business_review.ReviewScreen(),
          _ => const SizedBox(),
        };
```

Add the import: `import 'business/goal_screen.dart';` alongside the other `business/*_screen.dart` imports at the top of `kolab_flow_screen.dart`.

- [ ] **Step 5: Shift validator step indices** in `kolab_form_provider.dart`'s `_validateVenuePromotionStep` and `_validateProductPromotionStep` — every `case N:` for N ≥ 1 increases by 1, and a new `case 1:` (no required validation — Goal is encouraged but not blocking, per "do not block aggressively") is inserted. For `_validateVenuePromotionStep`:

```dart
  void _validateVenuePromotionStep(
    int step,
    Kolab kolab,
    Map<String, String> errors,
  ) {
    switch (step) {
      case 0: // Campaign copy only — venue meta inherited from onboarding profile
        if (kolab.title.isEmpty) {
          errors['title'] = 'Title is required';
        }
        if (kolab.description.isEmpty) {
          errors['description'] = 'Description is required';
        }
        // H2: offer headline is required on venue promotion.
        if (kolab.offerHeadline == null ||
            kolab.offerHeadline!.trim().isEmpty) {
          errors['offer_headline'] =
              'Add a one-line offer headline (e.g. "20% off Tuesdays")';
        }
      case 1: // Goal (optional — encouraged, not blocking)
        break;
      case 2: // Media
        if (kolab.media.isEmpty) {
          errors['media'] = 'Add at least 1 photo';
        }
      case 3: // What you offer
        if (kolab.offering.isEmpty) {
          errors['offering'] = 'Select at least 1 offering';
        }
      case 4: // Seeking communities
        // No required validation
        break;
      case 5: // Expectations
        // No required validation
        break;
      case 6: // Availability
        if (kolab.availabilityMode == null) {
          errors['availability_mode'] = 'Select an availability mode';
        } else if (kolab.availabilityStart == null) {
          errors['availability_start'] =
              'Pick a start date for your availability window';
        } else {
          final today = DateUtils.dateOnly(DateTime.now());
          final start = DateUtils.dateOnly(kolab.availabilityStart!);
          if (start.isBefore(today)) {
            errors['availability_start'] = 'Start date cannot be in the past';
          }
        }
      case 7: // Review
        // Review step has no additional validation
        break;
    }
  }
```

Apply the identical shift (case numbers +1 from index 1 onward, new no-op `case 1:` for Goal) to `_validateProductPromotionStep`.

**Note on Task 7's availability-immediate-mode validation change:** this task only shifts the case index from `5` to `6` — the actual logic change (allowing today when mode is `immediate`) is made in Task 7 below, not here. Don't conflate the two.

- [ ] **Step 6: Write a widget test** for the new screen, following whatever pattern an existing kolab screen test uses (check `find test -path "*kolab*" -iname "*_test.dart"` for a template). At minimum:

```dart
testWidgets('GoalScreen shows fallback goal options and selecting one updates the provider', (tester) async {
  // Pump within a ProviderScope with kolabFormProvider already seeded to
  // IntentType.venuePromotion (mirror however the existing offering_screen
  // or ideal_community_screen widget test — if any — sets up its
  // ProviderScope/container before pumping).
  // ... follow that exact harness pattern; assert that tapping the
  // "More Visits" fallback chip calls notifier.updateGoal('more_visits')
  // and the Kolab state reflects it.
});
```

If no existing widget-test harness exists for any kolab business screen, skip the widget test for this task (don't introduce a new test infrastructure pattern unilaterally) and rely on Task 2's model test + manual verification per the Manual Test Checklist in Task 9.

- [ ] **Step 7: Run static analysis**

Run: `flutter analyze lib/features/kolab/`
Expected: No issues found.

- [ ] **Step 8: Commit**

```bash
git add lib/features/kolab/screens/business/goal_screen.dart lib/features/kolab/enums/intent_type.dart lib/features/kolab/screens/kolab_flow_screen.dart lib/features/kolab/providers/kolab_form_provider.dart test/features/kolab/
git commit -m "feat: add Goal step to business Kolab creation flow"
```

---

### Task 4: Reorder the Offering step (headline-first, offer-first) + expand "what would you like from the community"

**Files:**
- Modify: `lib/features/kolab/screens/business/offering_screen.dart`
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (no new methods needed — `updateOfferHeadline`/`updateBaseOffer`/`toggleExpect` already exist; this task is screen-layout only)

**Interfaces:**
- Consumes: `kolab.offerHeadline`, `kolab.baseOffer`, `kolab.expects` (existing), `deliverablesProvider` (existing, already returns the expanded list once the backend plan's Task 6 seeder runs).

- [ ] **Step 1: Add an `_offerHeadlineController` and move headline + base-offer to the top of the `ListView`**, before the offering toggle cards. The current `_OfferingScreenState` only has `_baseOfferController`; add a sibling controller and sync it the same way:

```dart
class _OfferingScreenState extends ConsumerState<OfferingScreen> {
  final _offerHeadlineController = TextEditingController();
  final _baseOfferController = TextEditingController();
  bool _didInit = false;

  @override
  void dispose() {
    _offerHeadlineController.dispose();
    _baseOfferController.dispose();
    super.dispose();
  }

  void _syncControllers(Kolab kolab) {
    if (_didInit) return;
    _didInit = true;
    _offerHeadlineController.text = kolab.offerHeadline ?? '';
    _baseOfferController.text = kolab.baseOffer ?? '';
  }
```

- [ ] **Step 2: Reorder the `build()` method's `children` list.** Replace the current structure (offering toggle cards → base offer → negotiation triggers) with: offer headline (new, top, visually primary) → base offer (relabeled as the main offer, required) → offering toggle cards (kept, but now secondary) → "what would you like from the community" (new section using `deliverablesProvider` + `expects`) → negotiation triggers (unchanged, kept at the bottom). Insert this block as the very first children entries, before the existing `Text(l10n.offeringTitle, ...)` header:

```dart
        // -- Offer headline (H2): visually primary, required, top of the step.
        Text(
          'OFFER HEADLINE',
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'What are you offering?',
          style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.onSurface),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'The clearer the offer, the easier it is for communities to say yes.',
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),
        if (errors.containsKey('offer_headline'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['offer_headline']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
            ),
          ),
        KolabingInput(
          controller: _offerHeadlineController,
          maxLength: 50,
          hint: 'e.g. "Free coffee tasting for 20 runners"',
          onChanged: notifier.updateOfferHeadline,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Main offer (was "base offer", now framed as the primary public offer).
        _SectionLabel(label: 'YOUR OFFER'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Describe what you can offer in your own words.',
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _baseOfferController,
          maxLength: 400,
          maxLines: 3,
          hint: 'e.g. "We can offer free coffee and pastries for up to 20 people after a morning run."',
          onChanged: notifier.updateBaseOffer,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.lg),
```

Then keep the existing offering-toggle-cards block (unchanged code, just now positioned after the above instead of first), followed by a new "what would you like from the community" section before the existing negotiation-triggers block:

```dart
        // -- What would you like from the community?
        _SectionLabel(label: 'WHAT WOULD YOU LIKE FROM THE COMMUNITY?'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'You can choose more than one. This is not a strict contract yet — '
          'it helps communities understand your expectations.',
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        MultiSelectChips<OfferOption>(
          items: ref.watch(deliverablesProvider).when(
                data: (options) => options,
                loading: () => const <OfferOption>[],
                error: (_, _) => const <OfferOption>[],
              ),
          selected: kolab.expects
              .map((d) => OfferOption(id: d.toApiValue(), slug: d.toApiValue(), name: d.displayName))
              .toList(),
          labelBuilder: (o) => o.name,
          onToggle: (option) => notifier.toggleExpect(DeliverableType.fromString(option.slug)),
        ),
        const SizedBox(height: KolabingSpacing.md),
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.softYellow,
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
          child: Text(
            'Tip: good Kolabs usually include a clear perk for the community — '
            'free samples, a discount, a space, an experience, content, or '
            'something members will actually enjoy.',
            style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurface, height: 1.4),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
```

Verify `DeliverableType` has a `fromString` factory and `toApiValue()`/`displayName` getters by reading `lib/features/kolab/enums/deliverable_type.dart` (it's already used elsewhere in `ideal_community_screen.dart` for `.displayName`/`.subtitle`, and `kolab.dart` already calls `DeliverableType.fromString(e.toString())` in its `fromJson`, confirming both exist).

- [ ] **Step 3: Add the new imports** at the top of `offering_screen.dart`: `import '../../enums/deliverable_type.dart';` and `import '../../widgets/multi_select_chips.dart';` (check they're not already imported before adding — `offering_screen.dart` currently imports neither).

- [ ] **Step 4: Update `KolabFormNotifier._validateVenuePromotionStep`/`_validateProductPromotionStep`'s offering-step case** (now index 3 after Task 3's shift) to also require `baseOffer`, per the spec's "make `baseOffer` required or clearly explain when optional" decision — since `offer_headline` is already required at the Details step (index 0), and the spec wants the *main offer* clearly required too:

```dart
      case 3: // What you offer
        if (kolab.offering.isEmpty) {
          errors['offering'] = 'Select at least 1 offering';
        }
        if (kolab.baseOffer == null || kolab.baseOffer!.trim().isEmpty) {
          errors['base_offer'] = 'Describe your offer so communities know what to expect';
        }
```

Apply identically in `_validateProductPromotionStep`.

- [ ] **Step 5: Run static analysis**

Run: `flutter analyze lib/features/kolab/screens/business/offering_screen.dart lib/features/kolab/providers/kolab_form_provider.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/kolab/screens/business/offering_screen.dart lib/features/kolab/providers/kolab_form_provider.dart
git commit -m "feat: make offer headline and main offer primary, expand community-ask options"
```

---

### Task 5: Best-fit communities — dynamic chips + copy + venue-fit / product-interaction chips

**Files:**
- Modify: `lib/features/kolab/screens/business/ideal_community_screen.dart`
- Modify: `lib/features/kolab/screens/business/venue_details_screen.dart` (add "Best for:" chips)
- Modify: `lib/features/kolab/screens/business/product_details_screen.dart` (add product-interaction chips)
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (no new state field needed for venue-fit/product-interaction — see Step 4)

**Interfaces:**
- Consumes: an existing `communityTypesProvider`-equivalent if found in Step 1 below, or a new one created in this task; `venueFitsProvider`/`productInteractionsProvider` (Task 1).

- [ ] **Step 1: Check whether a community-types Riverpod provider already exists** (the lookup endpoint `/lookup/community-types` is already used by `lib/features/onboarding/services/onboarding_service.dart#getCommunityTypes()` per the earlier audit):

Run: `grep -rn "communityTypesProvider\|getCommunityTypes" lib/`

If a `FutureProvider`-style wrapper already exists (e.g. in `lib/features/onboarding/providers/onboarding_provider.dart`), reuse it directly in this screen. If only the raw service method exists with no provider wrapper, add one in `lib/features/onboarding/providers/onboarding_provider.dart` following the exact `FutureProvider.autoDispose` pattern from Task 1:

```dart
final communityTypesLookupProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(onboardingServiceProvider).getCommunityTypes(),
);
```

(Adjust the return type to match whatever model `getCommunityTypes()` already returns — it may return a different model than `OfferOption`, e.g. a `CommunityType`-shaped class; in that case keep that model and adapt the chip-building code in Step 2 to use `.slug`/`.name`-equivalent fields on whatever type it actually is, rather than forcing it into `OfferOption`.)

- [ ] **Step 2: Replace the hardcoded `_communityTypes` list** in `ideal_community_screen.dart` with the dynamic provider from Step 1:

```dart
// TODO(admin-taxonomy): community types are already admin-managed via the
// existing /lookup/community-types endpoint (shared with onboarding) — no
// further taxonomy work needed here, this just stops re-hardcoding the list
// client-side.
```

Remove the `static const List<String> _communityTypes = [...]` block entirely. Replace the `MultiSelectChips<String>` usage:

```dart
          // -- Community type chips
          Builder(builder: (context) {
            final communityTypesAsync = ref.watch(communityTypesLookupProvider);
            final types = communityTypesAsync.when(
              data: (options) => options.map((o) => o.name).toList(),
              loading: () => const <String>[],
              error: (_, _) => const <String>[],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MultiSelectChips<String>(
                  items: types,
                  selected: kolab.seekingCommunities,
                  labelBuilder: (t) => t,
                  onToggle: notifier.toggleSeekingCommunity,
                  maxSelect: 5,
                ),
                if (communityTypesAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          }),
```

(If Step 1 revealed `getCommunityTypes()` returns slugs distinct from display names, use `.slug` for the value stored in `seekingCommunities` and `.name` only for `labelBuilder` — check how `offering_screen.dart` stores `option.slug` vs. displays `option.name` and mirror that distinction here. The current hardcoded list stores plain display strings directly, so confirm with the team/spec intent whether `seeking_communities` should now store slugs instead — if changing the stored value's shape would be a breaking change to existing `seeking_communities` data, keep storing `.name` to preserve the wire format, only changing where the option list comes from.)

- [ ] **Step 3: Update the screen's copy** — replace the section header and subtitle:

```dart
          Text(
            'BEST-FIT COMMUNITIES',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          Text(
            'Who would this Kolab be perfect for?',
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Choose a few. This helps the right communities understand the opportunity faster.',
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.md),
```

(Replaces the old `'IDEAL COMMUNITY'` / `'What kind of communities would be a great fit?'` text block — read the surrounding code first since this plan shows the replacement text but the exact `Text(...)` widgets it replaces are at `ideal_community_screen.dart:92-101` per the file content already captured earlier in this plan's research.)

- [ ] **Step 4: Add "Best for:" chips to `venue_details_screen.dart`** (informational only — composed into `description`, per the Global Constraints decision). Read the file first, then add, near the existing description/details input:

```dart
        const SizedBox(height: KolabingSpacing.lg),
        _SectionLabel(label: 'BEST FOR:'),
        const SizedBox(height: KolabingSpacing.xs),
        Builder(builder: (context) {
          final venueFitsAsync = ref.watch(venueFitsProvider);
          final options = venueFitsAsync.when(
            data: (options) => options,
            loading: () => const <OfferOption>[],
            error: (_, _) => const <OfferOption>[],
          );
          return MultiSelectChips<OfferOption>(
            items: options,
            selected: _selectedVenueFits,
            labelBuilder: (o) => o.name,
            onToggle: (option) {
              setState(() {
                if (_selectedVenueFits.contains(option)) {
                  _selectedVenueFits.remove(option);
                } else {
                  _selectedVenueFits.add(option);
                }
              });
              _appendVenueFitsToDescription(notifier, kolab);
            },
          );
        }),
```

Add local state to the screen's `State` class: `final List<OfferOption> _selectedVenueFits = [];` and a helper that appends the selected labels to the description text the business is already writing, without clobbering what they typed:

```dart
  void _appendVenueFitsToDescription(KolabFormNotifier notifier, Kolab kolab) {
    final base = kolab.description.split('\n\nBest for:').first.trim();
    if (_selectedVenueFits.isEmpty) {
      notifier.updateDescription(base);
      return;
    }
    final fitLabels = _selectedVenueFits.map((o) => o.name).join(', ');
    notifier.updateDescription('$base\n\nBest for: $fitLabels');
  }
```

(This is a pragmatic, minimal way to keep "Best for:" informational and additive without a new payload key — read `venue_details_screen.dart`'s actual current description-handling code first, since the exact controller/notifier wiring there needs to match its existing `_descriptionController`/`onChanged` pattern rather than being guessed; adapt the snippet above to whatever that pattern already is, e.g. it may already debounce or trim differently.)

- [ ] **Step 5: Mirror Step 4's pattern in `product_details_screen.dart`** using `productInteractionsProvider` instead, with the question "How do you want communities to interact with your product?" and the same description-append approach, using a distinct marker (e.g. `'\n\nInteraction:'`) so it doesn't collide with venue's `'Best for:'` marker (these two screens are mutually exclusive per intent type, but keep the markers distinct for clarity/future-proofing).

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze lib/features/kolab/screens/business/`
Expected: No issues found.

- [ ] **Step 7: Commit**

```bash
git add lib/features/kolab/screens/business/ideal_community_screen.dart lib/features/kolab/screens/business/venue_details_screen.dart lib/features/kolab/screens/business/product_details_screen.dart lib/features/onboarding/providers/onboarding_provider.dart
git commit -m "feat: dynamic best-fit community chips, venue-fit and product-interaction chips"
```

---

### Task 6: "Past Events" → "Why communities will like this"

**Files:**
- Modify: `lib/features/kolab/screens/business/past_events_screen.dart`
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (`updateHighlights`/`toggleHighlight` + free-text handling)

**Interfaces:**
- Consumes: `kolabHighlightsProvider` (Task 1), `Kolab.highlights` (Task 2).
- Produces: `KolabFormNotifier.toggleHighlight(String slug)`.

- [ ] **Step 1: Read `past_events_screen.dart` in full** before editing — this plan was not able to capture its exact current content; do not guess at its existing controller/state structure. Identify: the section header/subtitle Text widgets to relabel, the existing past-event-entry list UI to keep (reframe only — don't remove fields), and where to insert the new highlights section.

- [ ] **Step 2: Relabel the header/subtitle** to:

```dart
        Text(
          'WHY COMMUNITIES WILL LIKE THIS',
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Add a few reasons that make your Kolab attractive.',
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),
```

(Replace whatever existing "Past Events"/"Past Collaborations" header Step 1 found, in-place, same widget tree position.)

- [ ] **Step 3: Add the highlights multi-select**, before the existing past-event-entries list:

```dart
        Builder(builder: (context) {
          final highlightsAsync = ref.watch(kolabHighlightsProvider);
          final options = highlightsAsync.when(
            data: (options) => options,
            loading: () => const <OfferOption>[],
            error: (_, _) => const <OfferOption>[],
          );
          return MultiSelectChips<OfferOption>(
            items: options,
            selected: kolab.highlights
                .map((slug) => options.firstWhere(
                      (o) => o.slug == slug,
                      orElse: () => OfferOption(id: slug, slug: slug, name: slug),
                    ))
                .toList(),
            labelBuilder: (o) => o.name,
            onToggle: (option) => notifier.toggleHighlight(option.slug),
          );
        }),
        const SizedBox(height: KolabingSpacing.lg),
```

Add the matching imports: `import '../../models/offer_option.dart';`, `import '../../providers/offer_option_provider.dart';`, `import '../../widgets/multi_select_chips.dart';` (only add whichever of these three aren't already imported — check first).

- [ ] **Step 4: Add `toggleHighlight` to `KolabFormNotifier`** (next to `toggleExpect`, in `kolab_form_provider.dart`):

```dart
  void toggleHighlight(String slug) {
    final list = List<String>.from(state.kolab.highlights);
    if (list.contains(slug)) {
      list.remove(slug);
    } else {
      list.add(slug);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(highlights: list),
      clearError: true,
    );
  }
```

- [ ] **Step 5: Add the optional "Anything else communities should know?" free-text field**, after the highlights chips and before the (reframed, kept) past-event-entries list:

```dart
        _SectionLabel(label: 'ANYTHING ELSE COMMUNITIES SHOULD KNOW? (OPTIONAL)'),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: _extraNotesController,
          maxLength: 500,
          maxLines: 3,
          hint: 'e.g. "We have space for groups of 20–30 and can prepare a special post-run menu."',
          onChanged: (value) {
            final base = kolab.description.split('\n\nNote:').first.trim();
            notifier.updateDescription(
              value.trim().isEmpty ? base : '$base\n\nNote: ${value.trim()}',
            );
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: KolabingSpacing.lg),
```

Add `final _extraNotesController = TextEditingController();` to the `State` class and dispose it alongside the screen's existing controllers (per Step 1's findings — there will already be a `dispose()` override to extend). This composes the free text into `description` with a distinct `'Note:'` marker, exactly mirroring Task 5's `'Best for:'`/`'Interaction:'` approach — confirming the project-wide convention of using marker-suffixed `description` text for any net-new informational copy that doesn't get its own backend field.

- [ ] **Step 6: Keep the existing past-event-entry fields (name/date/partner/photos) exactly as-is** — do not remove or restructure them; only their position (now below the highlights section, since they're "optional supporting evidence, not the primary ask" per spec) and surrounding copy framing changes (e.g. an "Optional" label if the section header doesn't already say so).

- [ ] **Step 7: Run static analysis**

Run: `flutter analyze lib/features/kolab/screens/business/past_events_screen.dart lib/features/kolab/providers/kolab_form_provider.dart`
Expected: No issues found.

- [ ] **Step 8: Commit**

```bash
git add lib/features/kolab/screens/business/past_events_screen.dart lib/features/kolab/providers/kolab_form_provider.dart
git commit -m "feat: relabel Past Events to Why communities will like this, add highlight chips"
```

---

### Task 7: Availability — "Immediate / always available" mode

**Files:**
- Modify: `lib/features/kolab/enums/availability_mode.dart` (find the actual file — likely `lib/features/kolab/enums/availability_mode.dart`; confirm with `find lib -iname "availability_mode.dart"`)
- Modify: `lib/features/kolab/screens/business/availability_screen.dart`
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (`_validateVenuePromotionStep`/`_validateProductPromotionStep`'s now-index-6 availability case)

**Interfaces:**
- Produces: `AvailabilityMode.immediate` (new enum value, `toApiValue() => 'immediate'`), matching the backend plan's Task 8 which adds `immediate` to the `availability_mode` `in:` validation list.

- [ ] **Step 1: Find and read the `AvailabilityMode` enum**

Run: `find lib -iname "availability_mode.dart"`

Read it fully, then add a new `immediate` value following the exact existing pattern for `oneTime`/`recurring`/`flexible`/`specificDates` (whichever values currently exist — `kolab_form_provider.dart`'s `updateAvailabilityMode` references `AvailabilityMode.oneTime` and `.recurring`; `CreateKolabRequest`'s `in:` list on the backend has `one_time,recurring,flexible,specific_dates`, so the Dart enum almost certainly has all 4 — add `immediate` as a 5th):

```dart
  immediate, // ... alongside the other existing values
```

with `toApiValue()` returning `'immediate'` and `fromString('immediate')` mapping back, mirroring however the other 4 values are wired in that same method.

- [ ] **Step 2: Read `availability_screen.dart` in full** before editing — this plan was not able to capture its exact current content. Identify: the mode-selector widget (chips/segmented control choosing between the existing modes) and the date-picker's `firstDate`/`firstAllowedDate` logic (confirmed by the earlier audit to live around `availability_screen.dart:42-43` as `firstAllowedDate = today`).

- [ ] **Step 3: Add "Immediate / always available" as a selectable mode option** in whatever widget Step 2 found renders the mode choices, following its exact existing per-mode-option pattern (likely a loop over `AvailabilityMode.values` or an explicit list of mode chips — if the former, no extra code needed beyond Step 1's enum addition + a `displayName`/label case for `immediate`; if explicit, add one more chip entry mirroring the others).

- [ ] **Step 4: Change the date-picker floor logic** so it only allows today when `immediate` is selected:

```dart
    final isImmediate = kolab.availabilityMode == AvailabilityMode.immediate;
    final firstAllowedDate = isImmediate
        ? DateUtils.dateOnly(DateTime.now())
        : DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
```

Replace the existing `firstAllowedDate = today` assignment (line ~42-43 per the audit) with the above, reading the surrounding code first to match variable names exactly.

- [ ] **Step 5: Update `_validateVenuePromotionStep`'s availability case** (now index 6, per Task 3's shift) to allow today only for `immediate`:

```dart
      case 6: // Availability
        if (kolab.availabilityMode == null) {
          errors['availability_mode'] = 'Select an availability mode';
        } else if (kolab.availabilityStart == null) {
          errors['availability_start'] =
              'Pick a start date for your availability window';
        } else {
          final isImmediate = kolab.availabilityMode == AvailabilityMode.immediate;
          final floor = isImmediate
              ? DateUtils.dateOnly(DateTime.now())
              : DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
          final start = DateUtils.dateOnly(kolab.availabilityStart!);
          if (start.isBefore(floor)) {
            errors['availability_start'] = isImmediate
                ? 'Start date cannot be in the past'
                : 'Start date must be tomorrow or later';
          }
        }
```

Apply identically in `_validateProductPromotionStep`'s now-index-6 case.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze lib/features/kolab/`
Expected: No issues found.

- [ ] **Step 7: Manually verify against a backend running the companion plan's Task 8 fix** — submitting a venue-promotion kolab with `availability_mode: immediate, availability_start: <today>` must succeed; submitting any other mode with today's date must still show the "must be tomorrow or later" validation error before it ever reaches the network call.

- [ ] **Step 8: Commit**

```bash
git add lib/features/kolab/enums/availability_mode.dart lib/features/kolab/screens/business/availability_screen.dart lib/features/kolab/providers/kolab_form_provider.dart
git commit -m "feat: add immediate availability mode, default other modes to tomorrow"
```

---

### Task 8: Media — default to existing photos, soften the hard block

**Files:**
- Modify: `lib/features/kolab/screens/business/media_screen.dart`
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (media validation in `_validateVenuePromotionStep`/`_validateProductPromotionStep`, now index 2)

**Interfaces:**
- Consumes: `BusinessProfile.profilePhoto`, `PrimaryVenueProfile.photos`, `galleryProvider` (all already used by this screen per the earlier audit — `media_screen.dart:46-50,106-107,189`, `ExistingPhotoPickerSheet`).

- [ ] **Step 1: Read `media_screen.dart` in full** before editing — confirm exactly how `galleryProvider` and the venue-photos fallback are currently surfaced (the audit found them at lines 46-50, 106-107, 189) and how the "Add at least 1 photo" requirement is currently presented to the user in this screen (vs. just enforced in the provider's validator).

- [ ] **Step 2: Add an explicit "Use business profile photo" quick-action** if one doesn't already exist as a distinct affordance (the audit found the existing photo picker is reachable via `ExistingPhotoPickerSheet`, but confirm whether a one-tap "use my profile photo" shortcut already exists or whether everything funnels through the existing-photo sheet — if the sheet already lists the profile photo as one of the choices, no new UI is needed here, only the validator change in Step 4 below).

- [ ] **Step 3: If no business photo and no gallery/venue photos exist at all**, replace the current hard error styling with a softer warning tip (still visible, not a blocking red error) — read how the current `errors['media']` message is rendered in this screen and change its presentation (e.g. swap the error-red container for the same `softYellow` tip-box style introduced in Task 4, while still recording the field error for Next-button gating only when truly nothing exists):

```dart
        if (hasNoPhotoAnywhere)
          Container(
            padding: const EdgeInsets.all(KolabingSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
            child: Text(
              'Kolabs with photos get more interest. Add one from your gallery '
              'or upload a new one.',
              style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurface, height: 1.4),
            ),
          ),
```

(`hasNoPhotoAnywhere` should be computed from whatever Step 1 reveals as the combined source — business profile photo, venue/gallery photos, and `kolab.media` — all empty.)

- [ ] **Step 4: Update the media validator** in `kolab_form_provider.dart` (now index 2 in both business flows) to pass when a business profile photo or existing gallery/venue photo is available, even if `kolab.media` itself is still empty at validation time — i.e., the validator needs to know whether the business *has* a usable default, not just whether they've explicitly added one to `kolab.media`. Since the form provider doesn't currently read profile/gallery state, the simplest minimal-risk approach is: when the Media screen's "Use business profile photo" / "Choose from existing" action is taken, it should call the existing `notifier.addMedia(...)` (already used by this screen) so the photo actually lands in `kolab.media` — meaning **no validator change is needed at all** if Step 2 confirms defaulting writes into `kolab.media` already. Only add a validator change if Step 1/2 reveal that defaulting bypasses `kolab.media` entirely (e.g. relying on `offer_photo`/profile photo as a separate fallback never written into `media`) — in that case, soften the case-2 block to:

```dart
      case 2: // Media
        // No hard block — Step 3 shows a tip instead when nothing exists at
        // all (business profile photo / gallery / venue photos / kolab.media
        // are all empty). See media_screen.dart's hasNoPhotoAnywhere check.
        break;
```

- [ ] **Step 5: Run static analysis**

Run: `flutter analyze lib/features/kolab/screens/business/media_screen.dart lib/features/kolab/providers/kolab_form_provider.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/kolab/screens/business/media_screen.dart lib/features/kolab/providers/kolab_form_provider.dart
git commit -m "fix: default Kolab media to existing business photos, soften empty-media block to a tip"
```

---

### Task 9: Review screen — listing-style preview card

**Files:**
- Modify: `lib/features/kolab/screens/business/review_screen.dart`

**Interfaces:**
- Consumes: `kolab.goal`, `kolab.highlights`, `kolab.offerHeadline`, `kolab.baseOffer`, `kolab.seekingCommunities`, `kolab.expects`, `kolab.availabilityStart`/`availabilityMode`, `kolab.preferredCity`, `kolab.media`/`kolab.offerPhoto` — all either existing or added by Tasks 2/3.

- [ ] **Step 1: Read `review_screen.dart` in full** before editing — confirm its current structure (likely a series of read-only summary sections per step) so the new preview card can be inserted/restructured in-place rather than guessed.

- [ ] **Step 2: Add a goal badge and listing-style header** at the top of the review content, above whatever summary sections Step 1 found, using a lookup of the goal's display name (via `goalsProvider`, matching `kolab.goal` against the fetched options the same way Task 6's highlights chips resolve slugs to labels):

```dart
        if (kolab.goal != null)
          Builder(builder: (context) {
            final goalsAsync = ref.watch(goalsProvider);
            final label = goalsAsync.maybeWhen(
              data: (options) => options
                  .firstWhere(
                    (o) => o.slug == kolab.goal,
                    orElse: () => OfferOption(id: kolab.goal!, slug: kolab.goal!, name: kolab.goal!),
                  )
                  .name,
              orElse: () => kolab.goal!,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm, vertical: KolabingSpacing.xxs),
              decoration: BoxDecoration(
                color: context.colors.softYellow,
                borderRadius: KolabingRadius.borderRadiusSm,
              ),
              child: Text(
                label,
                style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
              ),
            );
          }),
```

- [ ] **Step 3: Surface "Best-fit communities" and highlights** as chip rows in the preview (read-only — `Wrap` of plain styled `Text`-in-`Container` chips, reusing the same visual style as `MultiSelectChips`' selected-chip appearance but non-interactive), if Step 1's existing review screen doesn't already render `seekingCommunities` and the new `highlights` field. Resolve `highlights` slugs to display labels the same way Step 2 resolved `goal` (via `kolabHighlightsProvider`).

- [ ] **Step 4: Ensure offer headline and main offer (`baseOffer`) are shown prominently** near the top of the card (not buried below venue/product meta), matching the spec's "Show a preview card with: Photo, Offer headline, Goal badge, Venue/Product label, Best-fit communities, Main offer, What the business would like from the community, Availability, Location / city, Reasons communities will like this" — reorder Step 1's existing sections to match this order rather than introducing a parallel duplicate rendering of the same fields.

- [ ] **Step 5: Do not add any match-quality scoring** — `kolab.matchScore`/`matchBreakdown` exist on the model but are explicitly out of scope per both the spec and backend resource (`KolabResource` already keeps them read-only/computed); don't surface them on this screen if they aren't already shown, and don't add scoring logic.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze lib/features/kolab/screens/business/review_screen.dart`
Expected: No issues found.

- [ ] **Step 7: Commit**

```bash
git add lib/features/kolab/screens/business/review_screen.dart
git commit -m "feat: restyle business Kolab review as a listing-style preview card"
```

---

### Task 10: Manual verification + PR

**Files:** none (verification + PR only)

- [ ] **Step 1: Run full static analysis**

Run: `flutter analyze`
Expected: no new issues beyond pre-existing baseline.

- [ ] **Step 2: Run the full Flutter test suite**

Run: `flutter test`
Expected: all green.

- [ ] **Step 3: Manual test checklist — Venue Promotion**

Run the app against a backend that has the companion backend plan deployed (or a local branch with it). Walk through:
- [ ] Select "Venue Promotion" from the intent screen.
- [ ] Details step: confirm new copy/examples/"Best for:" chips appear; advancing without filling required fields shows the existing required-field errors unchanged.
- [ ] New Goal step appears as step 2 of 8; selecting a goal highlights it; "Open to Ideas" and "Community Perk / Member Discount" are present; advancing without picking a goal does NOT block.
- [ ] Media step: with an existing business profile photo, advancing without uploading anything new does not hard-block; with zero photos anywhere, a soft tip (not a red error) is shown.
- [ ] Offering step: offer headline is the first, visually primary field; leaving it blank and hitting Next reproduces the existing required-field error; main offer field is present and required; "what would you like from the community" multi-select shows the expanded ~16-option list (5 original + 11 new) fetched from `/lookup/deliverables`; tip box renders.
- [ ] Best-fit communities step: chips load dynamically (not the old hardcoded 16); selecting up to 5 works; copy reads "Best-fit communities" / "Who would this Kolab be perfect for?".
- [ ] "Why communities will like this" step: highlight chips load from `/lookup/kolab-highlights`; optional free-text "Anything else..." field works; existing past-event entry fields still present below, framed as optional.
- [ ] Availability step: "Immediate / always available" mode allows picking today; any other mode rejects today with a clear error and accepts tomorrow+.
- [ ] Review step: shows photo, offer headline, goal badge, best-fit communities, main offer, community asks, availability, highlights — in that order; no match score shown.
- [ ] Submit (save draft, then separately publish on a fresh draft) succeeds end-to-end; inspect the network payload (or backend logs) to confirm `goal` and `highlights` are present when set.

- [ ] **Step 4: Manual test checklist — Product Promotion**

Repeat the same walkthrough selecting "Product Promotion" instead, additionally confirming:
- [ ] Product details step shows the new "How do you want communities to interact with your product?" multi-select (`/lookup/product-interactions`).
- [ ] Product Promotion works fully without any venue/physical-location fields filled in (per spec: "product brands must be able to create Kolabs whether they have a venue or not").

- [ ] **Step 5: Create the ticket and PR** per this repo's contribution rules (check `kolabing-app`'s own CLAUDE.md/contribution doc if one exists for its exact PR requirements — this plan doesn't assume `kolabing-app` has the same protected-branch/PR-template rules confirmed for `kolabing-v2`; if it does, follow them identically: feature branch, never push to main directly, link the tracking ticket).

```bash
gh pr create --title "feat: redesign business Kolab creation flow (goal-first, offer-first)" --body "$(cat <<'EOF'
## Summary
- Adds a new Goal step; reorders Offering to lead with offer headline + main offer
- Best-fit communities and venue/product chip lists are now fetched dynamically instead of hardcoded
- Relabels Past Events to "Why communities will like this" with new highlight chips
- Adds an Immediate/always-available mode; media requirement softened to a tip when defaults exist
- Review screen restyled as a listing-style preview

## Backend dependency
Requires the companion kolabing-v2 PR (goal/highlights columns, 4 new lookup endpoints, expanded deliverable taxonomy, immediate-availability validation fix) to be merged/deployed first.

## Testing
[paste flutter test counts here]

Closes #<ticket-number>
EOF
)"
```

---

## Self-Review Notes

- **Spec coverage:** Goal step (Task 3), offer-first Offering reorder + expanded community-ask options (Task 4), Best-fit communities rename + dynamic chips + venue-fit/product-interaction chips (Task 5), Past Events relabel + highlights (Task 6), Immediate availability (Task 7), Media softening (Task 8), Review restyle (Task 9) — all spec sections covered. Community-seeking flow is untouched in every task.
- **Honest limitation:** Tasks 5 (venue/product details screens), 6 (`past_events_screen.dart`), 7 (`availability_screen.dart`/`availability_mode.dart`), 8 (`media_screen.dart`), and 9 (`review_screen.dart`) could not be given verbatim before/after diffs against their exact current source in this plan — those files were not read in full during planning (time-boxed). Each such task's first step explicitly directs the implementer to read the file before editing, and gives complete new code for the *added* logic/widgets (which follows patterns already verified verbatim in Tasks 1-4 against `offer_option_service.dart`, `offer_option_provider.dart`, `offering_screen.dart`, and `ideal_community_screen.dart`). Treat those steps as "insert this exact new code in the right place" rather than "this is the full file diff."
- **Type consistency check:** `OfferOption(id:, slug:, name:)` constructor shape used consistently across Tasks 1/3/4/5/6/9. `KolabFormNotifier.toggleHighlight`/`updateGoal` names match what Task 9's review screen and Task 6's chip section call. `AvailabilityMode.immediate` name matches across Task 7's enum, screen, and validator changes, and matches the backend plan's `'immediate'` string contract.
