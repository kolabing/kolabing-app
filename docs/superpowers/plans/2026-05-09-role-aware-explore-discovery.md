# Role-Aware Explore Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace generic explore filtering with a role-aware discovery feed that uses `Recommended` ranking, opposite-side-only results, and short high-signal filters.

**Architecture:** Keep the current `ExploreScreen` shell and swipe-card interaction, but introduce a new discovery API model and service backed by published kolabs. The mobile app will stop coupling Explore to the old `Opportunity` payload and instead consume a normalized discovery contract designed for ranking and role-aware filters.

**Tech Stack:** Flutter, Riverpod, HTTP REST API, widget tests, unit tests

---

## Files

- Create: `lib/features/discovery/models/discovery_item.dart`
- Create: `lib/features/discovery/models/discovery_filters.dart`
- Create: `lib/features/discovery/services/discovery_service.dart`
- Create: `lib/features/discovery/providers/discovery_provider.dart`
- Create: `lib/features/discovery/widgets/discovery_quick_filters.dart`
- Create: `test/features/discovery/models/discovery_filters_test.dart`
- Create: `test/features/discovery/services/discovery_service_test.dart`
- Create: `test/features/discovery/providers/discovery_provider_test.dart`
- Modify: `lib/features/business/screens/explore_screen.dart`
- Modify: `lib/widgets/explore_filter_sheet.dart`
- Modify: `lib/widgets/explore_swipe_card.dart`

### Task 1: Add the discovery domain model

**Files:**
- Create: `lib/features/discovery/models/discovery_item.dart`
- Test: `test/features/discovery/services/discovery_service_test.dart`

- [ ] **Step 1: Write the failing parsing test**

Add a JSON fixture-style test that asserts:

- business offer items parse `offer_types`, `venue_type`, `expected_deliverables`
- community request items parse `need_types`, `community_types`, `community_size`
- `match.score` and `match.reasons` parse correctly

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/discovery/services/discovery_service_test.dart`
Expected: fail because `DiscoveryItem` does not exist

- [ ] **Step 3: Implement `DiscoveryItem` and nested value objects**

Create focused value objects instead of a single giant map-driven model:

- `DiscoveryItem`
- `DiscoveryAvailability`
- `DiscoveryCreatorProfile`
- `BusinessOfferSummary`
- `CommunityRequestSummary`
- `DiscoveryMatch`
- `DiscoveryLabelValue`

- [ ] **Step 4: Re-run the parsing test**

Run: `flutter test test/features/discovery/services/discovery_service_test.dart`
Expected: pass for the parse-only case

### Task 2: Add role-aware discovery filters

**Files:**
- Create: `lib/features/discovery/models/discovery_filters.dart`
- Test: `test/features/discovery/models/discovery_filters_test.dart`

- [ ] **Step 1: Write failing filter serialization tests**

Cover:

- common filters serialize correctly
- business-only filters serialize correctly
- community-only filters serialize correctly
- clear/reset behavior removes params cleanly

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/discovery/models/discovery_filters_test.dart`
Expected: fail because `DiscoveryFilters` does not exist

- [ ] **Step 3: Implement the filter model**

Include:

- `feed`
- `city`
- `availabilityMode`
- `availabilityFrom`
- `availabilityTo`
- `intentTypes`
- `offerTypes`
- `needTypes`
- `communityTypes`
- `audienceSizeBand`
- `communityRequirementBand`
- `venueTypes`
- `productTypes`
- `expectedDeliverables`
- `offersInReturn`
- `venuePreferences`

- [ ] **Step 4: Re-run filter tests**

Run: `flutter test test/features/discovery/models/discovery_filters_test.dart`
Expected: pass

### Task 3: Add discovery service and provider

**Files:**
- Create: `lib/features/discovery/services/discovery_service.dart`
- Create: `lib/features/discovery/providers/discovery_provider.dart`
- Test: `test/features/discovery/services/discovery_service_test.dart`
- Test: `test/features/discovery/providers/discovery_provider_test.dart`

- [ ] **Step 1: Write the failing service test**

Assert that `GET /api/v1/discovery/opportunities` is called with:

