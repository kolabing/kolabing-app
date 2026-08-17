# Multi-Kolab Organizer Experience (Task 10) — Flutter design specification

**Status:** written before implementation, per the spec-first workflow.
**Repo:** `kolabing-app`, branch `feat/multi-kolab-event-mvp`.
**Source of truth for every field, enum, endpoint and error code:**
`kolabing-v2/docs/superpowers/specs/2026-08-12-multi-kolab-event-api-contract.md`
(the frozen contract, hereafter "§n").
**Builds on:** Task 9 (`0018071e`) — the applicant side and the typed data layer
under `lib/features/multi_kolab/`, plus the Task 9 correction that put open
Multi-Kolab roles into the ordinary Explore feed. Task 10 must **reuse and
extend** that layer, never duplicate it.

---

## 1. Scope

Organizer-side only:

1. Organizer dashboard / events overview
2. Create + edit a Multi-Kolab event (draft)
3. Add / edit / open / close roles
4. Pre-publish review, publish, confirm, complete, cancel
5. Applicant review per role
6. Shortlist / decline / accept
7. Surfacing the child Kolab + Collaboration created on acceptance

**Explicitly out of scope** (do not touch):

- Applicant discovery/apply flow (Task 9, done).
- The ordinary Explore feed, ordinary Kolab creation, ordinary collaborations —
  Task 10 adds *navigation into* the existing collaboration screens and changes
  nothing about them.
- Attendee ticketing / RSVP management. Organizers use Luma; we store an
  `rsvp_url` only.
- Event cover-photo upload. `MultiKolabEvent` **has no media column at all**
  (contract §13 "Image" deviation). No image field is offered in the editor;
  the organizer's avatar is the only image the API can produce, and the
  dashboard card uses an initial/monogram fallback.
- Any new moderation pipeline (contract §12 — reactive report/block only).
- A second collaboration system. Acceptance hands off to the existing
  `/collaboration/:id` and `/opportunity/:id` screens.
- Push scheduling for draft reminders — the backend already owns that.

---

## 2. Information architecture and navigation

