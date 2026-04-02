# New Kolab Creation Flow — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace generic create flows with intent-driven kolab creation for both business and community users.

**Architecture:** New `lib/features/kolab/` feature module with enums, model, Riverpod notifier, mock service, shared widgets, and intent-specific screen flows. Unified entry via FAB → IntentSelectionScreen → branching wizard.

**Tech Stack:** Flutter, Riverpod 2.4 (Notifier pattern), GoRouter, GoogleFonts, LucideIcons, existing design tokens (KolabingColors, KolabingSpacing, KolabingRadius).

**Design doc:** `docs/plans/2026-03-24-new-kolab-creation-flow-design.md`

**Reference files for patterns:**
- Enum pattern: `lib/features/opportunity/models/opportunity.dart` (AvailabilityMode, VenueMode enums)
- Provider pattern: `lib/features/opportunity/providers/opportunity_form_provider.dart`
- Screen pattern: `lib/features/community/screens/create_opportunity_screen.dart`
- Routes: `lib/config/routes/routes.dart`
- FAB: `lib/widgets/navigation/kolabing_fab.dart`
- Design tokens: `lib/config/theme/colors.dart`, `lib/config/constants/spacing.dart`, `lib/config/constants/radius.dart`

---

## Task 1: Create Enums

**Files:**
- Create: `lib/features/kolab/enums/intent_type.dart`
- Create: `lib/features/kolab/enums/venue_type.dart`
- Create: `lib/features/kolab/enums/product_type.dart`
- Create: `lib/features/kolab/enums/need_type.dart`
- Create: `lib/features/kolab/enums/deliverable_type.dart`

**Step 1:** Create all 5 enum files following the pattern from `AvailabilityMode` in opportunity.dart. Each enum needs: `displayName` getter, `toApiValue()` returning snake_case string, `static fromString(String)` factory.

**IntentType:** `communitySeekingcommunitySeeking('Community Seeking', 'community_seeking')`, `venuePromotion('Venue Promotion', 'venue_promotion')`, `productPromotion('Product Promotion', 'product_promotion')` — add `totalSteps` getter: communitySeekingcommunitySeeking→6, venue/product→7.

**VenueType:** restaurant, cafe, barLounge, hotel, coworking, sportsFacility, eventSpace, rooftop, beachClub, retailStore, other — each with display name and icon (LucideIcons).

**ProductType:** foodProduct, beverage, healthBeauty, sportsEquipment, fashion, techGadget, experienceService, other — each with display name and icon.

**NeedType:** venue, foodDrink, sponsor, products, discount, other — each with display name and icon.

**DeliverableType:** socialMedia, eventActivation, productPlacement, communityReach, reviewFeedback — each with display name and subtitle description.

**Step 2:** Verify: `dart analyze lib/features/kolab/enums/`

**Step 3:** Commit: `feat(kolab): add enums for new creation flow`

---

## Task 2: Create Kolab Model

**Files:**
- Create: `lib/features/kolab/models/kolab.dart`

