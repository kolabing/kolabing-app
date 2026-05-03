# Fix: Publish kolab shows "Draft Saved!" modal instead of "Kolab Published!"

## Status
- Created: 2026-05-03
- Started: 2026-05-03
- Completed: 2026-05-03

## Issue Description
After publishing a new kolab on the review screen, the success dialog displays "Draft Saved! / You can continue editing later." instead of the correct "Kolab Published! / Your kolab is now visible in Explore." message.

## Root Cause
In `lib/features/kolab/providers/kolab_form_provider.dart` `saveAndPublish()` (lines 825-829), the success state is set in a single `copyWith`:

```dart
state = state.copyWith(
  kolab: published,
  isPublishing: false,   // <-- reset BEFORE the listener observes success
  isSuccess: true,
);
```

The Riverpod listener in `lib/features/kolab/screens/kolab_flow_screen.dart` (line 64-67) reads `next.isPublishing` to decide which dialog copy to show:

```dart
if (next.isSuccess && !(prev?.isSuccess ?? false)) {
  _showSuccessDialog(context, ref, next.isPublishing); // already false
}
```

Because `isPublishing` is reset to `false` in the same state transition that flips `isSuccess` to `true`, the dialog ALWAYS receives `wasPublished = false` and shows the draft-saved copy — even for the publish flow.

## Affected Files
- `lib/features/kolab/screens/kolab_flow_screen.dart`

## Fix Applied
Use `prev?.isPublishing` (the publishing flag from the state right before success was set) instead of `next.isPublishing` when invoking `_showSuccessDialog`. This correctly distinguishes the publish flow (where the prior state had `isPublishing: true`) from the draft flow (where it was `false`).

Minimal one-line change at the listener call site — no provider state-shape change required, no risk of regressions in the draft path.

## Testing
- [ ] Publish a new kolab → success dialog reads "Kolab Published!" with Explore copy
- [ ] Save a kolab as draft → success dialog reads "Draft Saved!" with continue-editing copy
- [ ] Edit + publish an existing draft → "Kolab Published!"
- [ ] Edit + save existing draft → "Draft Saved!"
- [ ] No analyzer warnings introduced

## Notes
Considered alternatives:
1. Inspect `next.kolab.status == 'published'` — relies on backend reflecting the published status in the same response (true today, but couples UI to API field). Rejected as less direct.
2. Add a dedicated `wasPublishOperation` field to `KolabFormState` — overkill for a one-line bug; expands the state surface unnecessarily.
3. Reorder the `copyWith` to keep `isPublishing: true` until after the dialog opens — would require a second `copyWith` and risks the action bar showing the spinner past the success transition.

The chosen fix is minimal, local to the screen, and uses information already present in the listener's `prev` argument.
