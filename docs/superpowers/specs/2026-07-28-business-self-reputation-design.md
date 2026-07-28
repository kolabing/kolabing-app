# Design — Reputation block on the business's own profile (audit #13, remaining half)

> Date: 2026-07-28 · Author: Volkan (with Claude) · Status: approved, pre-implementation
> Source: mobile-audit fix-list item **#13** (M-04). Repo: **kolabing-app** only (no backend change).
> Ticket: #84.

## Problem

The business owner cannot see their own reputation. The public / third-party-viewed
profile renders `_ReputationSummaryCard` (`public_profile_screen.dart`), but the
owner's self-view (`business_profile_screen.dart`) has no reputation section. Audit #13
also lists **completed Kolabs**, which the current card does not render on either view.

## Grounding (verified against current code)

- `_ReputationSummaryCard({required Reputation? reputation})` is **private** in
  `lib/features/profile/screens/public_profile_screen.dart:1281-1351`. It renders avg
  rating, review count, and unique partner count (hidden when 0), with an empty state
  when `reputation == null || !reputation.hasReviews`. No completed-Kolabs, no
  partner-status badge.
- Public data: `publicProfileProvider(profileId)` → `PublicProfileService.getPublicProfile`
  → `GET /api/v1/profiles/{id}` → `PublicProfile.fromJson`. `PublicProfile` exposes
  `reputation` (`Reputation{averageRating, reviewCount, uniquePartnerCount, breakdown}`,
  keys `average_rating`/`review_count`/`unique_partner_count`) and
  `completedKolabsCount` (key `completed_kolabs_count`).
- Self-view: `business_profile_screen.dart` uses `profileProvider` → `UserModel` /
  `BusinessProfile` (`GET /auth/me`). It carries **no** reputation fields.
  `BusinessProfile` has `id`.
- `PartnerStatusBadge` is **not on master** (only on unmerged PR #70 / audit #14).

## Decisions (from brainstorming)

1. **Data source:** reuse `publicProfileProvider(myProfileId)` on the self-view — no
   backend change; the single call returns both `reputation` and `completedKolabsCount`.
2. **Partner-status badge:** out of scope (blocked on PR #70 / audit #14).
3. **Completed Kolabs:** add to the shared card so it shows on **both** the public and
   self views.

## Changes (kolabing-app only)

### 1. Extract + extend the shared widget
Move `_ReputationSummaryCard` → a public `ReputationSummaryCard` in
`lib/features/profile/widgets/reputation_summary_card.dart`:
```dart
ReputationSummaryCard({ required Reputation? reputation, int? completedKolabsCount })
```
Keeps avg rating / review count / unique partners; adds a **Completed Kolabs** stat,
shown only when `completedKolabsCount != null && completedKolabsCount > 0` (mirrors the
unique-partners "hide when 0" rule). Empty-state behaviour unchanged. Update
`public_profile_screen.dart` to consume the extracted widget and pass
`completedKolabsCount: profile.completedKolabsCount`.

### 2. Wire the self-view
In `business_profile_screen.dart`, after the Profile Header card and before the
Subscription section, render a reputation block driven by
`ref.watch(publicProfileProvider(businessProfile.id))`:
- **loading** → a light placeholder (or `SizedBox.shrink()`), never blocking;
- **error** → `SizedBox.shrink()` (reputation is non-critical; the profile still renders);
- **data** → `ReputationSummaryCard(reputation: profile.reputation,
  completedKolabsCount: profile.completedKolabsCount)` — the empty state covers the
  no-reviews case for a new owner.
- If `businessProfile == null` or `businessProfile.id` is empty, skip the block.

### 3. i18n
New key `reputationCompletedKolabs` (e.g. "Completed Kolabs" / "Kolabs completados" /
"Kolabs completats") in en/es/ca; run `flutter gen-l10n`.

## Error handling

The self-view never fails because of reputation: a failed/absent
`publicProfileProvider` fetch renders nothing in that slot. The owner's own profile
content (header, subscription, gallery, contact, account) is unaffected.

## Testing

- **Widget** (`ReputationSummaryCard`): renders rating/reviews/partners + completed-Kolabs
  when present; hides completed-Kolabs and unique-partners at 0; shows the empty state
  when `reputation == null` / no reviews.
- **Self-view**: override `publicProfileProvider` with a `PublicProfile` carrying
  reputation → the card renders; override with an error → the profile renders without
  the block.
- **Regression**: existing `public_profile_screen` tests still pass with the extracted
  widget.

## Workflow / delivery

Per CLAUDE.md: ticket #84 → branch `feat/business-self-reputation` off `master` → PR
(`Closes #84`), mandatory template, screenshots of the self-view card with and without
reviews (iOS + Android). DoD: `flutter analyze` 0 new, `dart format`, i18n in all three
ARBs, no hardcoded values, BACKLOG updated.

## Out of scope (follow-ups)

- Partner-status badge on the profile (audit #14 / PR #70).
- Adding reputation to `GET /auth/me` to avoid the extra call (optimization only).
