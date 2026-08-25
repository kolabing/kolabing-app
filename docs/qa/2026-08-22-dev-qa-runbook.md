# Dev QA runbook — event-challenge QR gamification

> Issue #136. Gets you from nothing to "the QR loop is testable" against the
> **development** backend, with fixed accounts.
>
> The scenarios themselves live in
> [`2026-08-22-event-challenge-qr-test-plan.md`](./2026-08-22-event-challenge-qr-test-plan.md).
> This file is only about getting set up.

---

## 1. Seed the data (backend)

The command lives in `kolabing-v2`:

```bash
php artisan kolabing:seed-qa-gamification          # asks before writing
php artisan kolabing:seed-qa-gamification --fresh  # rebuild the event + kolab
php artisan kolabing:seed-qa-gamification --force  # non-interactive
```

> ### ⚠️ Run this against **development**, not production
>
> `kolabing-v2/.env` currently has `DB_DATABASE=main`, and
> `docs/BACKEND-SCHEMA.md` documents `main` as **production**. Running the
> command as-is would target production.
>
> The command therefore prints its target (`APP_ENV`, host, database) and
> **refuses outright** when the database is named `main`, unless you pass
> `--force`. Point at the dev environment first — either run it from the
> development environment's console, or temporarily point `.env` at the dev
> database.

### What it creates

Everything the loop needs, in one transaction, keyed so re-running is safe:

| | |
|---|---|
| **Business** | `hello@eixample46.com` — pre-existing, *not* created. The command fails loudly if it is absent, which also tells you you are on the wrong database. |
| **Community leader** | `qa-leader@kolabing.test`, owner of `[QA] Eixample Runners` |
| **Attendee A** | `qa-attendee-a@kolabing.test` — the challenger |
| **Attendee B** | `qa-attendee-b@kolabing.test` — the verifier |
| **Password** | `Kolabing2026!` for every seeded account |
| **Community** | `join_policy: open`, a default `Member` tier, a main chat thread, and all three profiles as `active` members (the leader with `can_manage`) |
| **Kolab** | `Kolab (published) → Application (accepted) → Collaboration (active)` between the community and the business — the real chain, formed the way `ApplicationService::accept` forms one |
| **Event** | `[QA] Gamification Test Run`, today 18:00–22:00, `visibility: public`, capacity 50, under that community, hosted by the leader |
| **Sign-ups** | both attendees `going` — which is what makes the app show **Check in** |
| **Challenges** | three on that event: 5 / 15 / 30 points (easy / medium / hard) |

Two attendees, not one, because the loop is two-person: one shows a code and the
other scans it. A single account cannot test it.

The event is created with **no check-in token** on purpose — the organizer
minting one is step 1 of what you are testing.

Everything carries a `[QA]` marker so it can be found and deleted.

---

## 2. Point the app at dev

`Environment.current` resolves from `--dart-define=APP_ENV`, falling back to
**prod in release, dev in debug**. So a debug build is already on dev; pass the
define anyway so it is explicit and cannot drift:

```bash
# simulator
flutter build ios --simulator --debug --dart-define=APP_ENV=dev
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.kolabing.kolabingApp

# or straight onto a connected device / simulator
flutter run --dart-define=APP_ENV=dev
```

| | dev | prod |
|---|---|---|
| API | `kolabing-v2-development-uhzrzd.laravel.cloud/api/v1` | `kolabing.com/api/v1` |
| QR / share host | the same dev host | `kolabing.com` |

Confirm you are on dev before trusting a result: the check-in QR's short link
should point at the dev webapp host, not `app.kolabing.com`.

---

## 3. Flags opened for this QA

Both are in `lib/config/feature_flags.dart`.

| Flag | State | Why |
|---|---|---|
| `kEventCheckinQrEnabled` | on | The loop itself (#132) |
| `kCommunityMembersTabEnabled` | **on (changed here)** | The **Members** tab on community detail — the seeder gives it real rows to show |
| `kAttendeeSignupEnabled` | **on (new here)** | Lets QA register *additional* attendees. Sign-up was closed in `820e3b7`, which removed the only way to create a test attendee |
| `kGamificationSetupEnabled` | off | The collaboration-detail challenge block is still unfinished — deliberately left hidden |

> ### ⚠️ Release decision before any store build
>
> `kAttendeeSignupEnabled` makes attendee sign-up **publicly reachable**. It was
> closed on purpose when the attendee track left launch scope. This branch opens
> it so QA can create accounts; whether it stays open is a product call and must
> be settled before a store build. The seeded accounts work regardless — sign-in
> was never gated.

---

## 4. First run, in order

1. Seed (§1) and keep the printed table — it has every id and credential.
2. Install the dev build (§2) on **two** devices, at least one of them real
   (simulators have no camera).
3. Sign in as `qa-leader@kolabing.test` → the community → `[QA] Gamification
   Test Run` → **⋮ → Show check-in QR**.
4. On device 1, sign in as attendee A → that event → **Check in** → scan the
   leader's QR. Expect the success sheet, then **SCAN SOMEONE**.
5. On device 2, sign in as attendee B and do the same.
6. B: app-bar QR icon → **My QR code**. A: scan it. The three seeded challenges
   should be listed under an **"At [QA] Gamification Test Run"** chip.
7. A: pick one → the verification QR appears. B: scan A's screen → **VERIFY**.
   A's screen should flip to **+N XP** within about three seconds.

If step 6 says "Check in first", step 4 did not take — check that the sign-up
row exists and that the event is today.

---

## 5. Cleaning up

`--fresh` drops the previous QA event and kolab (with their challenges,
sign-ups, and the application) and rebuilds them. Accounts, the community and
its memberships are kept on purpose: their ids end up in QA notes, and
re-registering every run is friction for no benefit.

To remove everything, delete by the marker: the `[QA] ` prefix on the community
name, event name, kolab title and challenge names, plus the three
`*@kolabing.test` profiles.
