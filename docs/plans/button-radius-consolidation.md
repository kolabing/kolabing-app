# Button Border-Radius Consolidation Plan

**Audited:** 2026-06-09  
**Status:** Pending implementation  
**Scope:** ~50–70 locations across ~25 files

---

## Summary

The codebase has **13 distinct border-radius values** on interactive buttons, with **80–85% hardcoded literals** instead of the `KolabingRadius` tokens that already exist. The global theme correctly uses `StadiumBorder` (pill) for ElevatedButton/OutlinedButton/Chip, but nearly every screen overrides it away with a hardcoded shape.

**Proposed standard:**

| Context | Radius | Token / Shape |
|---------|--------|---------------|
| Primary / secondary buttons (form submits, full-width CTAs) | pill | Remove override → inherit `StadiumBorder` from theme |
| Action buttons in sheets / dialogs (contextual, smaller) | 12px | `KolabingRadius.md` |
| Compact chips (filter, selection) | pill | `KolabingRadius.round` (9999px) |
| Business sub-feature inline buttons | 12px | `KolabingRadius.md` |
| Icon buttons | circle | `BoxShape.circle` (unchanged) |
| Extended FAB | 32px | `KolabingRadius.xxl` (unchanged) |

**Justified exceptions (do not change):**
- `lib/widgets/glass_button.dart` — 999px pill is intentional glass design
- `lib/widgets/navigation/kolabing_fab.dart` — CircleBorder / 32px are correct for FAB variants

---

## Design Token Reference

All tokens are in `lib/config/constants/radius.dart`:

```dart
KolabingRadius.xs    = 4px
KolabingRadius.sm    = 8px
KolabingRadius.md    = 12px   ← standard for contextual buttons
KolabingRadius.lg    = 16px
KolabingRadius.xl    = 24px
KolabingRadius.xxl   = 32px
KolabingRadius.round = 9999px ← pill chips
```

---

## Inconsistency Flags (Critical)

| Role | Files | Radii found | Severity |
|------|-------|-------------|----------|
| Primary auth CTAs (submit, register) | welcome, login, sign_in, forgot_password, reset_password | 12px, 14px, 16px, 18px | 🔴 Critical |
| Completion sheet chips | kolab_completion_sheet.dart | 10px, 12px, 14px, 20px, 28px, 50px | 🔴 Critical |
| Gamification ElevatedButton | reward_detail, stats, spin_wheel, event_discovery | 12px vs 16px | 🟡 Medium |
| Business offering buttons | offering_screen, media_screen, past_events_screen | 8px, 10px, 12px | 🟡 Medium |
| Rewards buttons | referral, withdrawal, wallet, banner | All `KolabingRadius.md` | ✅ Consistent |
| Collaboration detail buttons | collaboration_detail_screen, review sheet | All `KolabingRadius.md` | ✅ Consistent |

---

## File-by-File Change List

### Auth

| File | Location | Current | Change |
|------|----------|---------|--------|
| `lib/features/auth/screens/welcome_screen.dart` | ~303 | 14px | Remove shape override → theme StadiumBorder |
| `lib/features/auth/screens/login_screen.dart` | ~636, ~989 | 12px hardcoded | Remove shape override ×2 |
| `lib/features/auth/screens/sign_in_screen.dart` | ~208, ~232, ~378, ~412 | 12px / 16px hardcoded | Remove shape overrides ×4 |
| `lib/features/auth/screens/forgot_password_screen.dart` | ~437, ~553 | 18px hardcoded | → `KolabingRadius.md` ×2 |
| `lib/features/auth/screens/reset_password_screen.dart` | ~477, ~569 | 12px hardcoded | Remove shape override ×2 |
| `lib/features/auth/screens/attendee_register_screen.dart` | ~424 | 12px hardcoded | Remove shape override |
| `lib/features/auth/widgets/google_sign_in_button.dart` | ~161 | 12px hardcoded | → `KolabingRadius.md` |
| `lib/features/auth/widgets/apple_sign_in_button.dart` | ~50 | 12px hardcoded | → `KolabingRadius.md` |

### Collaboration

