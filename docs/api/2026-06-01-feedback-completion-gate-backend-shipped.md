# Feedback / Completion Gate — Backend SHIPPED (2026-06-01)

> Status: **Shipped in `kolabing-v2`.** This is the authoritative app-side
> integration contract for the forced-feedback completion gate (closes the
> server side of BACKLOG **IF-5** and **IF-2**). The Flutter app must now build
> against the contract below. Spec/origin: `docs/tickets/2026-06-01-feedback-flow.md`.

## What shipped

### Endpoints
- `POST /collaborations/{id}/feedback` — submit rich feedback.
- `PUT /collaborations/{id}/feedback` — edit own feedback.
- `POST /collaborations/{id}/complete` — **now gated** on feedback (see error codes).
- `POST /admin/kolabs/{kolab}/collaboration/complete` — maintainer force-complete.

**Error codes** wired on the gated `/complete` (and feedback) paths:
| Code | Meaning |
|---|---|
| `awaiting_own_feedback` | Viewer must submit their feedback before completion proceeds. |
| `awaiting_partner_feedback` | Viewer done; waiting on the other party. |
| `feedback_locked` | Feedback window closed / no longer editable. |
| `feedback_already_submitted` | Duplicate submit attempt. |

The app should branch on these codes (not just HTTP status) to drive the
completion sheet UX — e.g. `awaiting_own_feedback` → open the feedback sheet;
`awaiting_partner_feedback` → show "waiting on partner" state, not an error.

### Legacy `/review` mirror (rollout safety net)
- Legacy `POST /collaborations/{id}/review` calls **auto-create stub `/feedback`
  rows** so the new completion gate still succeeds while old mobile clients are
  in the wild.
- `/review` was **relaxed to accept active collaborations** so legacy clients can
  recover from the new `422` instead of dead-ending.
- Net effect: shipping the new app build is non-breaking; old installs keep working.

### Migration
- `collaborations`: `completion_reason`, `completed_by_profile_id`, `auto_completed_at`.
- `collaboration_feedback`: `mirrored_from_review` flag; `expectation_match` and
  `would_recommend` relaxed to **nullable** (so mirrored stub rows coexist with rich ones).
- Driver-portable (includes the SQLite shadow-column path for the nullable change).

### Service rewiring
- `CollaborationService::complete()` — gates on feedback and **drops the inline XP
  award** (XP now flows through the central ledger, not here).
- `CollaborationService::adminForceComplete()` and `autoComplete()` — new.
- `CollaborationFeedbackService` — owns submit / edit / mirror / pending logic.

### `CollaborationResource` — new fields (per spec Q10)
The collaboration payload now exposes:
- `pending_feedback_from` — who still owes feedback.
- `viewer_must_submit_feedback` — boolean the app can read directly to force the sheet.
- `own_feedback` — the viewer's own submitted feedback.
- `partner_feedback` — **cross-visible subset only** (never the private metrics like
  revenue / posts counts — those stay private to the submitter).
- Completion-metadata trio: `completion_reason`, `completed_by_profile_id`, `auto_completed_at`.

### Auto-timeout
- Command `app:auto-complete-stale-collaborations`, cron'd **daily at 03:00**.
- Threshold: **7 days** from `scheduled_date`, and requires **≥1 feedback row**.
- Both knobs configurable in `config/collaborations.php`.

### Admin UI
- Force-complete form added to the kolab lifecycle panel (mirrors the existing force-cancel).

### Docs
- Both `ROLES-*` files in the backend repo updated and dated 2026-06-01.

## App-side follow-up (not done here)
- Wire the completion sheet to read `viewer_must_submit_feedback` /
  `pending_feedback_from` and branch on the four error codes above (IF-5).
- Build the rich feedback sheet against `POST/PUT /feedback`
  (rating, expectation_match, would_recommend, stories_posted, posts_reels, revenue, benefits).
- Render `partner_feedback` (cross-visible subset) and the completion-metadata trio
  on the kolab detail screen.
- End-to-end verify both-parties-confirm → completed transition with seeded data (IF-2).
