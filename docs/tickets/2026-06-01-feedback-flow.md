# TICKET — Forced rich feedback on collaboration completion

**Date:** 2026-06-01 · **Owner split:** Backend (`kolabing-v2`) + App (`kolabing-app`)
**Priority:** High · **Related:** BACKLOG IF-5

## Problem
Closing a Kolab should **force structured feedback**, and a collaboration should
only become `completed` once feedback is submitted. Today:
- The app marked `/complete` **first**, then showed an *optional* "Leave a review"
  CTA afterwards (wrong order; skippable).
- The only feedback endpoint is `POST /collaborations/{id}/review` which accepts
  just `rating` (required), `body` (optional), `would_collaborate_again` (optional)
  → writes the lean `collaboration_reviews` table.
- The richer `collaboration_feedback` table **exists in the DB**
  (`rating, reviewer_role, expectation_match, would_recommend, posts_reels,
  stories_posted, revenue, benefits`) but has **NO API route** —
  `POST /collaborations/{id}/feedback` returns **404** (verified live 2026-06-01).

## App-side (DONE 2026-06-01, interim)
`kolab_completion_sheet.dart` reordered so feedback is the forced closing step:
Confirm → mark complete → **required feedback (rating mandatory)** → celebration →
done. Sheet is non-dismissible; you cannot reach celebration/close without
submitting. Still posts the lean `/review` (only fields available today).

## Backend work (REQUIRED to finish)
1. **Add `POST /api/v1/collaborations/{id}/feedback`** writing `collaboration_feedback`:
   - Required: `rating` (1–5), `reviewer_role` (creator|applicant — derive from auth),
     `expectation_match` (bool), `would_recommend` (bool).
   - Optional: `posts_reels` (int), `stories_posted` (int), `revenue` (numeric),
     `benefits` (text). One row per (collaboration, reviewer_profile).
   - 422 on missing required; 403 if caller isn't a participant; 409 if already
     submitted.
2. **Gate completion on feedback.** Make `/complete` (or a combined endpoint) only
   transition `→ completed` once the caller's feedback row exists — so the
   collaboration "only closes when feedback is added" server-side, not just in UI.
   Recommend: status flips to `completed` when the *acting* party submits; the
   other party is still prompted to give their feedback on next open.
3. Keep/retire `/review`: either fold `collaboration_reviews` into feedback, or
   keep review as the public rating and feedback as the private business metrics.

## App-side work (AFTER backend ships)
- Swap the completion sheet's `/review` call for `/feedback`.
- **Role-aware fields** (per spec): business sees `revenue`, `stories_posted`,
  `posts_reels`; both see `rating`, `expectation_match`, `would_recommend`,
  `benefits`.
- Make `/complete` depend on a successful `/feedback` (atomic once backend gates).

## Acceptance
- Completing a Kolab is impossible without submitting feedback (server-enforced).
- Business feedback captures content volume (stories/reels) + revenue estimate.
- `collaboration_feedback` rows surface in the admin stats Quality section.
