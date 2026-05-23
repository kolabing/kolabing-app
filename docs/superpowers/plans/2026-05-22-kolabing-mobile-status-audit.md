# Kolabing Mobile Status Audit

Date: 2026-05-22
Scope: reconcile Daniel/Paige QA list with the current Flutter codebase

## Summary

Static audit says the majority of the original mobile-side blockers are already implemented in code.

What remains is mostly in three buckets:

1. live QA verification against fresh and seeded accounts
2. backend / seed-data / asset follow-up
3. one product/backend item for discovery taxonomy (`H4`)

No obvious large mobile-only blocker remains from code inspection alone.

## Fixed in Flutter code

### Auth / onboarding / publishing

- `B1` paywall on business publish attempts
  - `lib/features/kolab/providers/kolab_form_provider.dart`
  - `lib/features/kolab/screens/kolab_flow_screen.dart`
- `B2` broken login route / page-not-found stranding
  - `lib/features/auth/screens/login_screen.dart`
  - `lib/features/auth/utils/auth_navigation.dart`
  - `lib/config/routes/routes.dart`
- `B6` business signup failure surfacing and onboarding submit hardening
  - `lib/features/onboarding/providers/onboarding_provider.dart`
  - `lib/features/onboarding/screens/business/business_final_screen.dart`
- `B7` publish image-url error hardening
  - `lib/services/upload_service.dart`
  - `lib/utils/remote_media_url.dart`
  - `lib/features/kolab/providers/kolab_form_provider.dart`
- `E2` app launch chooser instead of dropping straight into register
  - `lib/features/auth/screens/splash_screen.dart`
  - `lib/features/auth/providers/auth_state_provider.dart`
  - `lib/features/auth/screens/welcome_screen.dart`
- `E3` password field present on final create-account screen
  - `lib/features/onboarding/screens/business/business_final_screen.dart`
- `E5` business onboarding label changed from photo to logo
  - `lib/features/onboarding/screens/business/business_step2_screen.dart`
  - `lib/features/onboarding/widgets/photo_upload_widget.dart`

### Creation flow / media / image pipeline

- `C1` tap-outside keyboard dismiss in create flows
  - `lib/features/kolab/screens/business/venue_details_screen.dart`
  - `lib/features/kolab/screens/community/event_details_screen.dart`
  - `lib/features/kolab/screens/community/community_info_screen.dart`
- `C4` past-events video upload path
  - `lib/features/event/widgets/add_event_modal.dart`
  - `lib/features/event/services/event_service.dart`
- `C6` full venue address selection and Google import flow
  - `lib/features/onboarding/screens/business/business_step5_screen.dart`
  - `lib/features/onboarding/services/onboarding_service.dart`
- `C7` reuse venue/profile photos in kolab creation
  - `lib/features/kolab/screens/business/media_screen.dart`
  - `lib/features/kolab/screens/community/photo_screen.dart`
  - `lib/features/kolab/widgets/existing_photo_picker_sheet.dart`
- `C8` flexible scheduling removed from creation flow
  - `lib/features/opportunity/models/opportunity.dart`
  - `lib/features/kolab/screens/business/availability_screen.dart`
  - `lib/features/community/screens/create_opportunity_screen.dart`
  - `lib/features/kolab/providers/kolab_form_provider.dart`
- `C10` Google Photos preview normalization
  - `lib/utils/image_picker_normalize.dart`
  - `lib/features/kolab/screens/business/media_screen.dart`
  - `lib/features/kolab/screens/community/photo_screen.dart`
  - `lib/features/onboarding/widgets/photo_upload_widget.dart`
- `C15` profile/gallery images render again through URL normalization
  - `lib/utils/remote_media_url.dart`
  - `lib/features/auth/models/user_model.dart`
  - `lib/features/profile/providers/gallery_provider.dart`
  - `lib/features/profile/screens/public_profile_screen.dart`
  - `lib/services/upload_service.dart`

