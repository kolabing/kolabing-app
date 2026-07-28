# Design — Apply-flow date-availability guard (audit #1–#5)

> Date: 2026-07-27 · Author: Volkan (with Claude) · Status: approved, pre-implementation
> Source: `docs/audit-output/` fix-list tracker items **#1, #2, #3, #4, #5** (P0 apply-flow block).
> Repos touched: **kolabing-app** (Flutter, items #1/#2/#3/#5) and **kolabing-v2** (Laravel, item #4).

## Problem

The core "apply to a Kolab" action is broken for date-exhausted / expired / closed
opportunities:

- **#1** The Apply button is enabled whenever `canApply` is true, and `canApply` is
  computed only from viewer role / self-apply / subscription
  (`explore_screen.dart:155,443`) — it never checks whether any application date is
  still available.
- **#2** There is no "Applications closed" label anywhere on the card or detail sheet.
- **#3** `ApplyModal.show()` (`apply_modal.dart:59-65`) opens unconditionally; when no
  date is available the already-open modal just renders an inline red error box
  (`apply_modal.dart:420-440`, key `applyModalNoDates`).
- **#4** Backend `ApplyToOpportunityRequest` validates `message` + a **free-text
  `availability` string** only — no window/recurring-day check. A direct API call can
  submit an application to a fully-expired Kolab. The needed window logic already
  exists at **accept** time (`AcceptApplicationRequest.php:74-114`) but not at apply
  time.
- **#5** The Explore discovery feed shows expired Kolabs with no filter or label.

Root cause: **no date-availability awareness in the feed → detail → modal → backend
chain.** The app already has all the data to compute availability; the backend already
has the window/recurring logic (only at the wrong step).

## Grounding (verified against current code)

- `buildSelectableApplicationDates(Opportunity o, {DateTime? today})`
  (`apply_modal.dart:19`) is a top-level, `@visibleForTesting` function that **already
  returns `[]` when the window is fully in the past or a recurring pattern yields no
  date from today onward**. It reads `availabilityStart`, `availabilityEnd`,
  `availabilityMode` (`oneTime`/`recurring`/`immediate`), and `recurringDays`
  (ISO weekday ints 1=Mon..7=Sun). It is reusable outside the modal.
- The `Opportunity` model (`lib/features/opportunity/models/opportunity.dart`) exposes
  `availabilityMode`, `availabilityStart`, `availabilityEnd`, `recurringDays`, and a
  `status` enum `OpportunityStatus { draft, published, closed, completed }`. There is
  **no** server-provided `is_open`/`has_available_dates` flag today.
- Apply button: `explore_detail_sheet.dart:687` → `onPressed: canApply ? onApply : onSubscribe`.
- Backend table is `kolabs` (not `collab_opportunities`). `Kolab` casts
  `availability_start`/`availability_end` → date, `recurring_days` → array; helpers
  `isDraft/isPublished/isClosed`. `ApplicationService::validateCanApply()` already gates
  own-opportunity / published / already-applied / active-subscription — but no date or
  capacity check. `DiscoveryOpportunityResource` serializes raw
  `availability{mode,start,end,selected_time,recurring_days}` with no computed flags.
- `AcceptApplicationRequest.php:43-116` contains the authoritative window +
  `recurring_days` validation to mirror.

## Single source of truth

**App** — add one testable helper colocated with the date logic in `apply_modal.dart`:

```dart
/// Applications are open when the Kolab is not closed/completed AND at least one
/// application date is still selectable from `today` onward.
bool opportunityApplicationsOpen(Opportunity o, {DateTime? today}) {
  if (o.status == OpportunityStatus.closed ||
      o.status == OpportunityStatus.completed) {
    return false;
  }
  return buildSelectableApplicationDates(o, today: today).isNotEmpty;
}
```

**Backend** — add the mirror on the model so apply-time and accept-time share it:

```php
// Kolab.php
public function hasSelectableDatesFrom(\Carbon\CarbonInterface $from): bool { /* window + recurring_days */ }
public function applicationsOpen(): bool {
    return !$this->isClosed() && !$this->isCompleted()
        && $this->hasSelectableDatesFrom(now()->startOfDay());
}
```

Both definitions must stay behaviourally identical (closed/completed OR no date from
today ⇒ closed).

## App changes (kolabing-app) — items #1, #2, #3, #5

1. **#5 Feed (`explore_screen.dart`):** filter the recommendation/all discovery **deck**
   to drop Kolabs where `!opportunityApplicationsOpen(o)`. The **Saved** tab is **not**
   filtered — a saved-but-closed Kolab still appears (labeled per #2). Client-side only;
   server-side query exclusion is a noted future optimization, not in scope.
2. **#1/#2 Detail sheet (`explore_detail_sheet.dart`) and
   `community_offer_detail_screen.dart`:** compute `open = opportunityApplicationsOpen(o)`.
   When `!open`: render an **"Applications closed"** label near the CTA and render Apply
   **disabled** (`onPressed: null`) — it must **not** fall through to the
   subscribe/paywall path. When `open`: behaviour unchanged
   (`canApply ? onApply : onSubscribe`).
3. **#3 Modal guard (`apply_modal.dart`):** `ApplyModal.show()` early-returns `null` with
   a snackbar (`applyModalClosedSnack`) when `!open`, so the modal is unreachable in the
   empty-dates state even if a caller forgets to gate. The existing inline
   `applyModalNoDates` error stays as a harmless last-resort fallback.
4. **i18n:** new keys in en/es/ca — `exploreApplicationsClosed`
   ("Applications closed" / "Inscripciones cerradas" / "Inscripcions tancades") and
   `applyModalClosedSnack` ("Applications for this Kolab are closed" / …). es =
   Castilian. Run `flutter gen-l10n`.

## Backend change (kolabing-v2) — item #4 (minimal guard)

1. Add `Kolab::hasSelectableDatesFrom()` + `applicationsOpen()` mirroring the window +
   `recurring_days` logic from `AcceptApplicationRequest.php:74-114`, and refactor
   `AcceptApplicationRequest` to reuse the model helper (removes the flagged
   duplication — no behaviour change at accept time).
2. In `ApplicationService::validateCanApply()`, after the existing checks, reject when
   `!$kolab->applicationsOpen()` → throw the domain exception used by the apply path with
   `error_code: applications_closed` and a clear message → surfaces as HTTP 422.
3. **No change to the apply request payload.** The free-text `availability` → structured
   `selected_date(s)` refactor is explicitly **out of scope** and logged as a follow-up
   (BACKLOG / a new ticket).

## Error handling

- App: `!open` disables the CTA and shows a static label; the modal guard shows a
  transient snackbar. No exceptions thrown on the happy path.
- Backend: a closed/expired apply returns 422 `applications_closed`. The app's existing
  apply error handling surfaces the backend `message`; because the client already gates,
  this path is defense-in-depth (only reachable via a stale card or direct API call). If
  the app receives `applications_closed`, it shows the same "Applications closed" copy.

## Testing

**App**
- Unit: `opportunityApplicationsOpen` — past window ⇒ false; future/today window ⇒ true;
  `recurring` with an upcoming allowed weekday ⇒ true, with none remaining ⇒ false;
  `status == closed`/`completed` ⇒ false regardless of dates.
- Widget: detail sheet with a closed opportunity shows `exploreApplicationsClosed` and a
  disabled Apply (no navigation, no subscribe fallthrough).
- `ApplyModal.show()` with a closed opportunity does not push the sheet and returns null.
- Deck filter: a closed opportunity is absent from the discovery deck list but present in
  the Saved list.

**Backend**
- Feature: `POST` apply to a date-exhausted Kolab ⇒ 422 `applications_closed`; apply to a
  `closed`/`completed` Kolab ⇒ 422; apply to an open Kolab ⇒ success.
- The shared `Kolab::hasSelectableDatesFrom()` stays covered by the existing accept-time
  window tests after the refactor.

## Workflow / delivery

Per CLAUDE.md: ticket → branch → description → code, one per repo.

- **kolabing-app:** issue on Project 4 → branch `fix/apply-date-availability-gate` off
  up-to-date `master` → PR (`Closes #<n>`), mandatory template, screenshots of the closed
  label + disabled Apply on iOS & Android.
- **kolabing-v2:** issue on Project 4 → branch `fix/apply-reject-closed-kolab` off `master`
  → PR (`Closes #<n>`), mandatory template.

Acceptance criteria:
- Apply is impossible (UI-disabled **and** API-rejected) for any closed/completed or
  date-exhausted Kolab.
- The discovery deck contains no closed Kolabs; Saved still shows them, labeled.
- A direct `POST` apply to a closed/expired Kolab returns 422 `applications_closed`.
- `flutter analyze` 0 new issues; new unit/widget/feature tests green; i18n present in
  en/es/ca; BACKLOG updated.

## Out of scope (follow-ups)

- Free-text `availability` → structured `selected_date(s)` payload refactor.
- Server-side exclusion of closed Kolabs from the discovery query (bandwidth optimization).
- A server-authoritative `applications_closed` computed field on the opportunity resource
  (client computes it today; add later if a second client appears).
- Capacity/slots enforcement (no capacity column exists today).
