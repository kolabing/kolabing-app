# Backend P0 — event sign-up 500s for EVERYONE (Postgres `FOR UPDATE` + `count()`)

> **Target repo:** `kolabing-v2` · `app/Services/EventSignupService.php` · **production-only**.

## Symptom (reproduced on prod, 2026-06-10)
`POST /events/{id}/signup` → **HTTP 500** `{"message":"Server error"}` for **every** event
and **every** user (attendee AND community owner), fresh or existing events. No
`event_signups` row is created (transaction rolls back). `GET /events…` and
`GET /events/{id}` are fine. So it's the sign-up transaction, not data or serialization.

## Root cause
`EventSignupService::signup()`:
```php
$goingCount = EventSignup::query()
    ->where('event_id', $event->id)
    ->where('status', EventSignupStatus::Going->value)
    ->lockForUpdate()   // ← generates: SELECT count(*) … FOR UPDATE
    ->count();
```
**PostgreSQL forbids `FOR UPDATE` with an aggregate** (`count()`) →
`SQLSTATE: FOR UPDATE is not allowed with aggregate functions` → 500.

It passed CI because **tests run on SQLite** (`phpunit.xml` + `.env.testing`:
`DB_CONNECTION=sqlite, :memory:`), which *allows* `FOR UPDATE` + aggregate. **Production
is Postgres** (`db main`) → it throws. (863 green tests, 100% broken in prod.)

This is the only broken spot — the other `lockForUpdate()` calls are row `->first()`
selects (legal on Postgres); `goingCount()/waitlistCount()` use a plain `count()`;
`nextWaitlistPosition()` uses `->max()` with no lock.

## Fix
Serialize concurrent sign-ups by locking the **event row** (a legal `SELECT … FOR
UPDATE` on a single row), then count **without** a lock:

```php
return DB::transaction(function () use ($event, $profile): EventSignup {
    // Serialize all sign-ups for this event (legal row-level lock on Postgres).
    Event::query()->whereKey($event->id)->lockForUpdate()->first();

    $existing = EventSignup::query()
        ->where('event_id', $event->id)
        ->where('profile_id', $profile->id)
        ->first();                       // event-row lock already serializes us

    if ($existing !== null && $existing->status !== EventSignupStatus::Cancelled) {
        return $existing;
    }

    $goingCount = EventSignup::query()
        ->where('event_id', $event->id)
        ->where('status', EventSignupStatus::Going->value)
        ->count();                       // ← no lockForUpdate()
    …
});
```
(Drop `->lockForUpdate()` from the `$existing->first()` too — the event-row lock covers it.)

## Guardrail (so this never reships)
- Add a **Postgres** test lane in CI (the sign-up/capacity/waitlist suite at minimum),
  or a `pgsql` matrix entry. SQLite-only testing hid a 100%-prod-down bug.
- Grep for other `->lockForUpdate()->count()` / `->lockForUpdate()->max()` /
  `->lockForUpdate()->sum()` patterns repo-wide.

## Acceptance
1. `POST /events/{id}/signup` (member & owner) → 200, row created, `my_signup=going`.
2. Capacity + waitlist still serialize under concurrent joins (event-row lock).
3. Sign-up suite green on **Postgres**, not just SQLite.
