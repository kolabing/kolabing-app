# Task: Post-completion Collaboration Feedback Sheet

## Status
- Created: 2026-05-21
- Started: 2026-05-21
- Completed: 2026-05-21

## Description
After a business marks a collaboration as `completed`, prompt them with a short multi-step feedback survey: star rating, content output (stories + posts/reels), revenue, expectation match, and recommendation. Submit to the (to-be-built) backend endpoint. Implementation assumes the endpoint exists; while it doesn't, the client falls back to debug log + soft error toast.

Backend ticket: `kolabing-v2/.agent/todo/BE-XXX-collaboration-feedback-endpoint.md`.

## Related API Endpoints
- `POST /api/v1/collaborations/{id}/feedback` (assumed, see backend ticket)
- `GET  /api/v1/collaborations/{id}/feedback` (assumed; surfaces "already submitted" state)

## Assigned Agents
- [x] @ui-designer
- [x] @flutter-expert

## Progress

### UX Design
**Status:** Done
- Multi-step bottom sheet (1 question per step) with linear progress + Back/Next.
- Steps:
  1. **Star rating** — 5 tappable stars (required to advance).
  2. **Stories posted** — bucket selector `0 / 1-5 / 6-10 / 11-15 / 16-30 / 31-50 / 50+` (skippable).
  3. **Posts / reels** — same buckets (skippable).
  4. **Revenue** — EUR amount input + "I'd rather not say" toggle (skippable).
  5. **Met expectations** — optional 1-5 chips + optional comment (all skippable).
  6. **Would recommend** — Yes / No tiles (required).
  7. **Review & submit** — recap card listing answers, primary "SUBMIT FEEDBACK" button.
- Dismiss / swipe-down only valid before submission; warn with snackbar that progress is lost.
- After successful submit: thank-you state inside the sheet for ~1.2s → auto-close → re-invalidate `collaborationDetailProvider`.
- If backend returns 404 (endpoint not yet shipped), show a soft warning toast: "Saved locally — backend pending."

### Flutter Implementation
**Status:** Done
- New model: `lib/features/collaboration/models/collaboration_feedback.dart`
  - Enum `OutputBucket` with `apiValue` (`0`, `1-5`, ...) + `label`.
  - Class `CollaborationFeedbackDraft` with `copyWith` + `toPayload()`.
- New provider: `lib/features/collaboration/providers/collaboration_feedback_provider.dart`
  - `submitCollaborationFeedback(id, draft)` posts to `/collaborations/{id}/feedback`; on 404 throws `FeedbackEndpointMissingException` (soft handled in UI).
- New widget: `lib/features/collaboration/widgets/collaboration_feedback_sheet.dart` — `PageView`-based stepper.
- `_FinishCollaborationSection._confirmAndFinish` invokes the sheet after a successful `markCollaborationCompleted`.
- Follow-up: `_LeaveReviewSection` in `collaboration_detail_screen.dart` — a soft-yellow card with a "LEAVE REVIEW" button shown on completed collaborations for business users when `collaboration.feedbackSubmittedAt == null`. Re-invalidates the detail provider after submission so the card disappears.
- Model: added `feedbackSubmittedAt` (nullable `DateTime`) to `Collaboration` + `fromJson` parses `feedback_submitted_at`. Until the backend ships, this field is always null and the CTA always shows for completed business collaborations — exactly the desired fallback.

## Notes
- Bucket order/text matches the backend ticket exactly so the contract is single-sourced.
- v1 = business audience only (community feedback is a v2 follow-up).
- Revenue captured in **cents** on the wire (`revenue_amount_cents`) to avoid float drift.