The organizer area lives **inside the existing My Kolabs experience** as an
entry point, not as a new bottom-nav destination. `MyKolabsHubScreen` has four
fixed segmented tabs (Offers / Requests / Active / Finished) shared by both
account types; adding a fifth segment would degrade that control on small
phones and would show an empty tab to the ~all users without the Event Creator
entitlement. Instead the **Offers tab gains a single entry row** ("Multi-Kolab
events") that pushes the organizer area.

Routes (registered under a distinct `/organizer/...` prefix so they can never
collide with the existing applicant-facing `/multi-kolab-events/:id` route,
which GoRouter would otherwise match with `id = "organizer"`):

| Route | Screen |
|---|---|
| `/organizer/multi-kolab-events` | Screen 1 — organizer dashboard (events overview) |
| `/organizer/multi-kolab-events/new` | Screen 2 — create event (draft) |
| `/organizer/multi-kolab-events/:id/edit` | Screen 2 — edit draft |
| `/organizer/multi-kolab-events/:id` | Screen 5 — event management (Overview / Roles / Applicants) |
| `/organizer/multi-kolab-events/:id/roles/new` | Screen 3 — role editor (create) |
| `/organizer/multi-kolab-events/:id/roles/:roleId` | Screen 3 — role editor (edit) |
| `/organizer/multi-kolab-events/:id/review` | Screen 4 — pre-publish review |
| `/organizer/multi-kolab-roles/:roleId/applications` | Screen 6 — applicant review for one role |

Route-name constants live on `KolabingRoutes` beside the existing
`multiKolabEventDetail`, with `…Location(...)` builder helpers matching the
existing `multiKolabRoleDetailLocation` convention.

Back behaviour: the editor screens `pop()` back to the management screen; the
management screen pops to the dashboard; the dashboard pops to My Kolabs.

---

## 3. Permissions and the Event Creator entitlement

Truth lives on the backend. Flutter reads
`GET /api/v1/me/organizer-entitlement` (§2) via the existing
`multiKolabEntitlementProvider` → `EventCreatorEntitlement`.

Rules:

- **Never** call `hasActiveSubscription()` / the Business paywall for anything
  in this feature. The Event Creator entitlement is a *separate* capability and
  both Business and Community profiles can hold it.
- Entitled organizer (either account type): full create/manage access.
- Non-entitled profile: the dashboard renders a **gate state** — what a
  Multi-Kolab event is, that it needs Event Creator access, and a
  "Request access" CTA. No create/edit affordances are rendered at all.
- Entitlement is **not** required to *view* the organizer area or one's own
  existing events (an organizer whose entitlement lapsed must still be able to
  read and cancel what they already published) — only creation and publishing
  are gated. The backend enforces the same: `publish()` is the entitlement
  check-point (§5), draft creation is deliberately ungated (§3).
- Because the backend is authoritative, the Flutter gate is a **UX
  optimisation only**: if a publish nonetheless returns `403` with
  `errors.entitlement = ["event_creator_required"]`, the publish screen shows
  the same gate copy inline rather than a generic error.
- Applicants never touch any of this. Ordinary Community Kolab creation is
  untouched and stays free.

---

## 4. Screen 1 — Organizer dashboard (events overview)

**Data:** `GET /api/v1/multi-kolab-events/me` (§ controller `myEvents`) →
`List<MultiKolabEventSummary>` via the existing `multiKolabMyEventsProvider`
(all statuses, newest first, paginated 15/page).

**Card contents** (per `MultiKolabEventSummary`): title; city; target date
(exact date, or "range" label when `date_mode = range` — note the *summary*
resource only carries `event_date`, so a range event shows its date-mode label
without the endpoints); a status badge; `role_counts.total` / `.open` /
`.filled` rendered as "N roles · N open · N filled"; a monogram avatar
fallback; and a "Manage" action opening Screen 5.

**Needs-attention rule** (client-side, derived from the summary payload alone —
no per-event fan-out): an event needs attention when it is `draft` (never
published), or when it is `recruiting` **and** `role_counts.open > 0`. It is
rendered as a distinct chip plus a semantic label, never colour alone.

**Deviation, documented:** the task brief asks the *list* to show "pending
applications" per event. The `myEvents` summary resource does not carry
application counts, and the only source is
`GET /multi-kolab-events/{event}/dashboard` — one request per event, i.e. an
N+1 from the client. We do **not** do that. Pending/shortlisted/accepted/
declined counts appear on Screen 5 (one dashboard call for the event the
organizer actually opened). Filed as a follow-up: add
`application_counts` to `MultiKolabEventSummaryResource`.

**Filters:** a segmented status filter (All / Drafts / Recruiting / Confirmed /
Finished) applied **client-side** over the already-fetched list — the `me`
endpoint takes no `status` query parameter, so a server-side filter would be an
invented API. "Finished" groups `completed` + `cancelled` + `expired`.

**States:**

| State | Behaviour |
|---|---|
| Loading | Existing skeleton/shimmer convention, 3 placeholder cards |
| Refresh | `RefreshIndicator` → `ref.invalidate(multiKolabMyEventsProvider)` |
| Empty (entitled) | Illustration + copy + primary CTA "Create Multi-Kolab event" |
| Empty (not entitled) | Gate state (§3), CTA "Request access" |
| Error | Localized message + Retry |
| Filter yields nothing | "No events in this group" + clear-filter action |

---

## 5. Screen 2 — Create / edit event

`POST /api/v1/multi-kolab-events` (§3) and
`PATCH /api/v1/multi-kolab-events/{event}` (§3), via the existing
`CreateMultiKolabEventInput` / `UpdateMultiKolabEventInput`.

Fields — **exactly** the contract's, nothing more:

| UI label (en) | API field | Validation (client) |
|---|---|---|
| Event name | `title` | required, ≤255 |
| What's the event? | `description` | optional, ≤5000 |
| What partners get | `value_summary` | optional, ≤1000 |
| I still need a venue | `venue_needed` | bool switch |
| When? (a date / a range) | `date_mode` | `exact` \| `range` |
| Date | `event_date` | required when `exact`; not in the past |
| From / To | `date_range_start` / `date_range_end` | required when `range`; `end >= start` |
| City | `city` | optional, ≤100 |
| Category | `category` | optional, ≤100, existing category picker |
| RSVP link (Luma, etc.) | `rsvp_url` | optional; must parse as a URL **and** scheme must be `https` |
| Who can apply? | `eligible_account_type` | `business` \| `community` \| `either` |

Behaviour:

- **Draft-first.** Saving always writes a draft; the backend's draft validation
  is lenient (only `title`), so the organizer can leave and come back. Client
  validation for the non-title fields is applied **at save** only for
  format-level rules (HTTPS, date ordering) — never blocking a partially
  completed draft.
- Editing a draft **restores every saved value** by seeding the form controller
  from the `MultiKolabEvent` detail response.
- `date_mode` switching clears the fields of the other mode so no stale
  `event_date` is sent alongside a range.
- **Unsaved changes guard:** a `PopScope` confirm dialog if the form is dirty.
- Terminal statuses (`completed`, `cancelled`) are not editable — the backend
  returns `422 invalid_transition`; the UI hides the Edit action for them.
- After a **create**, navigate straight to Screen 5 with the Roles tab
  selected, and show an inline nudge to add the first role.
- Inline, localized, field-associated errors. Server-side 422 field errors are
  mapped back onto the matching form field by key.

---

## 6. Screen 3 — Role management

`POST /api/v1/multi-kolab-events/{event}/roles` (§4),
`PATCH /api/v1/multi-kolab-roles/{role}` (§4).

Fields (contract §4): `title`; `eligible_account_type`; `positions_needed`;
`required`; `need`; `receive`; `compensation_type`; `requirements`; `details`.

There is **no separate "partner type / category" column on a role** — the
contract has none. "Run club partner", "yoga community", "venue partner",
"open to any brand" are all expressed through the role **title** plus
`eligible_account_type`, exactly as the Explore card already renders them
(`multiKolabRoleOpenToAnyCommunity` etc. already exist in the ARB). Open-ended
roles therefore need no special field: they are simply a role whose title is
generic and whose `need` is broad. This is called out because the brief lists
"partner type/category when supported" — it is **not** supported, and inventing
a column would be a schema change out of scope.

Rules:

- `positions_needed` ≥ 1, enforced client-side with a stepper that cannot go
  below 1 (backend `min:1`).
- Editing must not produce `positions_filled > positions_needed`: the stepper's
  lower bound for an existing role is `max(1, positions_filled)`, with an
  explanatory helper line when clamped.
- A multi-position role stays **one** role. Progress is shown as
  "`positions_filled` of `positions_needed` partners confirmed" using the
  existing `MultiKolabRoleProgress` widget.
- Each role's editor shows a plain-language explanation of where the role will
  appear: community-only → "Communities will see this in their Explore feed";
  business-only → "Businesses…"; either → "Both businesses and communities…".

### 6.1 Open / close a role — required smallest backend addition

The frozen contract has role `status: open | filled | closed`, and the Explore
query (§13) already excludes anything not `open`, so `closed` is the correct,
already-designed way to stop recruiting for one role. **But there is no API
that can set it:** `UpdateMultiKolabRoleRequest` does not accept `status`, and
the only other mutation is `DELETE` (§4), which hard-removes the role and is
refused once an application has been accepted (`role_has_accepted_application`).

Smallest backend addition (Phase B of this task):

- Allow `status` in `UpdateMultiKolabRoleRequest`, `in:open,closed` only —
  `filled` is never client-settable; it is derived by the acceptance service.
- Guard in `MultiKolabEventService::updateRole()`: reopening
  (`closed → open`) is refused with `422 role_capacity_exceeded` when
  `positions_filled >= positions_needed`; a `filled` role cannot be moved to
  `open` by the client.
- No migration, no new route, no new resource, no new error code.

Flutter then exposes "Stop recruiting for this role" / "Reopen this role".
**Hard deletion is not offered in the UI at all** — closing is always safe and
never destroys applicant history, per the brief's instruction.

---

## 7. Screen 4 — Pre-publish review

Read-only compact summary of everything Screen 2 and Screen 3 captured: event
info; venue-needed state; date or range; every role with eligibility, positions
and value exchange; RSVP URL; and a **"Still needed"** block listing anything
the client can already tell is missing (no roles, no date, no city).

`POST /api/v1/multi-kolab-events/{event}/publish` (§5). The **backend response
is the final authority** — the client's "Still needed" list is advisory and
never blocks the button on its own beyond the obvious "no roles" case.

Failure handling:

- `403` + `errors.entitlement = ["event_creator_required"]` → inline gate copy
  (§3), draft untouched.
- `422` + field errors → each error is rendered against its section, and the
  scroll position jumps to the first failing section. Nothing entered is lost;
  the event stays `draft`.
- Any other error → localized generic message with Retry.

Success: confirmation sheet explaining that **each open role is now an offer in
the Explore feed of the profiles that can apply to it**, then return to Screen 5
with fresh server state.

---

## 8. Screen 5 — Event management

Two data sources, both existing providers:
`multiKolabEventDetailProvider(eventId)` (§6 detail: event fields + roles) and
`multiKolabDashboardProvider(eventId)` (§9: role-level application counts).

Three sections, using the app's existing `KolabingSegmentedControl`:

- **Overview** — status badge; role-fill progress bar; aggregated pending /
  shortlisted / accepted / declined totals (summed from the dashboard's
  per-role `application_counts`); event details; the permitted lifecycle
  actions; and the list of **child Kolabs created so far** (see §10).
- **Roles** — every role with its status, fill progress, per-role application
  counts, "Manage applicants" and "Edit / Close" actions, plus "Add role".
- **Applicants** — the role list again, each row opening Screen 6. (The API has
  no cross-role application list; grouping *is* by role.)

Lifecycle actions rendered only when valid for the current status (§5):

| Status | Actions |
|---|---|
| `draft` | Edit · Add role · Review & publish · Cancel |
| `recruiting` | Edit · Manage roles · Confirm · Cancel |
| `confirmed` | Complete · Cancel |
| `completed` / `cancelled` / `expired` | none (read-only) |

Cancel requires a **reason** (backend `required`) collected in a dialog and
never hard-deletes the event or its roles.

Every mutation: disabled-while-submitting (no double submit), progress
indicator, `ref.invalidate` of the detail + dashboard providers on success,
stable-code localized error on failure.

---

## 9. Screen 6 — Applicant review (per role)

`GET /api/v1/multi-kolab-roles/{role}/applications` (§7), paginated, organizer
only (`403 not_owner`).

**What the API actually returns per application** (`MultiKolabRoleApplication`
resource, §7): `id`, `multi_kolab_role_id`, `applicant_profile_id`,
`applicant_profile_type`, `status`, `pitch`, `availability`, `kolab_id`,
`created_at`.

**Deviation, documented:** the brief asks for "applicant profile … relevant
profile info … existing collaboration/social-proof info". The role-application
resource deliberately does **not** nest the applicant profile (its docblock
says so explicitly, to avoid an N+1). Task 10 therefore renders the applicant's
**name/avatar by resolving `applicant_profile_id` through the existing public
profile surface** (`GET /api/v1/profiles/{profile}` — already used elsewhere in
the app), and the "View full profile" action deep-links to the existing public
profile screen, which already carries reviews, collaborations and social proof.
No new profile fields are invented and no private data is surfaced.

**`withdrawal_reason`: not exposed.** Verified against
`MultiKolabRoleApplicationResource` — it is deliberately never serialized
(contract §12: "Never publicly expose `withdrawal_reason`"). Flutter therefore
shows a withdrawn application's *status only*, with no reason. Filed as a
follow-up for the contract owner to decide whether an organizer-only field is
wanted; **not** implemented speculatively.

Grouping/sections within one role: **Pending → Shortlisted → Accepted →
Declined → Withdrawn**, each a collapsible section with a count. Declined and
withdrawn applications stay visible with their status rather than vanishing.

Per-status actions (only what is valid is rendered):

| Status | Actions |
|---|---|
| `pending` | Shortlist · Decline · Accept |
| `shortlisted` | Decline · Accept |
| `accepted` | Open child Kolab / Collaboration |
| `declined`, `withdrawn` | none |

- **Shortlist** (`POST …/shortlist`) — no confirmation (reversible-ish, low
  consequence); the row shows an inline spinner and is action-locked while in
  flight; on success the row moves to the Shortlisted section; on failure the
  list state is preserved and a localized error toast is shown.
- **Decline** (`POST …/decline`) — confirmation dialog naming the applicant and
  the role; then the row moves to the Declined section.
- **Accept** (`POST …/accept`) — the consequential one. Confirmation sheet
  shows: applicant, role title, **remaining capacity after this acceptance**,
  the role's value exchange (`need` / `receive` / `compensation_type`), and an
  explicit line that a Kolab and a collaboration will be created. See §10.

Capacity conflict (`409`, `errors.role = ["role_capacity_exceeded"]`): a clear
localized message "this role is already full", the list and the role capacity
are refreshed from the server, and Accept disappears for the remaining rows.

---

## 10. Acceptance and the child Kolab

Acceptance is **never** modelled locally. The client calls the endpoint and
renders whatever the transaction returned (`ChildKolabResult` — `application`,
`kolab`, `collaboration`, §8). No optimistic accepted state, no locally
fabricated Kolab.

After success:
1. Application row → Accepted, with the child Kolab surfaced on it.
2. `multiKolabEventDetailProvider` + `multiKolabDashboardProvider` +
   the role's application list are invalidated so `positions_filled` and role
   status come back from the server.
3. A success sheet offers "Open collaboration" →
   `/collaboration/{collaboration_id}` (existing screen) and, when there is no
   collaboration id, "Open Kolab" → `/opportunity/{kolab_id}` (existing
   screen). **No new detail UI is built.**
4. Accept is disabled for every other row in the role once capacity is reached.
5. Re-calling accept on an already-accepted application is idempotent (§8) and
   returns the same ids — the UI treats a repeat response as success, not as a
   duplicate creation.

Screen 5's Overview lists every accepted application's child Kolab, so the
organizer has one place to reach all collaborations spawned by the event.

---

## 11. Data layer additions

Extend `lib/features/multi_kolab/`, do not fork it.

`MultiKolabRepository` gains:

```dart
Future<MultiKolabRole> updateRole(String roleId, UpdateMultiKolabRoleInput input);
Future<MultiKolabRole> setRoleStatus(String roleId, MultiKolabRoleStatus status);
Future<List<MultiKolabRoleApplication>> roleApplications(String roleId);
Future<MultiKolabEvent> confirmEvent(String eventId);
Future<MultiKolabEvent> completeEvent(String eventId);
```

- `UpdateMultiKolabRoleInput` = a partial (`sometimes`) variant of
  `CreateMultiKolabRoleInput`; `setRoleStatus` is a thin `PATCH` with only
  `status`, so both share one endpoint.
- `cancelEvent` already exists; it returns `void` today and is left as is.
- `ApiMultiKolabRepository` implements each with the existing `_request`
  helper (401 refresh-retry, `ApiException`, `MultiKolabApiErrorCode.stableCode`
  for stable codes — **no message string matching anywhere**).
- `MockMultiKolabRepository` implements each deterministically, so the whole
  organizer flow is exercisable without a backend session.
- The mock stays hard-gated by `multiKolabRepositoryProvider`
  (`_mockRequested && !kReleaseMode`) and the existing release-mode regression
  test is extended to cover the new surface.
- No new models for resources the Task 9 layer already types.

## 12. State management

Following the app's Riverpod conventions, responsibilities stay separated:

| Provider | Responsibility |
|---|---|
| `multiKolabMyEventsProvider` (existing) | organizer event list |
| `multiKolabEventDetailProvider` (existing, family) | one event + roles |
| `multiKolabDashboardProvider` (existing, family) | per-role counts |
| `multiKolabEntitlementProvider` (existing) | entitlement gate |
| `multiKolabRoleApplicationsProvider` (new, family by roleId) | one role's applications |
| `MultiKolabEventFormController` (new, `AutoDisposeNotifier`) | event editor state + dirty tracking |
| `MultiKolabRoleFormController` (new, family by roleId?) | role editor state |
| `MultiKolabOrganizerActions` (new, `AutoDisposeNotifier<MultiKolabActionState>`) | every mutation: in-flight lock, last stable error, targeted invalidation |

The action notifier keys its in-flight lock by `(actionKind, targetId)` so two
different rows can never be blocked by each other, and a double tap on the same
row is a no-op.

## 13. Localization

All new copy in `app_en.arb`, `app_es.arb`, `app_ca.arb` with an identical key
set (enforced by the existing `multi_kolab_l10n_parity_test.dart`, extended to
the new keys). Key prefix `multiKolabOrganizer…`. No hardcoded strings in
widgets.

Product language, never enum names:

| Wire value | en | es | ca |
|---|---|---|---|
| `recruiting` | Recruiting partners | Buscando partners | Buscant partners |
| `positions_filled` | Partners confirmed | Partners confirmados | Partners confirmats |
| `eligible_account_type` | Who can apply? | ¿Quién puede aplicar? | Qui pot aplicar-hi? |
| `venue_needed` | I still need a venue | Todavía necesito un espacio | Encara necessito un espai |
| `shortlisted` | Shortlisted | Preseleccionado | Preseleccionat |
| `confirmed` | Confirmed | Confirmado | Confirmat |

## 14. Visual design

Existing Kolabing tokens only: black `#19150F`, yellow `#FFE28C`, soft yellow
`#FFF3C5`, `KolabingSpacing`, `KolabingTextStyles`, existing card radii, the
existing segmented control, button hierarchy and status-badge component. Status
colours reuse the existing badge palette; no new design system, no dense admin
tables, no desktop dashboard patterns.

## 15. Accessibility

Semantic labels on every status badge and progress bar (status is never colour
alone); ≥48dp tap targets; visible disabled states; form errors associated with
their field via `TextFormField.errorText`; text scales without overflow
(`Wrap`/`Flexible` on every badge row); the review screen scrolls to and
announces the first failing section.

## 16. Analytics

The backend already emits the Task 8 PostHog business events for
create/publish/confirm/cancel/shortlist/decline/accept. Flutter therefore
**does not** re-emit them — that would double-count. Flutter emits only
UI-funnel events that have no backend equivalent, using the existing analytics
service and the Task 8 naming convention:
`multi_kolab_organizer_dashboard_viewed`,
`multi_kolab_event_editor_opened`,
`multi_kolab_publish_review_viewed`,
`multi_kolab_entitlement_gate_viewed`.
No new event name duplicates an existing backend one.

## 17. Test strategy

Strict red-green-refactor per unit. Layers:

- **Repository/data:** parsing of `myEvents`, event detail, dashboard, role
  create/update, role status, application list, lifecycle responses, accept →
  `ChildKolabResult` ids; stable error-code extraction for
  `event_creator_required`, `not_owner`, `invalid_transition`,
  `role_capacity_exceeded`, `role_has_accepted_application`; mock-vs-API
  selection; release-mode mock refusal.
- **Entitlement:** entitled Business creates; entitled Community creates;
  non-entitled sees the gate; ordinary Community Kolab creation untouched;
  applicant flow never reads the entitlement; subscription state never consulted.
- **Widget:** dashboard loading/empty/populated/error/gate; draft card;
  recruiting card; role progress; event-form validation (title, HTTPS RSVP,
  date-range ordering); editing a saved draft restores values; venue-needed;
  exact vs range; role editor for community/business/either and open-ended;
  `positions_needed` lower bound; value-exchange fields; pre-publish review;
  publish failure keeps the draft; publish success copy; application sections
  by status; shortlist; decline confirmation; accept confirmation contents;
  capacity conflict; accepted child-Kolab row; lifecycle confirmations;
  l10n parity; accessibility semantics.
- **Integration:** the full organizer flow, driven purely by
  `find.byKey`/`byText`/`byType` + `tester.tap`/`enterText`/`pumpAndSettle`
  over the deterministic mock repository. **No simulator-tap automation
  (`cliclick` or similar)** — proven unreliable in this environment.
- **Backend (for §6.1 only):** feature tests for closing a role, reopening a
  role, refusing to reopen a full role, and refusing a client-set `filled`.

## 18. Open follow-ups (not implemented here)

1. `application_counts` on `MultiKolabEventSummaryResource` so the organizer
   list can show pending counts without an N+1 (§4).
2. A contract decision on whether `withdrawal_reason` should be exposed
   organizer-only (§9).
3. An event cover-photo column + upload (contract §13 already flags this).
4. `status`/pagination query parameters on `GET /multi-kolab-events/me`.
