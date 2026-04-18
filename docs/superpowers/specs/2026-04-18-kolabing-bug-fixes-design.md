# Kolabing Bug Fixes Design

## Goal

Apply minimal, targeted fixes for the April 2026 bug list, prioritizing critical issues first and avoiding refactors or new features.

## Scope

This implementation pass covers client-side fixes that can be completed safely in the Flutter app and platform configuration:

- C1 auth session restore on app launch
- C2 broken post-login redirect / page-not-found flow
- C3 publish flow failures with surfaced API errors
- C4 business image picker and platform permission declarations
- C5 missing photo upload option in community kolab creation
- C6 business onboarding category-selection mismatch
- C7 draft save/load behavior if caused by client payload/filtering
- C8 Explore search wiring and refresh behavior
- C9 keyboard dismiss in creation flows
- C10 past-event video upload capability check and safe handling
- C12 carousel dot positioning
- U1 expired kolabs hidden from Explore on read
- U2 hide time picker when it should not be shown
- U5 smaller past-events CTA if a local UI-only change exists
- U6 better empty-state copy if a local gallery empty-state exists

The following items are expected to require backend or product-scope changes and will be documented clearly if the client cannot safely complete them alone:

- U3 curated active-city list backed by server data
- U4 masking marketplace result counts based on marketplace size rules
- Full video-upload support if backend/event API does not support video payloads

## Constraints

- Minimal fixes only
- No broad refactors
- No new product features beyond what is necessary to restore broken behavior
- Preserve existing route, provider, and screen patterns unless a direct bug requires a small correction

## Bug Grouping

### 1. Auth bootstrap and navigation

Files:

- `lib/features/auth/providers/auth_state_provider.dart`
- `lib/features/auth/providers/auth_provider.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/screens/splash_screen.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/config/routes/routes.dart`

Observed root causes:

- `SplashScreen` currently always exits to `/auth/welcome` instead of using auth/bootstrap state.
- Splash bootstrap already exists in `auth_state_provider.dart`, but the screen does not use it.
- Legacy and current auth routes coexist (`/auth/sign-in` and `/auth/login`), increasing the chance of redirect mismatches.

Design:

- Keep `AuthService` as the source of truth for persisted token/user restoration.
- Change splash startup to call the existing splash initializer and navigate to its resolved destination.
- Normalize post-login navigation to the real route set exposed in `routes.dart`.
- Keep legacy aliases if they already exist, but route app-owned navigation through the canonical routes.

Success criteria:

- Relaunching the app with a valid token goes to the correct dashboard or permission screen.
- Successful login no longer reaches the placeholder “Page Not Found” screen.

### 2. Opportunity publish, drafts, and search

Files:

- `lib/features/opportunity/services/opportunity_service.dart`
- `lib/features/opportunity/providers/opportunity_provider.dart`
- `lib/features/opportunity/providers/opportunity_form_provider.dart`
- `lib/features/community/screens/create_opportunity_screen.dart`
- `lib/features/business/screens/create_collab_request_screen.dart`
- `lib/features/community/screens/my_opportunities_screen.dart`
- `lib/features/business/screens/my_kollabs_screen.dart`
- `lib/features/business/screens/explore_screen.dart`
- `lib/widgets/explore_filter_sheet.dart`

Observed root causes:

- Publish relies on one endpoint and a limited fallback path; failures are partially surfaced but still collapse into generic UI states in some paths.
- Draft/publish state depends on provider/service coordination and may fail if the outgoing payload/status or refresh path is inconsistent.
- Search UI updates filters, but the list provider behavior needs verification so filter changes actually trigger a new load reliably.

Design:

- Verify and correct the status values sent for save-draft and publish flows.
- Surface exact API error messages from `ApiException` anywhere the UI currently replaces them with generic failures.
- Ensure list refresh happens correctly after draft/publish transitions.
- Preserve existing Explore search/filter UX, but fix any provider invalidation or re-fetch issue preventing results from loading.

Success criteria:

- Publish failures show the actual backend message.
- Successful publish moves a draft into published state in the list.
- Draft list tabs load the correct records when the API returns them.
- Explore search updates results instead of appearing inert.

### 3. Media picking and upload entry points

Files:

