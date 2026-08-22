# Community follower / member split — backend implementation plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a one-tap follower relationship and an application-with-questions gate on membership, without changing any existing behaviour on production.

**Architecture:** Three new tables (`community_followers`, `community_join_questions`, `community_join_answers`). `community_members` and `community_join_requests` are structurally untouched, and every existing member-gated query keeps its exact meaning — a follower can never be mistaken for a member because they do not live in the same table. The approval machinery already exists (`CommunityJoinRequestController::store/index/approve/decline` + `CommunityMemberService`); this plan adds answers to it rather than replacing it.

**Tech Stack:** Laravel 12, PHP 8.4, Postgres, PHPUnit with `LazilyRefreshDatabase`, Pint.

**Design:** `docs/plans/2026-08-22-community-follower-member-split-design.md` (in `kolabing-app`)
**Issue:** kolabing/kolabing-app#138 · **Branch:** `feat/community-follower-split`

---

## The production-safety rules every task obeys

1. **Additive migrations only.** New tables. No column altered, renamed or dropped.
2. **No existing endpoint changes its response shape.** Fields may be *added*; nothing is removed or retyped.
3. **No existing row is written by a migration.**
4. **Behaviour changes are gated on new data.** The one behaviour change in this plan — an `open` community accepting a join request — only happens when that community has active questions, and no community has any until a leader creates one. Every existing open community keeps 422-ing on `join-requests` exactly as it does today, so the `/communities/{id}/join` path is untouched.
5. Backend deploys before the app. Until then the new endpoints are simply unused.

---

## Task 1: Migrations

**Files:**
- Create: `database/migrations/2026_08_22_100000_create_community_followers_table.php`
- Create: `database/migrations/2026_08_22_100001_create_community_join_questions_table.php`
- Create: `database/migrations/2026_08_22_100002_create_community_join_answers_table.php`
- Test: `tests/Feature/Database/CommunityFollowerSchemaTest.php`

**Step 1: Write the failing test.** Assert the three tables exist with their columns, and — the important one — that `community_members` and `community_join_requests` still have exactly the columns they had before (guards rule 1).

```php
public function test_new_tables_exist_and_existing_ones_are_untouched(): void
{
    $this->assertTrue(Schema::hasTable('community_followers'));
    $this->assertTrue(Schema::hasColumns('community_followers',
        ['id', 'community_id', 'profile_id', 'followed_at']));
    $this->assertTrue(Schema::hasColumns('community_join_questions',
        ['id', 'community_id', 'position', 'prompt', 'required', 'is_active']));
    $this->assertTrue(Schema::hasColumns('community_join_answers',
        ['id', 'join_request_id', 'question_id', 'answer']));

    // Additive only: these keep every column they had.
    $this->assertTrue(Schema::hasColumns('community_members',
        ['id', 'community_id', 'profile_id', 'tier_id', 'can_manage', 'status', 'joined_at']));
    $this->assertTrue(Schema::hasColumns('community_join_requests',
        ['id', 'community_id', 'profile_id', 'status', 'decided_by', 'requested_at', 'decided_at']));
}
```

**Step 2: Run it, expect failure** (`community_followers` missing):
`php artisan test --filter=CommunityFollowerSchemaTest`

**Step 3: Write the migrations.** Follow the existing style — `uuid('id')->primary()`, `foreignUuid(...)->constrained(...)->cascadeOnDelete()`. `community_followers` gets `unique(['community_id','profile_id'])` and an index on `profile_id`. `community_join_questions` gets `index(['community_id','position'])`. `community_join_answers` gets `unique(['join_request_id','question_id'])`. Each `down()` drops only its own table.

**Step 4: Run it, expect PASS.**

**Step 5: Commit.** `feat(community): tables for followers and membership questions`

---

## Task 2: Models

**Files:**
- Create: `app/Models/CommunityFollower.php`, `app/Models/CommunityJoinQuestion.php`, `app/Models/CommunityJoinAnswer.php`
- Modify: `app/Models/Community.php` (add `followers()`, `joinQuestions()`), `app/Models/CommunityJoinRequest.php` (add `answers()`), `app/Models/Profile.php` (add `followedCommunities()`)
- Test: `tests/Unit/CommunityFollowerRelationsTest.php`

**Step 1–4:** test the relations resolve both ways, then write the models. Casts: `followed_at` → datetime, `required`/`is_active` → boolean, `position` → integer. Mirror the `$fillable` style of the neighbouring models.

**Step 5: Commit.** `feat(community): follower and join-question models`

---

## Task 3: Follow / unfollow

**Files:**
- Create: `app/Services/CommunityFollowService.php`
- Create: `app/Http/Controllers/Api/V1/CommunityFollowController.php`
- Modify: `routes/api.php` (next to the existing `communities/{community}/join` routes)
- Test: `tests/Feature/Api/V1/CommunityFollowTest.php`

