# Task: phase1-4-fix-draft-save-load

## Status
- Created: 2026-05-18 15:30
- Started: 2026-05-18 15:30
- Completed:

## Description
B3: "Draft Saved!" modal appears but the saved draft doesn't show up in the drafts list. Loading existing drafts also reportedly errors.

## Root cause
`MyKolabsNotifier` caches the list in state. When user creates a draft via `kolab_form_provider.saveDraft()`, the success dialog dismisses and the dashboard reappears — but `myKolabsProvider` is never invalidated/refreshed. The stale cached list (without the new draft) is shown.

Same issue applies to publish: a published kolab won't update the visible Drafts filter, but the user navigates away so this is less obvious.

Files involved:
- `lib/features/kolab/screens/kolab_flow_screen.dart` (success dialog DONE handler)
- `lib/features/kolab/providers/my_kolabs_provider.dart` (the list provider)

## Changes applied
- `lib/features/kolab/screens/kolab_flow_screen.dart`:
  - In `_showSuccessDialog` DONE button handler, call `ref.invalidate(myKolabsProvider)` before popping back to dashboard. This forces the dashboard's drafts/published list to refetch with the new entry.
  - Same applies on success after publish (existing kolabs list shows updated status).

## Verification
1. `flutter analyze` clean.
2. Existing `my_kolabs_provider_test.dart` still passes.
3. Manual: Create a draft, tap Save → "Draft Saved!" → DONE → return to dashboard → tap Drafts filter → new draft appears.

## Files touched
- `lib/features/kolab/screens/kolab_flow_screen.dart`

## Notes
- Daniel also reported "loading drafts errors." That symptom is likely the SAME stale-state issue: opening the drafts tab on a fresh app start re-fetches and works; but after the success dialog the cache is stale. If load actually errors with a server response, we'll see it once Phase 1.5 (auth refresh) lands — flagged for that task.