- `lib/features/onboarding/widgets/photo_upload_widget.dart`
- `lib/features/profile/providers/gallery_provider.dart`
- `lib/features/permission/screens/permission_screen.dart`
- `lib/features/community/screens/create_opportunity_screen.dart`
- `lib/features/business/screens/create_collab_request_screen.dart`
- `ios/Runner/Info.plist`
- `android/app/src/main/AndroidManifest.xml`

Observed root causes:

- iOS photo-library usage descriptions are missing.
- Android manifest includes camera but not explicit photo/media read permissions for newer Android behavior.
- Business request flow contains an upload area stub with a “can be added later” comment, so the tap intentionally does nothing.
- Community create flow appears to have no dedicated image upload entry for kolab photos.

Design:

- Add missing platform permission declarations required for gallery/camera flows.
- Make the shared photo upload widget usable anywhere it is already designed to be used.
- Replace the inert upload stub in business collab creation with a working picker flow backed by the existing opportunity form state.
- Add the missing upload control to the community creation flow using the same minimal pattern.

Success criteria:

- Tapping the business upload control opens the picker.
- Community users have an actual photo-upload option in kolab creation.
- Platform permission dialogs can appear correctly where required.

### 4. Onboarding selection mismatch

Files:

- `lib/features/onboarding/screens/business/business_step1_screen.dart`
- `lib/features/onboarding/screens/business/business_step2_screen.dart`
- `lib/features/onboarding/providers/onboarding_provider.dart`
- `lib/features/onboarding/models/onboarding_state.dart`

Observed root cause:

- The current business-type data model is single-select (`type`, `typeSlug`, `typeName`), while the bug report describes a UI promise of “Select up to 5.”

Design:

- Inspect current business onboarding UI copy and payload contract.
- Choose the lowest-risk correction:
  - If backend and app everywhere are single-select, fix the misleading UI text so behavior matches reality.
  - If the code already partially supports multi-select without backend risk, wire business onboarding to the same multi-select behavior.

Decision rule:

- Favor correcting misleading copy over widening payload shape unless multi-select is already supported end-to-end.

Success criteria:

- The UI no longer promises unsupported multi-select behavior.

### 5. Creation-flow UX polish

Files:

- `lib/features/community/screens/create_opportunity_screen.dart`
- `lib/features/business/screens/create_collab_request_screen.dart`
- `lib/widgets/time_picker.dart`
- `lib/widgets/explore_swipe_card.dart`
- any local gallery empty-state / event CTA widget found during implementation

Design:

- Add tap-to-dismiss keyboard at the scaffold/body level for both creation flows.
- Ensure time picker widgets are only rendered when their prerequisite date/availability state is present.
- Move carousel dots to a more stable, readable position in the image area.
- Apply tiny copy or button-size fixes only where the widget already exists locally.

Success criteria:

- Keyboard dismisses when tapping outside inputs in create flows.
- Time picker no longer appears before date selection when the screen logic should hide it.
- Carousel dots no longer overlap awkwardly with content.

### 6. Past events video support check

Files:

- `lib/features/event/widgets/add_event_modal.dart`
- `lib/features/event/services/event_service.dart`

Observed root cause:

- Current modal supports only image picking (`pickMultiImage`) and the service sends `photos[]` multipart uploads only.

Design:

- Verify whether any existing event model/API contract supports videos.
- If no safe client-side video path exists, do not fake the feature. Instead:
  - keep current photo flow working,
  - note the backend/API gap clearly in the outcome,
  - only add UI messaging/guardrails if needed to avoid misleading users.

Success criteria:

- We do not claim video support unless the full request path exists.

## Testing Strategy

- Run focused analyzer/build verification after code changes.
- Prefer targeted validation over broad refactors.
- Manually inspect high-risk compile paths after editing route/provider/platform files.

## Out-of-Scope Guardrails

- No data-model redesign beyond bug-fix necessity
- No navigation rewrite
- No backend contract invention
- No unrelated UI cleanup

## Implementation Order

1. C1/C2 auth bootstrap and routing
2. C3/C7/C8 opportunity publish, drafts, search
3. C4/C5 media picking and platform permissions
4. C6 onboarding category/selection mismatch
5. C9/C12/U1/U2/U5/U6 local UX fixes
6. C10 capability check and safe fallback
7. Build verification
