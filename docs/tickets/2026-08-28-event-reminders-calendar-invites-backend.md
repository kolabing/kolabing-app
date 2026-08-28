# Backend contract — Event reminders (24h + 1h) and ICS calendar invitations

> **Repo:** `kolabing-v2` (Laravel). **Companion app work:** `kolabing-app` issue
> [#191](https://github.com/kolabing/kolabing-app/issues/191), branch
> `feat/event-reminders-calendar-invites`.
> **Design:** [`docs/plans/2026-08-28-event-reminders-calendar-invites-design.md`](../plans/2026-08-28-event-reminders-calendar-invites-design.md).
> **Approved by:** Volkan, 2026-08-28.

An attendee who signs up for an event gets **two push reminders** (24h and 1h before) and
a **calendar invitation by email** on RSVP that stays correct when the event moves or is
cancelled. No Google OAuth anywhere.

---

## B0. Verify before you build

- [ ] **Can `notification_reminders` carry the send ledger?** It needs a unique key on
      `(event_id, profile_id, type)`. Inspect the live table (db `main`) before adding
      anything. Per CLAUDE.md: never invent columns — if it does not fit, add a purpose-built
      table and say so here.
- [ ] Confirm `events.starts_at` / `ends_at` are stored as UTC timestamps (the app sends
      `toUtc().toIso8601String()`). Every window below assumes UTC instants.
- [ ] Confirm `profiles.email` is populated for attendee accounts created through Google /
      Apple social login — an empty address means no invitation.

## B1. Two new notification types

`event_reminder_24h`, `event_reminder_1h`. Add to the notification type enum, the
`notifications` payload, and the OneSignal dispatch path alongside the existing
`CollabDayReminder`.

**Payload must carry `event_id`** and a deeplink the app can resolve to `/event/{id}` —
the app maps both types to the existing `EventDetailScreen` route.

**Copy must be duration-relative**, not a fixed string. The 1h sweep has catch-up
behaviour, so an attendee may legitimately receive it 20 minutes out; "in 1 hour" would
then be a lie. Render from the actual delta.

**Localise by the recipient's `profiles` locale** (en / es-castilian / ca). The app cannot
translate a server-rendered push — without this, every reminder arrives in English.

## B2. `events:send-reminders` — stateless sweep, every 5 minutes

Register in `routes/console.php` at `everyFiveMinutes()`. Note that the existing
`notifications:send-reminders` command is **not** registered today (`docs/BACKLOG.md` §2);
do not confuse the two.

Query `event_signups ⋈ events` where `event_signups.status = 'going'` and
`events.starts_at` is non-null and in the future:

```
event_reminder_24h  →  starts_at ∈ (now + 23h, now + 24h]
event_reminder_1h   →  starts_at ∈ (now,       now +  1h]
```

- The command **re-derives these windows from `starts_at` on every run**. Do not
  materialise per-signup reminder rows at RSVP time — the whole point is that moving an
  event needs no rescheduling.
- The 24h window's one-hour tolerance absorbs a missed run. It deliberately does **not**
  back-fire: an attendee who RSVPs 3 hours before the event must never receive a
  "tomorrow" reminder.
- Guard every send through the `(event_id, profile_id, type)` unique key so overlapping or
  re-run crons cannot double-send.
- **Waitlisted sign-ups get nothing.** An auto-promoted waitlister is already `going` by
  the time the sweep sees them.

**Quiet hours:** `event_reminder_24h` respects `quiet_hours_start` / `quiet_hours_end`
resolved through `notification_preferences.timezone`. `event_reminder_1h` **overrides
them** — time-critical by design. Document that exception in the code.

## B3. Schema addition request

- [ ] `events.ics_sequence` — `integer NOT NULL DEFAULT 0`. Incremented whenever the
      event's time or location changes, and used as the ICS `SEQUENCE` so calendars update
      the existing entry instead of creating a duplicate.

## B4. `EventInvitation` mailable + ICS builder

Queued mail to `profiles.email` on `POST /events/{id}/signup` when the resulting status is
`going`. Attachment `Content-Type: text/calendar; method=REQUEST; charset=UTF-8`.

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Kolabing//Events//EN
METHOD:REQUEST
BEGIN:VEVENT
UID:event-{event_id}@kolabing.com          ← stable per EVENT, not per attendee
SEQUENCE:{events.ics_sequence}
DTSTAMP:{now in UTC, Z}
DTSTART:{starts_at in UTC, Z}
DTEND:{ends_at ?? starts_at + 2h, in UTC, Z}
SUMMARY:{event name}
LOCATION:{location / address / city_name, composed}
DESCRIPTION:{community name}\n{event universal link}
ORGANIZER;CN={community name}:mailto:{sending address}
ATTENDEE;CN={attendee name};RSVP=TRUE:mailto:{profiles.email}
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
```

`UID` is per-event on purpose: it makes the event the *same* event across every attendee's
calendar and lets updates land in place. `ends_at` fallback of `+2h` is a configurable
default, not a rule.

## B5. Calendar lifecycle

| Trigger | Action |
|---------|--------|
| `PUT /events/{id}` changes `starts_at`, `ends_at` or `location` | `ics_sequence++`; re-send `METHOD:REQUEST` with the same `UID` to **every** `going` attendee |
| `DELETE /events/{id}` | `METHOD:CANCEL` + `STATUS:CANCELLED` + `ics_sequence++` to every `going` attendee |
| `DELETE /events/{id}/signup` | `METHOD:CANCEL` to **that attendee only** |

Recurring series: each occurrence is its own `events` row with its own `UID`, so
`?scope=following|series` fans out per occurrence. **No `RRULE`** — it would duplicate
state the backend already models row-wise.

Edits that touch neither time nor location (a renamed event, a new photo) should not bump
`SEQUENCE` or re-mail; churn in someone's calendar is its own kind of spam.

## B6. Global `NotificationPreference` filter

This closes the `docs/BACKLOG.md` §2 P1 gap and was explicitly chosen over a
reminder-only filter.

- [ ] One choke point in `NotificationService`, before any dispatch: load the recipient's
      `notification_preferences`, map notification type → preference key, drop when
      disabled, and apply quiet hours through `timezone`.
- [ ] New preference key **`events_enabled`** (the app writes it on the same key).
- [ ] **A missing preferences row means everything is enabled** — opt-out semantics. An
      opt-in default would silently mute every existing user.
- [ ] **Regression test per existing notification type.** A mis-mapped key silently kills
      a working notification, and this filter now sits in front of `NewMessage`,
      `ApplicationReceived`, `ApplicationAccepted`, `ApplicationDeclined`,
      `ChallengeVerified`, `RewardWon`, `CollabDayReminder`, `CollabFollowUpReminder`,
      `KolabCreateIncomplete`, `ApplicationPending` and `UnreadMessage`. This is the
      accepted risk of the root fix.

## B7. Blocker — mail transport

`docs/BACKLOG.md` §1 has Postmark planned but **`POSTMARK_API_KEY` and
`MAIL_MAILER=postmark` are not wired in production**. B1–B3 and B6 ship without it; B4 and
B5 cannot. Wire the mailer (and a real `ORGANIZER` sending address, e.g.
`events@kolabing.com`, with SPF/DKIM aligned so invitations are not filtered) before
shipping the calendar half.

## Acceptance criteria

- A `going` attendee receives exactly one `event_reminder_24h` and one
  `event_reminder_1h`, never duplicated across cron runs, and nothing at all when
  `events_enabled` is false.
- An attendee who RSVPs 40 minutes before an event receives one duration-accurate
  "starting soon" push and no 24h reminder.
- Moving an event updates the entry already in the attendee's calendar (same `UID`, higher
  `SEQUENCE`) instead of creating a second one.
- Cancelling the event, and withdrawing a single RSVP, each remove it from the right
  calendars and no others.
- Every notification type listed in B6 still delivers under default (missing-row)
  preferences.
