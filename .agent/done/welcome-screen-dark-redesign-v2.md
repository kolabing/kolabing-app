# Task: welcome-screen-dark-redesign

## Status
- Created: 2026-05-17 13:55
- Started: 2026-05-17 13:55
- Completed:

## Description
Second iteration of the welcome screen. User reverted from warm beige back to **deep black
background with subtle dark-brown/yellow gradient**, vibrant neon yellow accent (#FFD700),
floating pill tags, a horizontal 2-card carousel pitching to community (FUND YOUR DREAMS)
and business (UNLOCK REAL REACH) sides, "Trusted by" social proof row, big yellow CTA
"İŞ BİRLİĞİNE BAŞLA", LOGIN link.

Reference: user-supplied screenshot at 13:45 on 2026-05-17.

## Constraints
- File: `lib/features/auth/screens/welcome_screen.dart` (rewrite again).
- Keep navigation actions: CREATE-ACCOUNT-equivalent ("İŞ BİRLİĞİNE BAŞLA") → `KolabingRoutes.userTypeSelection`; LOGIN → `KolabingRoutes.login`.
- This screen overrides the calm-beige system intentionally per user request. Introduce one local accent constant `_kAccentYellow = Color(0xFFFFD700)` rather than mutating `KolabingColors`.
- Use Flutter-painted abstract illustrations on cards (NO new image assets).
- Carousel uses `PageView`; auto-advance optional (every 4s) but pauses when user swipes.

## Assigned Agents
- [x] @ui-designer (spec)
- [x] @flutter-expert (implementation)

## Notes
Old beige version is preserved in git history (last commit on this file). User explicitly
asked for the dark treatment described in the prompt.
