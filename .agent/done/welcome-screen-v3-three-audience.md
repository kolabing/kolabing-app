# Task: welcome-screen-v3-three-audience

## Status
- Created: 2026-05-17 14:05
- Started: 2026-05-17 14:05
- Completed:

## Description
v3 rebuild after user rejected v2 ("berbat / terrible"). Direction approved (option B):
3-card horizontal carousel with real Lucide icons, all English, more prominent logo,
"IRL" tag replaced with REWARDS, trusted-by glyph row removed, dropping the abstract
painted illustrations entirely. Now serves three audiences explicitly: Business, Community,
Attendee.

## Constraints
- File: `lib/features/auth/screens/welcome_screen.dart`
- All copy in English
- Use `lucide_icons` package
- Keep the dark/black palette with #FFD700 accent from v2
- Keep nav: GET STARTED → `KolabingRoutes.userTypeSelection`, LOGIN → `KolabingRoutes.login`

## Three audience cards
1. BUSINESS — icon `LucideIcons.target`, headline "REACH REAL AUDIENCES", sub "Sponsor communities and events that match your brand. Pay for impact, not impressions."
2. COMMUNITY — icon `LucideIcons.partyPopper`, headline "FUND YOUR EVENTS", sub "Get brand sponsorships to power your meetups, parties, and gatherings."
3. ATTENDEE — icon `LucideIcons.ticket`, headline "DISCOVER & EARN", sub "Find events near you, check in, and unlock rewards from the brands you love."

## Floating tags (4, English): OFFERS, REWARDS, CAMPAIGNS, EVENTS

## Assigned Agents
- [x] @flutter-expert