**Step 1: Write the failing tests.**
- following returns 201 and creates one row;
- following twice is idempotent — 200, still one row (the unique constraint must not surface as a 500);
- unfollowing removes it; unfollowing when not following is 200, not 404;
- **a follower gets no member access**: `GET /communities/{id}/members` still 403s, the community chat is still refused, and no `community_members` row appears. This is the test that matters.

**Step 2: Run, expect failure.** **Step 3: Implement.** `POST|DELETE /communities/{community}/follow`, `auth:sanctum`, service uses `firstOrCreate` / `delete`. No policy needed to follow — any signed-in profile may.

**Step 4: Run, expect PASS. Step 5: Commit.** `feat(community): follow and unfollow a community`

---

## Task 4: The question set

**Files:**
- Create: `app/Services/CommunityJoinQuestionService.php`
- Create: `app/Http/Controllers/Api/V1/CommunityJoinQuestionController.php`
- Create: `app/Http/Resources/CommunityJoinQuestionResource.php`
- Modify: `routes/api.php`
- Test: `tests/Feature/Api/V1/CommunityJoinQuestionTest.php`

**Step 1: Write the failing tests.**
- a leader creates a question; `GET` returns it ordered by `position`;
- **the 6th active question is refused (422)** — enforced in the service, not just the UI;
- `DELETE` retires (`is_active: false`) rather than deleting, and a retired question's existing answers stay readable;
- a non-leader gets 403 on create/edit/retire (match `CommunityMemberController::index`'s `$profile->cannot('manage', ...)` pattern);
- any signed-in profile may read the active set (an applicant has to see the questions).

**Step 2–4** as usual. `prompt` max 280 chars, `position` 1..5.

**Step 5: Commit.** `feat(community): leader-defined membership questions`

---

## Task 5: Answers on the application, and open-with-questions

**Files:**
- Modify: `app/Http/Controllers/Api/V1/CommunityJoinRequestController.php` (`store`, `index`)
- Modify: `app/Services/CommunityMemberService.php` (`request`)
- Modify: `app/Http/Resources/CommunityJoinRequestResource.php` (add `answers`)
- Test: `tests/Feature/Api/V1/CommunityJoinRequestTest.php` (extend the existing file)

**Step 1: Write the failing tests.**
- applying to an `invite_only` community with answers stores them, and the leader's `index` returns them;
- a **required** question left unanswered → 422;
- an `open` community **with active questions** accepts the request and auto-approves it in one transaction, producing the same member row and default tier as `/join` does;
- an `open` community with **no** questions still 422s `community_is_open` — the existing behaviour, unchanged, so today's app keeps working;
- an existing active member still gets `already_member`;
- answers to a retired question still appear in `index`.

**Step 2: Run, expect the new ones to fail and every pre-existing test in this file to still pass** — that file is the regression guard for the flow this task touches.

**Step 3: Implement.** `store` accepts `answers: [{question_id, answer}]`, validates required ones against the active set, and writes them inside the existing transaction. The `open` branch changes from *always* throwing to throwing **only when the community has no active questions**.

**Step 4: Run, expect PASS. Step 5: Commit.** `feat(community): applications carry answers; open communities may ask questions`

---

## Task 6: Surfacing follower state

**Files:**
- Modify: `app/Http/Resources/CommunityResource.php` (add `followers_count`, `is_following`)
- Modify: the `/me/memberships` payload — **add** a `following` section, leave `memberships` byte-identical
- Test: `tests/Feature/Api/V1/CommunityFollowTest.php` (extend)

**Step 1: Write the failing test.** Assert `memberships` still has exactly the keys it has today (rule 2), and that `following` is a new sibling. Assert `is_following` is false for a member who never followed — the two axes are independent.

**Steps 2–5** as usual. **Commit.** `feat(community): expose follower state without changing the membership payload`

---

## Task 7: The regression that matters

**Files:**
- Test: `tests/Feature/Api/V1/CommunityMemberAccessRegressionTest.php`

**Step 1: Write the test.** Seed a community with an active member holding a tier, exactly as today's flow produces. Then assert, *after* the new migrations, that the member can still: read the roster, reach the community chat, sign up to a `members`-visibility event, and earn community points. Then assert a **follower** of the same community can do **none** of those.

This is the test that proves the split did not leak or revoke anything.

**Step 2–4.** It should pass immediately — the point is to lock it. **Step 5: Commit.** `test(community): member access unchanged, follower access denied`

---

## Task 8: Docs and finish

**Files:**
- Modify: `BACKLOG.md`, `docs/BACKEND-SCHEMA.md` (three new tables), `docs/ROLES-BACKEND-DB-MAP.md` (the follower/member distinction and which gate each surface uses)
- Run: `php artisan test` (full suite) and `vendor/bin/pint`

The repo rules require these three docs to stay in sync with any schema or role change; this is both.

**Commit.** `docs(community): record the follower/member split`

---

## Then: the app

Out of scope for this plan. The app work (Follow button, the Communities list's third state, the application form, the leader's queue) waits for this to deploy, and must self-gate on a 404 so a build can ship before the backend does.