| File | Location | Current | Change |
|------|----------|---------|--------|
| `lib/features/collaboration/widgets/kolab_completion_sheet.dart` | ~226, ~352, ~466, ~560, ~654, ~714, ~766 | 10px / 12px / 14px / 20px / 28px / 50px | → `KolabingRadius.md` for interactive chips; `KolabingRadius.xl` for sheet-top radii ×7 |
| `lib/features/collaboration/screens/collaboration_detail_screen.dart` | ~1219, ~1558, ~1764, ~2109 | `KolabingRadius.md` (token, correct) | Normalize syntax: ensure `BorderRadius.circular(KolabingRadius.md)` everywhere ×4 |
| `lib/features/collaboration/widgets/kolab_review_sheet.dart` | ~262 | `KolabingRadius.md` (token, correct) | No change needed |

### Gamification

| File | Location | Current | Change |
|------|----------|---------|--------|
| `lib/features/gamification/screens/reward_detail_screen.dart` | ~279, ~212, ~305, ~355 | 12px / 16px | → `KolabingRadius.md` ×4 |
| `lib/features/gamification/screens/stats_screen.dart` | ~315, ~320, ~349 | 12px / 16px | → `KolabingRadius.md` ×3 |
| `lib/features/gamification/screens/spin_wheel_screen.dart` | ~274, ~310, ~348 | 12px / 16px | → `KolabingRadius.md` ×3 |
| `lib/features/gamification/screens/create_challenge_screen.dart` | ~84, ~97, ~263, ~307, ~313, ~319, ~323, ~444 | 12px hardcoded | → `KolabingRadius.md` ×8 |
| `lib/features/gamification/screens/event_discovery_screen.dart` | ~285, ~332, ~492 | 12px / 20px | → `KolabingRadius.md` ×3 |
| `lib/features/gamification/screens/attendee_home_screen.dart` | ~429, ~473, ~623 | 12px hardcoded | → `KolabingRadius.md` ×3 |
| `lib/features/gamification/screens/event_challenges_screen.dart` | ~428 | 12px hardcoded | → `KolabingRadius.md` |
| `lib/features/gamification/screens/qr_scanner_screen.dart` | ~144, ~208, ~223 | 12px hardcoded | → `KolabingRadius.md` ×3 |
| `lib/features/gamification/screens/initiate_challenge_screen.dart` | ~121, ~381 | 12px hardcoded | → `KolabingRadius.md` ×2 |
| `lib/features/gamification/screens/attendee_profile_screen.dart` | ~210 | 12px hardcoded | → `KolabingRadius.md` |
| `lib/features/gamification/screens/event_qr_code_screen.dart` | ~155 | 12px hardcoded | → `KolabingRadius.md` |

### Kolab / Business

| File | Location | Current | Change |
|------|----------|---------|--------|
| `lib/features/kolab/screens/kolab_flow_screen.dart` | ~345 | 12px hardcoded | → `KolabingRadius.md` |
| `lib/features/kolab/screens/business/offering_screen.dart` | ~213, ~470 | 8px / 10px hardcoded | → `KolabingRadius.md` ×2 |
| `lib/features/kolab/screens/business/past_events_screen.dart` | ~106 | `KolabingRadius.sm` (8px) | → `KolabingRadius.md` |
| `lib/features/kolab/screens/business/media_screen.dart` | ~230 | `KolabingRadius.sm` (8px) | → `KolabingRadius.md` |

### Rewards (already consistent — no changes needed)

`lib/features/rewards/screens/referral_screen.dart`,
`lib/features/rewards/screens/withdrawal_request_screen.dart`,
`lib/features/rewards/screens/wallet_screen.dart`,
`lib/features/rewards/widgets/referral_banner_card.dart` — all use `KolabingRadius.md`. ✅

---

## Implementation Notes

- Line numbers above are approximate — verify before editing.
- Shape override syntax varies: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` and `BorderRadius.circular(KolabingRadius.md)` are both found. Standardize to the former for `ButtonStyle.shape`, the latter for `Container.decoration`.
- For buttons already inheriting `StadiumBorder` from the theme, **removing** the shape override is safer than replacing it with another value.
- After changes, run `flutter analyze` and spot-check the auth flow and gamification screens visually on a simulator.

---

## Expected Outcome

| Metric | Before | After |
|--------|--------|-------|
| Distinct radius values on buttons | ~13 | 3 (pill / 12px / circle) |
| Token adoption rate | ~15–20% | ~95% |
| Hardcoded integer literals | ~55–65 | ~5 (justified exceptions) |
| Auth flow radii | 4 | 1 (pill via theme) |
| Completion sheet chip radii | 6 | 2 |
