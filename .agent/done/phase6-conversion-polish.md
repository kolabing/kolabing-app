# Task: phase6-conversion-polish

## Status
- Created: 2026-05-21 12:15
- Started: 2026-05-21 12:15
- Completed:

## Description
Phase 6 — conversion polish: D3, C9, C5, F1, D1, E4, H5.

## Per-bug findings + action

| Bug | Status after audit | Action |
|---|---|---|
| **D1** Multi-category for businesses | **Already done**: `business_step2_screen.dart:341` says "Select up to 3 categories". `OnboardingData.businessTypeIds`/`businessTypeSlugs` are `List<String>` (lines 70/73). | Verified, no change. |
| **C5** Cannot accept a Kolab | Likely covered by Phase 3 C13 (contact-methods step removal — that field was the silent blocker) + Phase 1.5 auth refresh hardening. | Verify on next QA; no extra change. |
| **E4** Path-picker copy | Daniel explicitly said "Not a bug, FYI" — alternative framing test for later. | No change. |
| **H5** Card information density | Gated on H1 (mini-model match breakdown) — Phase 5 deferred (PM decision). | Defer until H1 ships. |
| **D3** Finish Collaboration action | **Real gap**: `CollaborationStatus.completed` enum exists (collaboration.dart:22) but no API action / UI button surfaces it. Collaborations have no terminal state. | **Fix**: add "Mark as completed" button on `collaboration_detail_screen.dart` (visible when status is `scheduled`/`inProgress`). Add `markCompleted` to `CollaborationDetailNotifier`. Backend endpoint `POST /collaborations/{id}/complete` is the TODO. |
| **C9** Discover→community profile dismiss-only | Currently the screen `community_profile_screen.dart` is the community's OWN profile (settings, sign out). The "Discover → tap a community → only Not right now" experience needs a separate "view-only" community detail screen for businesses, with a primary CTA to send a Kolab proposal. | **Defer to a Phase 6.1 task** — needs a new screen + routing. Document spec. |
| **F1** Carousel dot indicator placement | Multiple `PageView.builder` usages in `explore_screen.dart`, `event_detail_screen.dart`, `photo_viewer_dialog.dart`, `explore_swipe_card.dart`. Daniel's screenshot was on a Kolab/opportunity card. | **Fix**: locate the dot indicators on the explore card and move them either to the bottom of the image area or directly above the title (Daniel's preference). |

## Changes applied

### D3 — Finish Collaboration
- `lib/features/collaboration/providers/collaboration_detail_provider.dart`:
  - Add `markCompleted()` method that POSTs to `$baseUrl/collaborations/$id/complete`. Uses the existing auth+http patterns. Returns updated `Collaboration` from response.
- `lib/features/collaboration/screens/collaboration_detail_screen.dart`:
  - Add a "Mark as completed" button section visible only when `status` is `scheduled` or `inProgress`. Tapping shows a confirmation dialog; on confirm, calls the new method and invalidates the provider.
- After completion, the collaboration appears with the `completed` status badge (already styled).

### F1 — Carousel dot indicators
- Inspect `explore_swipe_card.dart` (Daniel's report mentions Explore cards) → reposition the dot indicators to immediately above the post title, where attention naturally lands.

## Out of scope / deferred (with clear next-steps)

- **C9** Discover→community CTA. Needs:
  1. A new read-only `CommunityPublicProfileScreen` that businesses see when tapping a community card in Discover.
  2. Primary CTA "Send a Kolab proposal" that routes to the existing Create Kolab flow with the community pre-selected as recipient.
  3. Secondary "Save for later" / "Not right now" combined into a single dismiss control.
- **D3 backend endpoint** — `POST /collaborations/{id}/complete` needs to be implemented server-side. The client sends an empty body; expects 200 with updated collaboration JSON. Flag for backend team.

## Verification
1. `flutter analyze` clean on touched files.
2. Existing tests pass.
3. Manual D3: open a `scheduled` collaboration → see "Mark as completed" → tap → confirm → button replaced by "Completed" badge.
4. Manual F1: scroll the Explore card carousel → dots are visible above the title.

## Files touched
- `lib/features/collaboration/providers/collaboration_detail_provider.dart`
- `lib/features/collaboration/screens/collaboration_detail_screen.dart`
- (F1) `lib/widgets/explore_swipe_card.dart` (if dots originate here)
