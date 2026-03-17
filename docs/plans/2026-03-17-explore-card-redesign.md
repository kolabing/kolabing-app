# Explore Card Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the scrollable OpportunityCard list in the Explore tab with full-screen, vertically-swipeable Tinder-style cards featuring image areas, gradient overlays, category chips, and a detail bottom sheet.

**Architecture:** New `ExploreSwipeCard` widget replaces `OpportunityCard` in `explore_screen.dart`. The Explore screen switches from ListView to a vertical PageView. A new `ExploreDetailSheet` bottom sheet provides full details on tap. Search/filter moves into a tappable pill that opens an `ExploreFilterSheet`.

**Tech Stack:** Flutter, Riverpod 2 (existing providers), GoRouter, Google Fonts, Lucide Icons

---

### Task 1: Create ExploreSwipeCard Widget

**Files:**
- Create: `lib/widgets/explore_swipe_card.dart`

**Description:** Full-screen card widget with:
- Image area (uses `offerPhoto` or gradient fallback with creator avatar)
- Horizontal PageView for future multi-image support (currently 1 image)
- Dot indicators for image count
- Bottom gradient overlay (transparent → black, bottom 35%)
- Overlaid: creator name (Rubik 22px w700 white), category chips (yellow bg, black text, max 3), description (OpenSans 14px, white 80%, 2 lines, "show more"), availability info row
- For recurring mode: day chips (M, Tu, W, Th, F, Sa, Su) - blue filled if in recurringDays, dim outline otherwise
- For one_time/flexible: date range text
- Tap on card body → callback to open detail sheet
- Border radius 20px, margin 16px horizontal

**Data:** Takes `Opportunity` + `onTap` + `onApply` callbacks

---

### Task 2: Create ExploreDetailSheet Widget

**Files:**
- Create: `lib/widgets/explore_detail_sheet.dart`

**Description:** Bottom sheet (85% screen height) shown on card tap:
- Drag handle at top
- Close (X) button top right
- Creator avatar (64px) + name + type badge
- Full description (scrollable)
- Offer summary section (what business offers)
- Location info (city, venue mode, address)
- Date range display
- Availability day chips (same as card but larger)
- Two CTAs at bottom: "Yes, I'd like to Kolab" (yellow primary) + "Not right now" (outlined)
- The "Yes" button triggers ApplyModal.show()

---

### Task 3: Create ExploreFilterSheet Widget

**Files:**
- Create: `lib/widgets/explore_filter_sheet.dart`

**Description:** Bottom sheet for search + filters, replacing the old inline search bar:
- Search TextField at top
- Filter chips: All, venue modes, availability modes (reuse existing filter logic)
- Results count display
- "Apply" button to close sheet
- Wired to existing `opportunityFiltersProvider`

---

### Task 4: Rewrite ExploreScreen with PageView

**Files:**
- Modify: `lib/features/business/screens/explore_screen.dart`

**Description:** Replace current layout:
- Remove old header, search bar, filter chips, ListView
- Add top bar: filter pill (left) + notification bell (right)
- Filter pill shows "All Opportunities" or active filter summary
- Tap filter pill → opens ExploreFilterSheet
- Main content: vertical PageView.builder with ExploreSwipeCard
- Keep existing provider wiring (opportunityListProvider, opportunityFiltersProvider)
- Preload next page when reaching last 2 cards
- Keep loading/empty/error states (adapted for full-screen layout)
- Loading state: full-screen shimmer with gradient placeholder

---

### Task 5: Wire Detail Sheet and Apply Flow

**Files:**
- Modify: `lib/features/business/screens/explore_screen.dart`

**Description:**
- Card tap → showModalBottomSheet with ExploreDetailSheet
- "Yes, I'd like to Kolab" → ApplyModal.show(context, opportunity)
- "View Details" in sheet → navigate to detail route (existing)
- Pass `canApply` logic (not own, not business user) to control CTA visibility