### Discovery / matching / profile CTA

- `C9` business viewing a community now has a primary Send Kolab CTA
  - `lib/features/profile/screens/public_profile_screen.dart`
  - `lib/features/business/screens/explore_screen.dart`
  - `lib/features/kolab/screens/intent_selection_screen.dart`
  - `lib/config/routes/routes.dart`
- `H1` match breakdown on cards
  - `lib/widgets/match_breakdown.dart`
  - `lib/widgets/explore_swipe_card.dart`
  - `lib/features/discovery/models/discovery_item.dart`
- `H2` offer headline captured and rendered
  - `lib/features/kolab/screens/business/venue_details_screen.dart`
  - `lib/features/kolab/screens/business/product_details_screen.dart`
  - `lib/features/kolab/providers/kolab_form_provider.dart`
  - `lib/widgets/explore_swipe_card.dart`
- `H3` base offer + negotiation triggers model
  - `lib/features/kolab/screens/business/offering_screen.dart`
  - `lib/features/opportunity/models/opportunity.dart`
  - `lib/features/business/screens/community_offer_detail_screen.dart`
- `H5` denser discovery card layout
  - `lib/widgets/explore_swipe_card.dart`
  - `lib/features/discovery/models/discovery_item.dart`

### Collaboration / acceptance / completion

- `C11` community kolab flow no longer leaks a venue-details step
  - `lib/features/kolab/screens/kolab_flow_screen.dart`
- `C12` accept-date picker constrained to publisher availability
  - `lib/features/application/screens/application_review_screen.dart`
- `C13` contact-methods step removed from accept flow
  - `lib/features/application/screens/application_review_screen.dart`
- `D3` finish collaboration action exists in the detail screen
  - `lib/features/collaboration/screens/collaboration_detail_screen.dart`
  - `lib/features/collaboration/providers/collaboration_detail_provider.dart`

### Taxonomy / business targeting / onboarding structure

- `D1` multi-category business signup
  - `lib/features/onboarding/screens/business/business_step2_screen.dart`
  - `lib/features/onboarding/models/onboarding_state.dart`
- `D2` Business / Coworking added to ideal community options
  - `lib/features/kolab/screens/business/ideal_community_screen.dart`
- `E1` merged account + first-venue onboarding flow is effectively in place
  - venue selection/import happens before final account creation in the same onboarding flow
  - `lib/features/onboarding/screens/business/business_step5_screen.dart`
  - `lib/features/onboarding/screens/business/business_step2_screen.dart`
  - `lib/features/onboarding/screens/business/business_final_screen.dart`

## Likely fixed, but needs live QA

These are not obvious open code gaps anymore, but they still need device/server verification:

- `A1` business profile image picker opens
- `A2` communities can add photos in kolab creation
- `A4` past-events video upload regression check
- `A5` search bar loads results
- `B3` draft save/load durability
- `C2` add pictures to a kolab post
- `C3` community profile photo upload during onboarding
- `C5` accept kolab end-to-end
- `F1` carousel-dot placement is likely acceptable after discovery-card redesign, but still subjective QA

## Backend / seed / product follow-up

- `B4` seeded test-account upload session expiry
- `B5` seeded test-account venue-type failure
- `G1` email banner public asset upload
- `H4` taxonomy and score-weight audit

Already tracked or documented on backend side:

- `D3` feedback endpoint follow-up:
  - `../kolabing-v2/.agent/todo/BE-XXX-collaboration-feedback-endpoint.md`
- discovery card activity/meta contract:
  - `../kolabing-v2/docs/superpowers/plans/2026-05-22-discovery-card-density-backend.md`

## Current conclusion

From the Flutter codebase alone, the mobile app is not missing another large implementation wave. The next efficient move is:

1. track the remaining backend items in `kolabing-v2`
2. run a focused live QA pass for the verify bucket
3. only reopen mobile code if one of those verify items still reproduces
