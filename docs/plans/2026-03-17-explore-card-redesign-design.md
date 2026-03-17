# Explore Card Redesign - Full-Screen Swipe Cards

**Date:** 2026-03-17
**Status:** Approved

## Overview

Replace the current scrollable list of `OpportunityCard` widgets in the Explore tab with full-screen, vertically-swipeable Tinder/Hinge-style cards featuring image slideshows, gradient overlays, and a detail bottom sheet.

## Card Structure

### Main Card (Full Screen)

```
┌─────────────────────────────────┐
│  "Filtering for..."  pill       │  ← tappable, opens filter/search sheet
├─────────────────────────────────┤
│                                 │
│   IMAGE AREA (PageView)         │
│   Horizontal swipe for images   │
│                                 │
│      ● ○ ○  dot indicators      │
│                                 │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← gradient: transparent → black
│ Creator Name                    │
│ [Category] [Category] [Cat...]  │
│ Short description... show more  │
│ [M] [Tu] [W] [Th] [F] [Sa][Su] │  ← day availability chips
└─────────────────────────────────┘
```

### Navigation Model
- **Vertical swipe (up/down):** Next/previous opportunity (PageView)
- **Horizontal swipe (left/right):** Browse images within a card
- **Tap on card:** Opens detail bottom sheet
- **Tap on filter pill:** Opens search/filter sheet

### Image Area
- Full-bleed images filling ~75% of card height
- Horizontal PageView for multiple images
- Dot indicators centered, just above gradient zone
- No images fallback: gradient background (dark with category-themed accent) + large creator avatar (120px) centered

### Gradient Overlay
- Bottom 35% of card: `LinearGradient(transparent → black)`
- All text overlaid in white on the gradient

### Overlaid Information
1. **Creator name** - Rubik 22px w700, white
2. **Category chips** - rounded pills, yellow bg, black text (max 3)
3. **Description** - OpenSans 14px, white 80% opacity, 2 lines max, "show more" link
4. **Availability day chips** - row of 7 day abbreviations (M, Tu, W, Th, F, Sa, Su)
   - Available: blue filled (#2196F3), white text
   - Unavailable: white 20% opacity outline, white 40% text
   - Uses `recurringDays` field (1=Mon..7=Sun) for recurring mode
   - For one_time/flexible: show date range instead of day chips

### Detail Bottom Sheet (on tap)
- Slides up from bottom, covers ~85% of screen
- Darkened/blurred background
- Content:
  - Creator avatar (64px) + name + type badge
  - Full description (scrollable)
  - Offer summary (what business offers)
  - Location info (city, venue mode, address)
  - Date range
  - Two CTAs: "Yes, I'd like to Kolab" (primary yellow) + "Not at the moment" (outlined)
  - Close (X) button top right

### Top Filter Bar
- Replaces the current header/search bar
- Single pill: "Filtering for..." or "All Opportunities"
- Tap opens a bottom sheet with search + filter chips (reuse existing filter logic)
- NotificationBell stays in top right

## Files to Create/Modify

### New Files
- `lib/widgets/explore_card.dart` - The full-screen swipe card widget
- `lib/widgets/explore_detail_sheet.dart` - Detail bottom sheet
- `lib/widgets/explore_filter_sheet.dart` - Search + filter bottom sheet

### Modified Files
- `lib/features/business/screens/explore_screen.dart` - Replace ListView with PageView, new layout

## Data Model Notes
- Current `Opportunity` model has `offerPhoto` field (single image) - use this for now
- `creatorProfile.avatarUrl` as secondary image/fallback
- `recurringDays` field (List<int>) for day availability
- No multi-image support yet - design for it but fallback to single image + avatar

## States
- **Loading:** Full-screen shimmer with gradient placeholder
- **Empty:** Centered illustration + "No opportunities" message
- **Error:** Centered error with retry button
- **Success:** Full-screen PageView with cards
- **Detail sheet:** Shown on card tap
