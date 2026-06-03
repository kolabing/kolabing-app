# Collab Completion Review Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a single completion-plus-lightweight-review flow across backend and Flutter, and expose recent/full profile reviews.

**Architecture:** Backend keeps `complete` plus `review` as the only active post-collab flow, exposes recent and paginated profile reviews, and stops serving the old `finish` path. Flutter consumes those endpoints, removes old feedback code, and adds recent-review and full-review profile UI.

**Tech Stack:** Laravel, PHPUnit, Flutter, Riverpod, GoRouter, HTTP JSON APIs

---

### Task 1: Backend review/profile API

**Files:**
- Modify: `app/Http/Controllers/Api/V1/ProfileController.php`
- Modify: `app/Services/ProfileService.php`
- Modify: `app/Http/Resources/Api/V1/PublicProfileResource.php`
- Create: `app/Http/Resources/Api/V1/PublicProfileReviewResource.php`
- Modify: `routes/api.php`
- Test: `tests/Feature/Api/V1/PublicProfileTest.php`

- [ ] Add recent review preview data to the public profile response.
- [ ] Add paginated `GET /profiles/{profile}/reviews`.
- [ ] Cover recent reviews and reviews pagination with feature tests.

### Task 2: Backend legacy cleanup

**Files:**
- Modify: `app/Http/Controllers/Api/V1/CollaborationController.php`
- Modify: `app/Http/Resources/Api/V1/CollaborationResource.php`
- Modify: `routes/api.php`
- Test: `tests/Feature/Api/V1/CollaborationDetailTest.php`

- [ ] Remove the active `/finish` endpoint and controller method.
- [ ] Remove legacy feedback serialization from collaboration detail payloads.
- [ ] Keep `/complete` and `/review` as the active flow.

### Task 3: Flutter profile reviews UI

**Files:**
- Modify: `lib/features/profile/models/public_profile.dart`
- Modify: `lib/features/profile/services/public_profile_service.dart`
- Modify: `lib/features/profile/screens/public_profile_screen.dart`
- Create: `lib/features/profile/screens/profile_reviews_screen.dart`
- Modify: `lib/config/routes/routes.dart`

- [ ] Add recent-review and full-review models.
- [ ] Render recent review cards on public profile.
- [ ] Add a dedicated review list route and screen.

### Task 4: Flutter completion/review cleanup

**Files:**
- Modify: `lib/features/collaboration/screens/collaboration_detail_screen.dart`
- Modify: `lib/features/collaboration/widgets/kolab_completion_sheet.dart`
- Create: `lib/features/collaboration/services/collaboration_completion_service.dart`
- Delete: `lib/features/collaboration/widgets/collaboration_feedback_sheet.dart`
- Delete: `lib/features/collaboration/models/collaboration_feedback.dart`
- Delete: `lib/features/collaboration/providers/collaboration_feedback_provider.dart`

- [ ] Restore a buildable completion service path.
- [ ] Remove dead feedback imports and code.
- [ ] Keep post-completion review CTA wired to the lightweight review sheet.

### Task 5: Verification and deploy

**Files:**
- Modify as needed from previous tasks

- [ ] Run focused backend tests.
- [ ] Run focused Flutter analyze.
- [ ] Fix regressions.
- [ ] Push backend `master` to trigger deploy.
