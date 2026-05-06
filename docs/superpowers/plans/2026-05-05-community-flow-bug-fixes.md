# Community Flow Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore reliable community navigation, community kolab creation validation, and my-kolabs state synchronization so community users always see the right tab, the right intent options, valid schedules, and fresh paginated list data.

**Architecture:** Keep fixes local to the existing Flutter client boundaries: GoRouter entry points, Riverpod profile/form/list providers, and the community-facing screens that already render these states. Reuse working pagination and loading-state patterns from the opportunity and dashboard flows instead of inventing new abstractions.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_test

---

### Task 1: Community entry and intent gating

**Files:**
- Modify: `lib/features/community/screens/community_main_screen.dart`
- Modify: `lib/features/kolab/screens/intent_selection_screen.dart`
- Add/Modify: `test/config/routes/community_route_test.dart`
- Add/Modify: `test/features/kolab/screens/intent_selection_screen_test.dart`

- [ ] **Step 1: Write a failing route/default-tab test**

Verify that the community shell starts on the Home tab when `/community` is opened without an explicit `initialTab`.

- [ ] **Step 2: Write a failing loading-state test for intent selection**

Render `IntentSelectionScreen` with a profile state that is still loading and confirm that business-only intent cards are not shown before profile type resolves.

- [ ] **Step 3: Implement the minimal navigation fix**

Change the default `CommunityMainScreen.initialTab` to the Home index used by the shell.

- [ ] **Step 4: Implement the minimal profile-gating fix**

Treat `profileProvider` loading/uninitialized state as its own branch in `IntentSelectionScreen`, and only render community or business intent cards once the profile type is known.

- [ ] **Step 5: Re-run the targeted tests**

Run: `flutter test test/config/routes/community_route_test.dart test/features/kolab/screens/intent_selection_screen_test.dart`

### Task 2: Community logistics validation

**Files:**
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart`
- Modify: `test/features/kolab/providers/kolab_form_provider_test.dart`

- [ ] **Step 1: Write failing validation tests**

Cover these cases for `IntentType.communitySeeking` step 3:
- one-time mode requires `availability_start`, `availability_end`, and `selected_time`
- recurring mode requires at least one `recurring_day` and `selected_time`
- flexible mode requires `availability_start` and `availability_end`
- all modes still require `preferred_city`

- [ ] **Step 2: Implement mode-aware validation**

Centralize the community step-3 rules so the provider validates exactly the fields that the logistics screen collects for each availability mode.

- [ ] **Step 3: Keep error keys aligned with the screen**

Use the existing field-error keys already rendered by the community logistics UI: `availability_mode`, `availability_start`, `availability_end`, `selected_time`, `recurring_day`, `preferred_city`.

- [ ] **Step 4: Re-run the targeted provider tests**

Run: `flutter test test/features/kolab/providers/kolab_form_provider_test.dart`

### Task 3: Community my-kolabs freshness and pagination

**Files:**
- Modify: `lib/features/community/screens/community_main_screen.dart`
- Modify: `lib/features/kolab/providers/my_kolabs_provider.dart`
- Modify: `lib/features/kolab/services/kolab_service.dart`
- Add/Modify: `test/features/kolab/providers/my_kolabs_provider_test.dart`

- [ ] **Step 1: Write failing provider tests for pagination/state refresh**

Cover the provider behavior that is currently missing:
- paginator metadata from `/kolabs/me` updates `currentPage`, `lastPage`, `total`, and `hasMore`
- `loadMore()` requests the next page and appends results
- refreshing after create/mutate reloads the first page cleanly

- [ ] **Step 2: Return paginated my-kolabs data from the service**

Parse both flat-list and Laravel paginator responses into a structured paginated result instead of discarding page metadata.

- [ ] **Step 3: Teach the provider to track pagination**

Add page counters, implement `hasMore`, and wire `loadMore()` to the same status-filtered endpoint pattern used by `myOpportunitiesProvider`.

- [ ] **Step 4: Invalidate the mounted my-kolabs list after create flow returns**

When the create flow closes from the community shell FAB, refresh both dashboard and my-kolabs state so the new kolab becomes visible immediately.

- [ ] **Step 5: Re-run the targeted provider tests**

Run: `flutter test test/features/kolab/providers/my_kolabs_provider_test.dart`

### Task 4: Verification

**Files:**
- Modify: changed files above

- [ ] **Step 1: Format touched Dart files**

Run: `dart format lib test`

- [ ] **Step 2: Run targeted regression tests**

Run:
`flutter test test/config/routes/community_route_test.dart test/features/kolab/screens/intent_selection_screen_test.dart test/features/kolab/providers/kolab_form_provider_test.dart test/features/kolab/providers/my_kolabs_provider_test.dart`

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`

- [ ] **Step 4: Report evidence**

Summarize which review findings were fixed, what commands were run, and any residual risk if a behavior still lacks direct test coverage.
