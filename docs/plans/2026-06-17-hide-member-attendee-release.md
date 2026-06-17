# Release plan — hide member/attendee, ship community + business only

> Goal (Daniel, 2026-06-17): a branch that hides ALL member/attendee features so
> the release exposes only **business** and **community** (as business partners).
> Each hidden surface shows a **"Coming soon"** placeholder. Fully reversible —
> keep all code, gate behind ONE flag so the member layer can be switched on later.

## Principle
- **Single master switch:** `FeatureFlags.attendeeEnabled = false` (compile-time, in
  `lib/config/constants/feature_flags.dart`). Everything below reads this flag.
  Flip to `true` to restore the whole member layer with zero other changes.
- **Hide, don't delete.** No code/screens removed. Entry points disabled + routes
  guarded + a shared `ComingSoonView` shown where appropriate.
- **Branch:** `release/community-business-only`.

## New shared widget
- `lib/widgets/coming_soon_view.dart` — `ComingSoonView({title, message, icon})`:
  centered illustration + "Coming soon" + one-line copy. i18n (en/es/ca). Used by
  every gated surface that's still reachable as a tab/route.

## Surface-by-surface plan

### A. Signup — attendee card (KEEP business + community)
- `lib/features/auth/screens/user_type_selection_screen.dart:227` — render the
  attendee `SelectionCard` with `isEnabled: false`, `badgeLabel: 'COMING SOON'`,
  `descriptionOverride` ("Event discovery & check-ins are coming soon"). Pattern
  already exists (`selection_card.dart` supports `isEnabled`/`badgeLabel`). Tap is
  inert when disabled. (Decision A: disable-with-badge vs fully remove — recommend
  disable-with-badge so users see it's coming.)

### B. Route guards (deep-link + existing-account safety)
- `lib/config/routes/routes.dart` redirect / `auth_navigation.dart:resolveAuthDestination`:
  when `!attendeeEnabled`, any attendee/member/gamification route resolves to a
  ComingSoon screen (or login). Routes to guard (all from the inventory):
  `/auth/register/attendee`, `/onboarding/attendee/step1..4`, `/attendee`,
  `/attendee/profile`, `/communities/discover`, `/community/:id/profile`
  (attendee/member view), `/rewards`, `/attendee/events/:id/qr|checkins|challenges*`.
- **Existing attendee logins:** `resolveAuthDestination` currently sends
  `isAttendee` → `/attendee`. With the flag off, route them to a full-screen
  ComingSoon ("The member app is coming soon") + sign-out option. (Decision B.)

### C. The "Community" nav tab (gamification/members/rewards) → Coming soon
- `lib/features/community/screens/community_main_screen.dart:164` — Tab 4
  (`_CommunityLeaderTab` → `CommunityDetailScreen` Rewards/Members/Events). This
  surfaces the **gamification/member layer** (rewards config, member roster,
  challenges) which isn't release-ready. When `!attendeeEnabled`, render
  `ComingSoonView` in this tab instead (keep the tab + flag icon visible, show the
  placeholder on tap — matches "on each screen a coming soon").
- Same for any equivalent tab in `business_main_screen.dart` if present.
- **Decision C (important):** the community-OWNER's own community management
  (roster/tiers/rewards config) lives in this same tab. Confirm we hide the WHOLE
  tab as coming-soon (recommended per Daniel's "community tab" example), vs keeping
  owner-management but hiding only the member/gamification bits. Recommend: whole
  tab → Coming soon for release (gamification ships later as one unit).

### D. Member community layer (discover / join / member views)
- `discover_communities_screen.dart`, `attendee_community_profile_screen.dart`
  (member view + join), `my_communities_screen.dart` (member memberships). These
  are only reachable from the attendee shell + the Community tab — both gated in
  A/B/C — so they become unreachable. Defensive: any residual entry point (CTAs)
  guarded by `attendeeEnabled`. KEEP the community-as-partner profile/edit, kolab
  create/apply, chats (those are business-partner features, not member).

### E. Gamification surfaces (rewards/badges/leaderboard/stats/spin/wallet/challenges/QR)
- `lib/features/gamification/**` + `personal_rewards_screen` (`/rewards`). All
  reachable only via the attendee shell / Community tab → unreachable once A–C are
  gated. Add `attendeeEnabled` guards on any cross-links. The community **wallet/
  referrals** for owners — Decision D: keep (owner earnings) or hide (part of
  gamification)? Recommend hide for release if it depends on the member economy.

## Decisions needed before building
- **A.** Attendee signup card: disable-with-"COMING SOON" badge (recommended) vs fully remove.
- **B.** Existing attendee accounts on login: ComingSoon screen + sign-out (recommended) vs hard block.
- **C.** Community "Community" tab: whole tab → Coming soon (recommended, matches the brief) vs keep owner-management only.
- **D.** Community wallet/referrals + any owner-facing rewards: keep vs hide (depends if they need the member economy).
- **E.** `Friends` + `Event detail` RSVP/check-in: confirm these are attendee-only → gate (Event detail stays for organizers, gate the attendee RSVP/QR actions).

## Reusable patterns (already in code)
- `FeatureFlags` (`feature_flags.dart`) — add `attendeeEnabled`.
- `SelectionCard(isEnabled, badgeLabel, descriptionOverride)` — attendee card.
- Existing self-gating (404 → empty/coming-soon) in discover/personal-rewards.
- Existing localized "coming soon" strings to reuse.

## Testing / rollout
- Widget tests: attendee card disabled; attendee routes → ComingSoon; Community tab → ComingSoon; business + community happy paths untouched.
- Manual: sign up business + community (full flow works); attendee card shows badge; deep-link `/attendee` → ComingSoon.
- i18n en/es/ca for ComingSoon copy.
- **Re-enable later:** flip `attendeeEnabled = true` → member layer returns; no other revert.

## Scope guard
KEEP intact: business + community accounts, kolab create/list/edit, Explore, apply/applications, collaborations, dashboard, chats, community-as-partner profile. HIDE: attendee accounts/onboarding/shell, member community discovery/join, the gamification/rewards/challenges/check-in layer, and the member "Community" tab.
