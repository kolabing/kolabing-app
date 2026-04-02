# New Kolab Creation Flow — Mobile Design

**Date:** 2026-03-24
**Status:** Approved
**Brief by:** Daniel Martinez
**Implementation:** Mobile-first (BFF). Backend spec generated after mobile is complete.

---

## Overview

Replace the current "Create a Kolab" (community) and "Create Collab Request" (business) flows with an intent-driven system. First screen asks what the user wants to achieve, then adapts subsequent steps.

## Flow Architecture

```
FAB tap (both user types)
    │
    ▼
IntentSelectionScreen (unified entry point)
    │
    ├─ Community: "Find Venue/Sponsor" ──► CommunitySeekingFlow (6 steps)
    │
    ├─ Community: "Promote Venue/Product" ► SubscriptionGate → BusinessFlow
    │
    ├─ Business: "Promote Venue" ────────► VenuePromotionFlow (7 steps)
    │
    └─ Business: "Promote Product" ──────► ProductPromotionFlow (7 steps)
```

## File Structure

```
lib/features/kolab/
├── models/
│   └── kolab.dart
├── enums/
│   ├── intent_type.dart
│   ├── venue_type.dart
│   ├── product_type.dart
│   ├── need_type.dart
│   └── deliverable_type.dart
├── providers/
│   └── kolab_form_provider.dart
├── services/
│   └── kolab_service.dart            # mock initially
├── screens/
│   ├── intent_selection_screen.dart
│   ├── community/
│   │   ├── needs_screen.dart
│   │   ├── community_info_screen.dart
│   │   ├── event_details_screen.dart
│   │   ├── logistics_screen.dart
│   │   ├── photo_screen.dart
│   │   └── review_screen.dart
│   ├── business/
│   │   ├── venue_details_screen.dart
│   │   ├── product_details_screen.dart
│   │   ├── media_screen.dart
│   │   ├── offering_screen.dart
│   │   ├── ideal_community_screen.dart
│   │   ├── past_events_screen.dart
│   │   ├── availability_screen.dart
│   │   └── review_screen.dart
│   └── subscription_gate_screen.dart
└── widgets/
    ├── kolab_step_indicator.dart
    ├── kolab_action_bar.dart
    ├── multi_select_chips.dart
    ├── intent_card.dart
    ├── media_picker_grid.dart
    ├── past_event_card.dart
    └── kolab_review_card.dart
```

## Data Model

### Kolab
```dart
class Kolab {
  final String? id;
  final IntentType intentType;
  final String status;

  // Common
  final String title;
  final String description;
  final String preferredCity;
  final String? area;
  final List<KolabMedia> media;

  // Availability
  final AvailabilityMode? availabilityMode;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;
  final TimeOfDay? selectedTime;
  final List<int> recurringDays;

  // Community Seeking
  final List<NeedType> needs;
  final List<String> communityTypes;
  final int? communitySize;
  final int? typicalAttendance;
  final List<DeliverableType> offersInReturn;
  final VenuePreference? venuePreference;

  // Venue Promotion
  final String? venueName;
  final VenueType? venueType;
  final int? capacity;
  final String? venueAddress;

  // Product Promotion
  final String? productName;
  final ProductType? productType;

  // Business Targeting
  final List<String> offering;
  final List<String> seekingCommunities;
  final int? minCommunitySize;
  final List<DeliverableType> expects;

  // Social Proof
  final List<PastEvent> pastEvents;

  final DateTime? publishedAt;
  final DateTime? createdAt;
}
```

### Enums

- **IntentType:** community_seeking, venue_promotion, product_promotion
- **VenueType:** restaurant, cafe, bar_lounge, hotel, coworking, sports_facility, event_space, rooftop, beach_club, retail_store, other
- **ProductType:** food_product, beverage, health_beauty, sports_equipment, fashion, tech_gadget, experience_service, other
- **NeedType:** venue, food_drink, sponsor, products, discount, other
- **DeliverableType:** social_media, event_activation, product_placement, community_reach, review_feedback
- **VenuePreference:** business_provides, community_provides, no_venue

## Step Mapping

| Step | community_seeking | venue_promotion | product_promotion |
|------|------------------|-----------------|-------------------|
| 0 | What do you need? | Venue details | Product details |
| 1 | Community info + size | Photos & media | Photos & media |
| 2 | Event details | What you're offering | What you're offering |
| 3 | Logistics | Ideal community | Ideal community |
| 4 | Photo | Past events (skip) | Past events (skip) |
| 5 | Review & Publish | Availability | Availability |
| 6 | — | Review & Publish | Review & Publish |

## Provider State

```dart
class KolabFormState {
  final IntentType? intentType;
  final int currentStep;
  final int totalSteps;
  final Kolab kolab;
  final bool isEditing;
  final bool isSubmitting;
  final bool isPublishing;
  final bool isSuccess;
  final bool requiresSubscription;
  final String? error;
  final Map<String, String> fieldErrors;
}
```

## Navigation

- New route: `/kolab/new` → IntentSelectionScreen
- FAB on both main screens pushes `/kolab/new`
- Old routes (`/business/offers/new`, `/community/opportunities/new`) stay for backward compat

## Subscription Gate (Community Flow B)

When community selects "Promote Venue/Product":
1. Check subscription via existing `profileProvider`
2. If not subscribed → show `SubscriptionPaywall` (existing widget)
3. If subscribed → proceed to business flow (venue or product selection)

## Design System

Follow existing patterns:
- Step indicator dots (from community create screen)
- Section cards with white bg, border, rounded corners
- Selectable chips for multi-select
- Selection cards for single-select (intent, venue mode)
- Sticky bottom action bar (Back + Next / Save Draft + Publish)
- Yellow primary (#FFD861) with black text
- Rubik headlines, Open Sans body, Darker Grotesque buttons

## Mock Service

All API calls return mock data. Service interface matches expected backend contract:
- `create(Kolab)` → Kolab with id
- `update(id, Kolab)` → updated Kolab
- `publish(id)` → void
- `getMyKolabs(status?)` → List<Kolab>
- `getDetail(id)` → Kolab