- `feed`
- pagination
- serialized filters
- bearer token headers from shared `AuthService`

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/discovery/services/discovery_service_test.dart`
Expected: fail because `DiscoveryService` does not exist

- [ ] **Step 3: Implement the service**

Mirror the existing service conventions:

- injected shared `AuthService`
- injected `http.Client`
- refresh/retry on `401`
- parse paginated envelope

- [ ] **Step 4: Add the failing provider test**

Assert that:

- initial build loads the first page
- changing filters refreshes results
- `loadMore()` appends data
- `Recommended` and `All` use separate query params, not separate providers

- [ ] **Step 5: Run the provider test to verify it fails**

Run: `flutter test test/features/discovery/providers/discovery_provider_test.dart`
Expected: fail because provider layer does not exist

- [ ] **Step 6: Implement the provider layer**

Add:

- `discoveryServiceProvider`
- `discoveryFiltersProvider`
- `discoveryListProvider`

- [ ] **Step 7: Re-run service and provider tests**

Run: `flutter test test/features/discovery/services/discovery_service_test.dart test/features/discovery/providers/discovery_provider_test.dart`
Expected: pass

### Task 4: Replace ExploreScreen data source

**Files:**
- Modify: `lib/features/business/screens/explore_screen.dart`
- Modify: `lib/widgets/explore_swipe_card.dart`
- Test: `test/features/discovery/providers/discovery_provider_test.dart`

- [ ] **Step 1: Write a failing widget/provider integration test**

Assert that:

- community explore forces business offers only through backend response, not client-only hacks
- business explore consumes the new discovery provider
- `Recommended | All` switching updates the feed

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/discovery/providers/discovery_provider_test.dart`
Expected: fail because `ExploreScreen` still depends on `Opportunity`

- [ ] **Step 3: Update ExploreScreen to consume discovery items**

Keep the shell intact:

- top bar stays
- page view stays
- empty/error/loading states stay

Change:

- provider source
- filter summary text
- quick filters row
- feed segmentation

- [ ] **Step 4: Update swipe cards**

Add:

- optional `fit score` badge
- short fit reason chips or text
- role-aware summary badges

Do not redesign the whole card.

- [ ] **Step 5: Re-run the integration test**

Run: `flutter test test/features/discovery/providers/discovery_provider_test.dart`
Expected: pass

### Task 5: Make the filter sheet role-aware

**Files:**
- Modify: `lib/widgets/explore_filter_sheet.dart`
- Create: `lib/features/discovery/widgets/discovery_quick_filters.dart`

- [ ] **Step 1: Write a failing widget test for the filter sheet**

Assert:

- business viewers see `Need`, `Community Type`, `Audience Size`
- community viewers see `Collab Type`, `What They Offer`, `Venue Type`, `Product Type`
- search remains visible but secondary

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/discovery/providers/discovery_provider_test.dart`
Expected: fail because the current sheet is still generic

- [ ] **Step 3: Implement role-aware sheet sections**

Keep the current visual language:

- same sheet chrome
- same typography family
- same chip treatment

Change the content by viewer role.

- [ ] **Step 4: Add quick filter row widget under the segmented control**

Quick filters:

- business viewer: `City`, `Need`, `Community Type`, `Audience Size`
- community viewer: `City`, `Collab Type`, `What They Offer`, `Availability`

- [ ] **Step 5: Re-run the widget test**

Run: `flutter test test/features/discovery/providers/discovery_provider_test.dart`
Expected: pass

### Task 6: Regression verification

**Files:**
- Review: `lib/features/business/screens/explore_screen.dart`
- Review: `lib/widgets/explore_filter_sheet.dart`
- Review: `lib/widgets/explore_swipe_card.dart`

- [ ] **Step 1: Run focused tests**

Run:

```bash
flutter test test/features/discovery/models/discovery_filters_test.dart
flutter test test/features/discovery/services/discovery_service_test.dart
flutter test test/features/discovery/providers/discovery_provider_test.dart
```

Expected: all pass

- [ ] **Step 2: Run analyzer on touched files**

Run:

```bash
flutter analyze lib/features/discovery lib/features/business/screens/explore_screen.dart lib/widgets/explore_filter_sheet.dart lib/widgets/explore_swipe_card.dart test/features/discovery
```

Expected: no new analyzer errors

- [ ] **Step 3: Manual smoke verification**

Run the app and verify:

- business explore opens on `Recommended`
- community explore opens on `Recommended`
- quick chips update the list
- switching `Recommended` / `All` refreshes results
- existing notification bell and swipe behavior still work
