# Design — Event reminders (24h + 1h) and automatic calendar invitations

> **Status:** approved by Volkan, 2026-08-28.
> **Issue:** [#191](https://github.com/kolabing/kolabing-app/issues/191).
> **Backend contract:** [`docs/tickets/2026-08-28-event-reminders-calendar-invites-backend.md`](../tickets/2026-08-28-event-reminders-calendar-invites-backend.md).
> **Branch:** `feat/event-reminders-calendar-invites`.

## The ask

An attendee who signs up for an event should be reminded **24 hours before and 1 hour
before it starts**, and the event should land in their calendar **automatically when they
RSVP** — and stay correct there if the event later moves or is cancelled.

## What the audit found

Before designing anything, the existing ground:

- **Push works, events are not in it.** OneSignal + `flutter_local_notifications` are
  live, but `NotificationType` has no event reminder at all — only `collab_day_reminder`
  and `collab_followup_reminder` (`lib/features/notification/models/app_notification.dart`).
- **The backend has half a reminder engine, unplugged.** A `notification_reminders`
  table and a `notifications:send-reminders` command exist, but per `docs/BACKLOG.md` §2
  the command **is not registered in `routes/console.php`**, and the collab reminder cron
  runs **daily at 08:00** — 1-hour precision is impossible on that cadence.
- **`NotificationPreference` is decorative.** The table and the `Profile` relation exist,
  but `NotificationService` has no runtime filter, so every push is delivered regardless
  of opt-out (`docs/BACKLOG.md` §2 P1).
- **There is no calendar code anywhere.** No `add_2_calendar`, no `device_calendar`, no
  ICS builder, no Google Calendar scope. `google_sign_in` is present but login-only.
- **Two facts that make this cheap.** `starts_at` / `ends_at` travel as **UTC ISO8601**
  (`event_service.dart:431,506`), so "24h before" and "1h before" are unambiguous
  instants with no timezone guessing; and `profiles` carries `email` +
  `email_verified_at`, so a calendar invitation needs **no Google OAuth**.

## Approach, and what was rejected

**Chosen: backend-driven reminders + ICS `METHOD:REQUEST` email invitation.**

Rejected, with reasons:

- **App-local scheduling** (`flutter_local_notifications` at RSVP time). Zero backend
  work and precise, but the reminder dies on reinstall or a new device, iOS caps pending
  local notifications at 64, and every event edit needs a client-side reschedule.
- **Google Calendar API with OAuth** (`calendar.events`). Genuinely silent insertion, but
  it is a Google-verified sensitive scope and only works for attendees who signed in with
  Google — a minority path gated behind a review process.

The ICS-email route gives a real calendar invitation, in Gmail *and* Apple Mail *and*
Outlook, for every attendee, with no OAuth. Its honest ceiling is documented below.

## 1. Reminder engine (kolabing-v2)

Two new notification types: `event_reminder_24h`, `event_reminder_1h`.

**A stateless sweep, not materialised reminder rows.** The command re-derives the window
from `events.starts_at` on every run, so when a leader moves an event nothing needs
rescheduling — the reminder simply follows. This is the single most valuable property of
the design and it comes free.

`events:send-reminders`, **every 5 minutes**, registered in `routes/console.php`. It
joins `event_signups ⋈ events` on `status = 'going'` and non-null, future `starts_at`:

| Type | Fires when | Why that window |
|------|-----------|-----------------|
| `event_reminder_24h` | `starts_at ∈ (now+23h, now+24h]` | One hour of catch-up tolerance absorbs a missed or slow cron run. Deliberately does **not** back-fire: someone who RSVPs 3 hours before the event never receives a "tomorrow" reminder. |
| `event_reminder_1h` | `starts_at ∈ (now, now+1h]` | Self-healing by construction, and correct for late RSVPs — someone who signs up 40 minutes out gets one "starting soon" nudge, which is wanted, not spam. Copy must therefore be **duration-relative**, never the literal string "in 1 hour". |

**Idempotency.** A send ledger with a unique index on `(event_id, profile_id, type)`.
`notification_reminders` already exists in the schema — reuse it if its columns can carry
that key, and only add a table if they cannot. Per CLAUDE.md this must be **verified
against the live schema**, not assumed; the contract ticket carries it as a check.

**Quiet hours.** `event_reminder_24h` respects `quiet_hours_start` / `quiet_hours_end`
(resolved through `notification_preferences.timezone`). `event_reminder_1h` deliberately
**overrides** them — it is a time-critical notice, closer to a boarding call than to
marketing.

**Only `going`.** Waitlisted sign-ups are not attending and get nothing; an auto-promoted
waitlister is simply `going` by the time the sweep sees them.

## 2. Calendar invitation (kolabing-v2)

On `POST /events/{id}/signup` returning `going`, queue an `EventInvitation` mailable to
`profiles.email` carrying an `.ics` attachment with
`Content-Type: text/calendar; method=REQUEST; charset=UTF-8`.

ICS shape:

- `UID` stable **per event** (`event-{event_id}@kolabing.com`) — so the event is the
  *same* event in every attendee's calendar, and updates land in place.
- `ATTENDEE` = the recipient; `ORGANIZER` = the community name over a real sending
  address.
- `DTSTART` / `DTEND` in UTC with the `Z` suffix; calendars render the viewer's local
  time. When `ends_at` is null, default to **`starts_at + 2h`** (a knob, not a law).
- `LOCATION` composed from `location` / `address` / `city_name`; `DESCRIPTION` carries the
  community and the event's universal link.
- `SEQUENCE` from a new `events.ics_sequence` column (int, default 0). This is an
  explicit **schema addition request** to kolabing-v2, not an assumed column.

**Full lifecycle** (Volkan's choice — a stale calendar entry is worse than none, because
it sends someone to a venue at the wrong hour):

| Trigger | Action |
|---------|--------|
| `PUT /events/{id}` changes time or location | `ics_sequence++`, re-send `METHOD:REQUEST` with the same `UID` to every `going` attendee → the existing calendar entry updates in place |
| `DELETE /events/{id}` | `METHOD:CANCEL`, `STATUS:CANCELLED` to every `going` attendee |
| `DELETE /events/{id}/signup` | `METHOD:CANCEL` to that one attendee |

Recurring series: each occurrence is already its own `events` row with its own `UID`, so
`scope=following|series` fans out per occurrence. No `RRULE` — it would duplicate state
the backend already models row-wise.

**The honest ceiling.** Gmail renders `METHOD:REQUEST` as a native invitation with
Yes/No/Maybe, and for most users it appears in Google Calendar immediately. But
auto-adding is a *user-side* Google setting; some users only see it after accepting. No
non-OAuth approach can do better, and nobody downstream should be promised silent 100%
insertion.

## 3. Notification preference filter (kolabing-v2)

Volkan chose the root fix over a narrow one: **one choke point inside
`NotificationService`**, before any dispatch — load the recipient's
`notification_preferences`, drop the send if the mapped key is disabled, apply quiet hours
via `timezone`. New key `events_enabled`.

- **A missing preferences row means everything is enabled** (opt-out, not opt-in), so no
  existing user goes silent when the filter lands.
- **Accepted risk:** this touches every notification type already in production
  (`NewMessage`, `ApplicationReceived`, `ApplicationAccepted`, …). A mis-mapped key
  silently kills a working notification, so the type→key map needs a regression test per
  type. This is the cost of closing the `docs/BACKLOG.md` §2 P1 gap and was accepted
  knowingly.

## 4. App side (this repo)

Small, and mostly plumbing:

- `lib/features/notification/models/app_notification.dart` — `eventReminder24h` /
  `eventReminder1h` enum values plus `fromString` / `toApiValue` wire mappings.
- `lib/features/notification/utils/notification_navigation.dart` — both types resolve to
  `/event/{id}` (the existing `EventDetailScreen` route).
- `lib/features/business/models/notification_preferences.dart` +
  `lib/features/settings/screens/notification_settings_screen.dart` — an `eventsEnabled`
  field on the `'events_enabled'` wire key, surfaced as a toggle.
- **i18n is mandatory**: new toggle strings into `app_en.arb` → `app_es.arb` (Castilian)
  → `app_ca.arb`, then `flutter gen-l10n`.
- Tests: wire-value round-trip for both new types, navigation mapping, settings toggle
  widget test.

**Push copy is rendered server-side**, so the backend must localise by the recipient's
`profiles` locale or the reminders arrive in English regardless of the app's language.
Tracked as a contract item, not an app fix.

## 5. Deliberately out of scope

Reminders for the community leader/host (the ask was about attendees), reminders for
waitlisted sign-ups, SMS delivery (NF-10 is its own feature), Google Calendar OAuth, and
`RRULE`-based recurring ICS.

## 6. Blockers to clear before the calendar half can ship

1. **No mailer is configured.** `docs/BACKLOG.md` §1 has Postmark planned, but
   `POSTMARK_API_KEY` and `MAIL_MAILER=postmark` are not wired in production. The
   reminder half ships without it; the invitation half cannot.
2. **Google's auto-add is a user setting**, per the ceiling noted in §2.

## Acceptance criteria

- A `going` attendee on an upcoming event receives exactly one `event_reminder_24h` and
  one `event_reminder_1h` — never duplicated across cron runs.
- Tapping either push opens that event's detail screen, from cold start and from
  background.
- RSVP produces an email whose `.ics` opens as a calendar invitation in Gmail at the
  correct local start time.
- Moving the event updates the entry already in the attendee's calendar rather than
  creating a second one; cancelling the event, and withdrawing the RSVP, both remove it.
- Switching the event-reminders toggle off stops both reminders for that account, and
  every pre-existing notification type still delivers under default preferences.
- `flutter analyze` clean, `dart format` on touched files only, i18n in all three ARBs,
  tested on iOS and Android.
