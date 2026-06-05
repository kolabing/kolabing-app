# Plan — Recurring events follow-ups (post-merge)

> Created 2026-06-05. Base: everything below builds on the shipped Phase-1
> recurring engine (`event_series`, `events.series_id/occurrence_index`,
> `chat_threads.series_id`, `EventSeriesService.materialize/extend/deleteScope`)
> now on master in both repos.
>
> **Branch strategy:** cut a fresh `feat/recurring-followups` off `master` (do
> NOT reuse `community-member-flow`, which is merged; keep it as history). Build
> each item translation-ready (CLAUDE.md i18n rule).

The five items, smallest-first. Items 1–4 are recurring polish; item 5 (Kolab
bridge) has its own ticket (`2026-06-05-events-to-kolab-bridge.md`).

---

## 1. App "Extend series" button  — effort: S (app only)
**Why:** the hybrid is "publish 3 months, extend later" but the *extend* half has
no UI yet (the backend `POST /event-series/{id}/extend` is already live).

- **App:** `EventService.extendSeries(seriesId)` → POST the endpoint, then
  `communityUpcomingEventsProvider(cid).reload()`.
- **UI:** on a recurring event's hub (leader) and/or the events list, an
  "Extend (+3 months)" action. Plus a gentle inline prompt when few future
  occurrences remain (e.g. < 3 left): "Only 2 dates left — extend?".
- **Backend:** none (done). Optional Phase-2: a nightly `schedule` command that
  auto-extends never-ending series so it's truly set-and-forget.

```
Events
  🔁 Sunday Run   Aug 23 · 09:00   (last materialised)
  [ Extend +3 months ]            ← leader-only
```

## 2. Scoped EDIT (this / following / series)  — effort: backend M, app S
**Why:** delete is scope-aware; edit isn't. Editing an occurrence today edits
only that row.

- **Backend:** `PUT /events/{id}?scope=this|following|series`.
  `EventSeriesService.updateScope(event, data, scope)`:
  - `this` → current behaviour (one row).
  - `following` / `series` → update this + matching occurrences AND the
    `event_series` template so not-yet-materialised dates inherit.
  - Propagate: name / location / capacity / tier_gate / time-of-day (shifts each
    affected occurrence's `starts_at` to the new time, keeping its date) /
    duration. Do NOT touch each occurrence's date.
- **App:** in the edit form, when `event.isRecurring`, show a scope selector on
  Save (mirror the delete dialog: This / This and following / Entire series).

```
Save changes to
  ( ) This event only
  ( ) This and the following
  (•) The entire series
```

## 3. Edit → make a one-off recurring  — effort: backend M, app S
**Why:** "on editing an event also allow to make it recurrent."

- **Backend:** accept a `recurrence` block on `PUT /events/{id}` for an event
  with no `series_id`. `EventSeriesService.convertExisting(event, recurrence)`:
  create an `event_series` from the event's current fields + recurrence, set the
  event as occurrence 0 (`series_id`, `occurrence_index = 0`, preserving its
  sign-ups), then `materialize()` the rest from the next matching date.
- **App:** stop hiding the Repeat section in edit mode; when the user picks a
  pattern on a one-off, Save converts it (calls the same PUT-with-recurrence).
- **Depends on:** item 2's PUT plumbing (share the request/scope path).

## 4. Shared-series chat delivery  — effort: backend M, app XS
**Why:** `event_series.chat_mode` + `chat_threads.series_id` already exist and the
create form lets the leader pick "one shared series chat", but `createEventChat`
still resolves a per-occurrence thread, so the choice is currently a no-op.

- **Backend (`ChatService` / event-chat create):**
  - When the occurrence's `series.chat_mode === 'series'`,
    `createEventChat`/`storeEventChat` resolves-or-creates ONE thread keyed by
    `series_id` (not `event_id`).
  - `canAccessThread` for a series thread: access if the viewer has a `going`
    sign-up on ANY occurrence of the series, OR is a community manager/owner.
  - `visibleThreads` + `threadRecipientIds`: union of going attendees across all
    occurrences (for the inbox + message fan-out).
  - Reverb channel stays `chat.thread.{id}` — no client change.
- **App:** none beyond opening whatever thread `createEventChat` returns (it
  already does). The "Open event chat" button on every occurrence then lands in
  the same shared room.
- **Test:** per_event still 1 thread/occurrence; series = 1 thread, reachable
  from any occurrence, a non-attendee blocked.

## 5. Events → Kolab bridge  — effort: backend M, app M (ROLES-sensitive)
See `docs/tickets/2026-06-05-events-to-kolab-bridge.md` (post an occurrence or a
whole series as a `collab_opportunity`; respects the business paywall on the
consume side; verify ROLES first). Build last / its own slice.

---

## Suggested order & rough sizing
1. **Extend button** (S) — fastest, endpoint live.
2. **Scoped edit** (M+S) — completes edit/delete symmetry.
3. **Edit → recurring** (M+S) — reuses #2's PUT path.
4. **Shared-series chat** (M+XS) — makes the stored `chat_mode` real.
5. **Kolab bridge** (M+M) — own slice, ROLES verify.

All on `feat/recurring-followups` off master; each item backend→app→tests, merge
when green. Phase-2 nice-to-have: nightly auto-extend (turns the hybrid into true
ongoing recurrence with zero leader action).
