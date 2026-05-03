# Fix: Duplicate kolabing request created on submit

## Status
- Created: 2026-05-03 17:57
- Started: 2026-05-03 17:57
- Completed: 2026-05-03 17:58

## Issue Description
When the user taps "Publish Request" (or "Save Draft") on the Create Collab Request
screen, the request gets created TWICE. The button must become disabled after the
first tap so subsequent taps do not trigger another API call.

## Root Cause
Rapid double-taps fire the captured `onPressed: _handlePublish` callback multiple
times before the next frame rebuilds the button as disabled.

Timeline:
1. Frame N renders the button with `onPressed = _handlePublish` (isBusy=false).
2. Tap 1 fires `_handlePublish` → validates → calls `saveAndPublish()` which
   synchronously sets `state.isPublishing = true`, then `await`s `POST /opportunities`.
3. Before Frame N+1 rebuilds the button as disabled, Tap 2 fires the SAME captured
   callback. `_handlePublish` runs again and calls `saveAndPublish()` a second time
   → second `POST /opportunities` → duplicate row.

The screen-level `isBusy` UI guard alone is insufficient because Flutter rebuilds
on the next frame, not synchronously after a state change.

## Affected Files
- `lib/features/opportunity/providers/opportunity_form_provider.dart`
  - `saveDraft()` and `saveAndPublish()` need re-entry guards.

This shields BOTH callers (shared provider):
- `lib/features/business/screens/create_collab_request_screen.dart`
- `lib/features/community/screens/create_opportunity_screen.dart`

## Fix Applied
Added synchronous re-entry guard at the top of `saveDraft()` and `saveAndPublish()`:
```dart
if (state.isSubmitting || state.isPublishing) return false;
```
The second tap's call sees `isPublishing == true` (set synchronously by the first
tap before its `await`) and returns `false` immediately — no API call is made.
Once the in-flight API call resolves, `isPublishing` flips back to `false` and the
form can be submitted again normally.

## Testing
- [ ] Tap "Publish Request" rapidly → only ONE request created
- [ ] Tap "Save Draft" rapidly → only ONE draft created
- [ ] Single tap still works as before (success dialog shows)
- [ ] Failed submission → user can retry (state flag resets in catch/finally)
- [ ] `dart analyze` passes

## Notes
- Minimal, root-cause fix — no UI/UX changes.
- Provider-layer fix protects every caller, present and future.