**Step 1:** Create the Kolab model class. Follow the pattern from `Opportunity` model. The class needs:
- All fields from design doc (see `docs/plans/2026-03-24-new-kolab-creation-flow-design.md` Data Model section)
- `const` constructor with named parameters, defaults for lists (`const []`)
- `factory Kolab.empty(IntentType intentType)` returning sensible defaults
- `copyWith()` method with all optional parameters
- `toJson()` method (for future API)
- `factory Kolab.fromJson(Map<String, dynamic>)` (for future API)
- Import and reuse `AvailabilityMode` from `lib/features/opportunity/models/opportunity.dart` (don't duplicate)

**Also create in same file:**
- `class KolabMedia { final String url; final String type; final int sortOrder; }` with const constructor, copyWith, toJson, fromJson
- `class PastEvent { final String name; final DateTime date; final String? partnerName; final List<String> photos; }` with const constructor, copyWith, toJson, fromJson
- `enum VenuePreference { businessProvides, communityProvides, noVenue }` with displayName, toApiValue, fromString (same pattern)

**Step 2:** Verify: `dart analyze lib/features/kolab/models/`

**Step 3:** Commit: `feat(kolab): add Kolab model with value objects`

---

## Task 3: Create Mock KolabService

**Files:**
- Create: `lib/features/kolab/services/kolab_service.dart`

**Step 1:** Create the mock service. Follow the pattern from `lib/features/opportunity/services/opportunity_service.dart` but return mock data. All methods add `await Future.delayed(const Duration(milliseconds: 500))` to simulate network.

Methods:
- `Future<Kolab> create(Kolab kolab)` — returns kolab with generated mock id
- `Future<Kolab> update(String id, Kolab kolab)` — returns updated kolab
- `Future<void> publish(String id)` — no-op with delay
- `Future<void> close(String id)` — no-op with delay
- `Future<List<Kolab>> getMyKolabs({String? status})` — returns empty list
- `Future<Kolab> getDetail(String id)` — returns mock Kolab

Create a Riverpod provider: `final kolabServiceProvider = Provider<KolabService>((ref) => KolabService());`

**Step 2:** Verify: `dart analyze lib/features/kolab/services/`

**Step 3:** Commit: `feat(kolab): add mock KolabService`

---

## Task 4: Create KolabFormProvider

**Files:**
- Create: `lib/features/kolab/providers/kolab_form_provider.dart`

**Step 1:** Create `KolabFormState` immutable class:
```dart
@immutable
class KolabFormState {
  final IntentType? intentType;
  final int currentStep;
  final int totalSteps;
  final Kolab kolab;
  final bool isEditing;
  final bool isSubmitting;
  final bool isPublishing;
  final bool isSuccess;
  final bool requiresSubscription;
  final String? error;
  final Map<String, String> fieldErrors;
  // const constructor, copyWith with clearError bool
}
```

**Step 2:** Create `KolabFormNotifier extends Notifier<KolabFormState>` with:
- `build()` → initial state with `intentType: null, currentStep: 0, totalSteps: 6, kolab: Kolab.empty(IntentType.communitySeeking)`
- `selectIntent(IntentType type)` → sets intentType, resets kolab to `Kolab.empty(type)`, sets totalSteps from `type.totalSteps`
- Navigation: `nextStep()` (validates first via `validateCurrentStep()`), `previousStep()`, `goToStep(int)`
- Field update methods — one per model field (all call `state = state.copyWith(kolab: state.kolab.copyWith(...), error: null)`)
- `bool validateCurrentStep()` — switch on intentType + currentStep, returns true/false and sets fieldErrors
- `Future<void> saveDraft()` — calls `_service.create()` or `_service.update()`, handles errors
- `Future<void> saveAndPublish()` — save then publish
- `void reset()` — back to initial state

**Step 3:** Create provider declaration: `final kolabFormProvider = NotifierProvider<KolabFormNotifier, KolabFormState>(KolabFormNotifier.new);`

**Step 4:** Verify: `dart analyze lib/features/kolab/providers/`

**Step 5:** Commit: `feat(kolab): add KolabFormProvider with validation`

---

## Task 5: Create Shared Widgets

**Files:**
- Create: `lib/features/kolab/widgets/kolab_step_indicator.dart`
- Create: `lib/features/kolab/widgets/kolab_action_bar.dart`
- Create: `lib/features/kolab/widgets/multi_select_chips.dart`
- Create: `lib/features/kolab/widgets/intent_card.dart`
- Create: `lib/features/kolab/widgets/media_picker_grid.dart`
- Create: `lib/features/kolab/widgets/past_event_card.dart`
- Create: `lib/features/kolab/widgets/kolab_review_card.dart`

**Step 1: KolabStepIndicator** — Extract the step indicator dots pattern from `create_opportunity_screen.dart` (lines ~440-490). Takes `currentStep`, `totalSteps`, `onStepTap` callback. Animated dots: inactive (border), active (primary filled), completed (primary filled + smaller).

**Step 2: KolabActionBar** — Sticky bottom bar. Takes `onBack`, `onNext`, `onSaveDraft`, `onPublish`, `isLastStep`, `isSubmitting`, `isPublishing`. Shows Back+Next for non-last steps, SaveDraft+Publish for last step. Follow existing button pattern: height 52dp, radius 12dp, Darker Grotesque font.

**Step 3: MultiSelectChips** — Takes `List<T> items`, `List<T> selected`, `String Function(T) labelBuilder`, `IconData? Function(T)? iconBuilder`, `void Function(T) onToggle`, optional `int? maxSelect`. Renders wrap of animated chip containers using KolabingColors.primary for selected, border for unselected.

**Step 4: IntentCard** — Large selection card. Takes `IconData icon`, `String title`, `String subtitle`, `String? badge` (e.g. "FREE"), `bool isSelected`, `VoidCallback onTap`. White card with border, selected state shows yellow border + soft yellow bg (#FFF6D8).

**Step 5: MediaPickerGrid** — Takes `List<KolabMedia> media`, `int maxItems` (default 5), `VoidCallback onAdd`, `void Function(int) onRemove`. Grid of photo slots + add button. Uses placeholder for now (no actual picker integration — just shows slots).

**Step 6: PastEventCard** — Takes `PastEvent? event`, `VoidCallback onAdd`, `VoidCallback? onRemove`. Card showing event name, date, partner, photo count. Add button if event is null.

**Step 7: KolabReviewCard** — Takes `Kolab kolab`. Renders full summary card per intent type. Shows all filled fields in sections with icons. Each section is tappable (takes `void Function(int step) onEditSection`).

**Step 8:** Verify: `dart analyze lib/features/kolab/widgets/`

**Step 9:** Commit: `feat(kolab): add shared widgets for creation flow`

---

## Task 6: IntentSelectionScreen

**Files:**
- Create: `lib/features/kolab/screens/intent_selection_screen.dart`

**Step 1:** Create `IntentSelectionScreen extends ConsumerWidget`. Reads user type from `profileProvider` (or auth state).

**For community users** — shows 2 IntentCards:
- "Find a Venue or Sponsor" / "for my community event" / badge: "FREE" → selectIntent(communitySeeking), push to step flow
- "Promote a Venue, Product or Service" / badge: "SUBSCRIPTION REQUIRED" → check subscription, if active selectIntent and show venue/product choice, if not show SubscriptionPaywall

**For business users** — shows 2 IntentCards:
- "Promote my Venue" / "Get communities to host events at your location" → selectIntent(venuePromotion), push to step flow
- "Promote a Product or Service" / "Get communities to feature your products" → selectIntent(productPromotion), push to step flow

**Layout:** AppBar with back button + "NEW KOLAB" title. Body: padding, headline text "What would you like to do?" (community) or "What would you like to promote?" (business), then cards with spacing.

**Step 2:** Verify: `flutter analyze lib/features/kolab/screens/intent_selection_screen.dart`

**Step 3:** Commit: `feat(kolab): add IntentSelectionScreen`

---

## Task 7: Community Flow — Screens 0-2

**Files:**
- Create: `lib/features/kolab/screens/community/needs_screen.dart`
- Create: `lib/features/kolab/screens/community/community_info_screen.dart`
- Create: `lib/features/kolab/screens/community/event_details_screen.dart`

**Step 1: NeedsScreen (Step 0)** — "WHAT DO YOU NEED?" with MultiSelectChips of NeedType values (6 options in 2-column grid). Each chip has icon + label. Min 1 selection required. Uses KolabStepIndicator at top + KolabActionBar at bottom.

**Step 2: CommunityInfoScreen (Step 1)** — "YOUR COMMUNITY TYPE" with MultiSelectChips of community type strings (reuse `OpportunityCategories.all` from existing code or the community_types from backend). Max 3 selections. Below: two text fields for "Community Size" (number input) and "Expected Attendees" (number input). Step indicator + action bar.

**Step 3: EventDetailsScreen (Step 2)** — "COLLABORATION DETAILS" with title field (max 255), description field (max 2000, multiline), and "WHAT YOU OFFER IN RETURN" section with MultiSelectChips of DeliverableType values. Step indicator + action bar.

**Step 4:** Verify: `dart analyze lib/features/kolab/screens/community/`

**Step 5:** Commit: `feat(kolab): add community flow screens 0-2`

---

## Task 8: Community Flow — Screens 3-5

**Files:**
- Create: `lib/features/kolab/screens/community/logistics_screen.dart`
- Create: `lib/features/kolab/screens/community/photo_screen.dart`
- Create: `lib/features/kolab/screens/community/review_screen.dart`

**Step 1: LogisticsScreen (Step 3)** — Reuse availability pattern from `create_opportunity_screen.dart`:
- 3 availability mode selection cards (one_time, recurring, flexible)
- Conditional date pickers (start/end) for one_time and flexible
- Conditional time picker + day selector for recurring
- "LOCATION" section: 3 venue preference cards (business provides, community provides, no venue)
- City dropdown (reuse `citiesProvider` from `lib/features/opportunity/providers/opportunity_provider.dart`)
- Optional "Preferred Area" text field

**Step 2: PhotoScreen (Step 4)** — "ADD A PHOTO" with two options: checkbox "Use your community profile photo" (default checked), or upload area placeholder (MediaPickerGrid with maxItems: 1). Simple screen.

**Step 3: CommunityReviewScreen (Step 5)** — Uses KolabReviewCard to show full summary. Sections: title+description, looking for (needs), offering (offersInReturn), community info (types, size, attendance), location (city, area, venue preference), availability. "Tap any section to edit" hint. Bottom: SAVE DRAFT + PUBLISH buttons.

**Step 4:** Verify: `dart analyze lib/features/kolab/screens/community/`

**Step 5:** Commit: `feat(kolab): add community flow screens 3-5`

---

## Task 9: Business Flow — Screens 0-2

**Files:**
- Create: `lib/features/kolab/screens/business/venue_details_screen.dart`
- Create: `lib/features/kolab/screens/business/product_details_screen.dart`
- Create: `lib/features/kolab/screens/business/media_screen.dart`

**Step 1: VenueDetailsScreen (Step 0, venue_promotion)** — "YOUR VENUE" with:
- Venue Name text field (max 255)
- Venue Type: MultiSelectChips with VenueType values (single select, max 1)
- Capacity: number input
- Address: text field
- City: dropdown (reuse citiesProvider)

**Step 2: ProductDetailsScreen (Step 0, product_promotion)** — "YOUR PRODUCT OR SERVICE" with:
- Product Name text field (max 255)
- Product Type: MultiSelectChips with ProductType values (single select, max 1)
- Description: multiline text field (max 2000)
- City: dropdown

**Step 3: MediaScreen (Step 1, both flows)** — "SHOW OFF YOUR VENUE" / "SHOW YOUR PRODUCT" (title varies by intent). MediaPickerGrid with min 1, max 5 photos. Optional video upload slot below (placeholder). Subtitle explains what photos are for.

**Step 4:** Verify: `dart analyze lib/features/kolab/screens/business/`

**Step 5:** Commit: `feat(kolab): add business flow screens 0-2`

---

## Task 10: Business Flow — Screens 3-6

**Files:**
- Create: `lib/features/kolab/screens/business/offering_screen.dart`
- Create: `lib/features/kolab/screens/business/ideal_community_screen.dart`
- Create: `lib/features/kolab/screens/business/past_events_screen.dart`
- Create: `lib/features/kolab/screens/business/availability_screen.dart`
- Create: `lib/features/kolab/screens/business/review_screen.dart`

**Step 1: OfferingScreen (Step 2)** — "WHAT YOU'RE OFFERING" with checkbox-style toggle cards (same pattern as community deliverables in `create_opportunity_screen.dart`):
- Venue (auto-selected + locked if venue_promotion intent)
- Food & Drink included
- Discount for community members
- Products / Samples
- Social Media Exposure
- Content Creation
- Sponsorship budget
- Other

**Step 2: IdealCommunityScreen (Step 3)** — "IDEAL COMMUNITY" with:
- MultiSelectChips of community types (max 5)
- "Minimum Community Size" number input (optional)
- "WHAT DO YOU EXPECT FROM THE COMMUNITY?" with MultiSelectChips of DeliverableType values

**Step 3: PastEventsScreen (Step 4)** — "PAST COLLABORATIONS (optional)" with PastEventCard list. Add button creates entry with name, date, partner name fields, photo upload placeholder (max 3 per event). Skip button available. Max 5 events.

**Step 4: AvailabilityScreen (Step 5)** — Same availability pattern as community LogisticsScreen but WITHOUT the location/venue preference section (venue address already collected in step 0). Just: availability mode + date/time fields.

**Step 5: BusinessReviewScreen (Step 6)** — KolabReviewCard showing: venue/product info, photos count, offering, ideal community + expects, past events count, availability. Bottom: SAVE DRAFT + PUBLISH.

**Step 6:** Verify: `dart analyze lib/features/kolab/screens/business/`

**Step 7:** Commit: `feat(kolab): add business flow screens 3-6`

---

## Task 11: Subscription Gate Screen

**Files:**
- Create: `lib/features/kolab/screens/subscription_gate_screen.dart`

**Step 1:** This screen is shown when a community user selects "Promote Venue/Product" in IntentSelectionScreen and does NOT have an active subscription.

It reuses the existing `SubscriptionPaywall` widget from `lib/features/subscription/widgets/subscription_paywall.dart`. The screen shows the paywall as a full-screen view (not bottom sheet), with a back button.

If already subscribed → skip this screen entirely (handled in IntentSelectionScreen logic).

After successful subscription → show venue/product choice (2 IntentCards: "A Venue" vs "A Product or Service") → then proceed to business flow.

**Step 2:** Verify: `dart analyze lib/features/kolab/screens/subscription_gate_screen.dart`

**Step 3:** Commit: `feat(kolab): add subscription gate for community Flow B`

---

## Task 12: Create Kolab Flow Shell Screen

**Files:**
- Create: `lib/features/kolab/screens/kolab_flow_screen.dart`

**Step 1:** Create the shell screen that wraps the step-based flow. This is the main screen pushed after intent selection. It:
- Reads `kolabFormProvider` for currentStep and intentType
- Renders KolabStepIndicator at top
- Switches content based on intentType + currentStep (returns the correct screen widget)
- Renders KolabActionBar at bottom
- Handles back button (PopScope) — goes to previous step or pops if step 0
- Listens for `isSuccess` to show success dialog and navigate back

**Step mapping logic:**
```dart
Widget _buildStepContent(IntentType intent, int step) {
  switch (intent) {
    case IntentType.communitySeeking:
      return switch (step) {
        0 => const NeedsScreen(),
        1 => const CommunityInfoScreen(),
        2 => const EventDetailsScreen(),
        3 => const LogisticsScreen(),
        4 => const PhotoScreen(),
        5 => const CommunityReviewScreen(),
        _ => const SizedBox(),
      };
    case IntentType.venuePromotion:
      return switch (step) {
        0 => const VenueDetailsScreen(),
        1 => const MediaScreen(),
        2 => const OfferingScreen(),
        3 => const IdealCommunityScreen(),
        4 => const PastEventsScreen(),
        5 => const AvailabilityScreen(),
        6 => const BusinessReviewScreen(),
        _ => const SizedBox(),
      };
    case IntentType.productPromotion:
      return switch (step) {
        0 => const ProductDetailsScreen(),
        1 => const MediaScreen(),
        // ... same as venue from step 2 onward
      };
  }
}
```

Each step screen is a plain widget (no Scaffold) — the shell provides Scaffold, AppBar, step indicator, and action bar.

**Step 2:** Verify: `dart analyze lib/features/kolab/screens/kolab_flow_screen.dart`

**Step 3:** Commit: `feat(kolab): add KolabFlowScreen shell`

---

## Task 13: Route & FAB Integration

**Files:**
- Modify: `lib/config/routes/routes.dart`
- Modify: `lib/features/business/screens/business_main_screen.dart`
- Modify: `lib/features/community/screens/community_main_screen.dart`

**Step 1:** Add route constants and GoRoute entries:
```dart
// In KolabingRoutes class
static const String kolabNew = '/kolab/new';

// In router GoRoute list
GoRoute(
  path: KolabingRoutes.kolabNew,
  builder: (context, state) => const IntentSelectionScreen(),
),
```

**Step 2:** Update business FAB to push `/kolab/new`:
```dart
// business_main_screen.dart — change _onFabPressed
await context.push(KolabingRoutes.kolabNew);
```

**Step 3:** Update community FAB to push `/kolab/new`:
```dart
// community_main_screen.dart — change _onFabPressed
await context.push(KolabingRoutes.kolabNew);
```

**Step 4:** Verify: `dart analyze lib/config/routes/ lib/features/business/screens/business_main_screen.dart lib/features/community/screens/community_main_screen.dart`

**Step 5:** Commit: `feat(kolab): integrate new creation flow with routes and FAB`

---

## Task 14: End-to-End Verification

**Step 1:** Run full analysis: `dart analyze lib/`

**Step 2:** Run the app on simulator: `flutter run -d <device_id>`

**Step 3:** Manual test all flows:
- Community user → FAB → "Find Venue/Sponsor" → complete 6 steps → Save Draft
- Community user → FAB → "Promote Venue/Product" → paywall shown
- Business user → FAB → "Promote Venue" → complete 7 steps → Save Draft
- Business user → FAB → "Promote Product" → complete 7 steps → Save Draft
- Back navigation works on each step
- Step indicator taps work for completed steps
- Validation errors show correctly per step

**Step 4:** Fix any issues found during testing.

**Step 5:** Final commit: `feat(kolab): complete new kolab creation flow`

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Enums | 5 new |
| 2 | Kolab model | 1 new |
| 3 | Mock service | 1 new |
| 4 | Form provider | 1 new |
| 5 | Shared widgets | 7 new |
| 6 | Intent selection screen | 1 new |
| 7 | Community screens 0-2 | 3 new |
| 8 | Community screens 3-5 | 3 new |
| 9 | Business screens 0-2 | 3 new |
| 10 | Business screens 3-6 | 5 new |
| 11 | Subscription gate | 1 new |
| 12 | Flow shell screen | 1 new |
| 13 | Route + FAB integration | 3 modified |
| 14 | E2E verification | 0 |
| **Total** | | **35 new, 3 modified** |
