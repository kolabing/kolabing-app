# Backend — Scale audit & query optimization (NF-15)

> **Target repo:** `kolabing-v2` (some app-side list rendering follows). **Goal:** the
> API stays fast and query-bounded as communities/members/events/messages grow to
> **hundreds–thousands** per community and platform-wide. Today several list endpoints
> issue **O(N) queries per page** (per-row work in Resources + per-thread loops), which
> is fine at current data sizes but degrades linearly with scale.
>
> This is an **audit + fix** ticket: instrument, measure under seeded load, then remove
> the N+1s, add indexes, and bound result sets. Do it in slices (below), each shippable.

---

## 0. Known hot spots (verified in code — start here)

### 0.1 `EventResource` — counts per event (N+1) — **HIGH**
`app/Http/Resources/Api/V1/EventResource.php` calls `app(EventSignupService::class)` per
event: `goingCount()` + `waitlistCount()` (+ `signupFor()` for the viewer) = **up to 3
queries per event**. `GET /events` paginates up to 50 → ~150 queries/request.
- **Fix:** `withCount` with status constraints for going/waitlist; batch the viewer's
  sign-ups in ONE query keyed by `event_id` and inject (transient attr) before the
  Resource. No per-row service calls inside Resources.

### 0.2 `ChatService::visibleThreads` — per-thread unread loops (N+1) — **HIGH**
`app/Services/ChatService.php`: `visibleCollaborationThreads` + `visibleCommunityThreads`
+ `visibleEventThreads` each loop and call `unreadForThread()` / `unreadForCommunityThread()`
**once per thread** → N+1 unread COUNT queries. `GET /chats` also returns **all** visible
threads unpaginated.
- **Fix:** compute unread in **grouped queries** (one for collaboration via existing
  `getUnreadCountByApplication`, one for thread-based via a single GROUP BY `thread_id`
  joined to `chat_thread_reads.last_read_at`). Consider paginating/cap­ping `GET /chats`
  (a power-leader can be in many threads).

### 0.3 `GET /events` time filter is not index-friendly — **MED**
`EventService::list` filters on `COALESCE(ends_at, starts_at, event_date)`. A functional
expression won't use a plain b-tree index.
- **Fix:** either backfill a single canonical `starts_at`/`ends_at` (and index it) so the
  filter is a column comparison, or add a Postgres **functional index** on the COALESCE
  expression. Decide and document.

### 0.4 Notification / broadcast fan-out — **MED (forward-looking)**
When community-wide / event-wide message push lands (not yet built), pushing to every
member must be **batched** (chunked `SendPushNotification`), not one query/job per member.
Reverb broadcast to large channels + connection scaling (Redis) needs sizing.

---

## 1. Audit method (do this first, it scopes everything)
1. **Instrument** staging with query logging (Telescope or a request-level
   `DB::listen` counter middleware). Emit `X-Query-Count` + duration per request.
2. **Seed at scale** (a new `db:seed --class=ScaleSeeder` or an artisan command):
   e.g. 50 communities × (500–2000 members, 20 events each, 10 custom chats, 5k chat
   messages, signups w/ waitlists). Make sizes configurable.
3. **Load test** key endpoints with k6/Artillery at that data size; capture
   **p50/p95/p99 latency, query count, peak memory** per endpoint.
4. **EXPLAIN ANALYZE** the slow/hot queries on Postgres; record seq scans on hot paths.

### Endpoints to profile (priority order)
`GET /chats`, `GET /chats/unread-count`, `GET /chats/{thread}/messages`, `GET /events`
(+ `?community_id`/`time`/`attendee=me`), `GET /events/{event}/signups`,
`GET /communities/{id}/members` (roster), the dashboard + leaderboard endpoints.

## 2. Fix patterns (apply where the audit shows O(N))
- Replace per-row Resource service calls with **`withCount` / eager `with()` / batched
  lookups** injected as transient attributes.
- **Grouped aggregate** queries for unread counts (no per-thread COUNT).
- **Cursor pagination** for message history + cap/paginate thread lists.
- `select()` only needed columns on wide rows; avoid loading blobs in lists.
- **Add covering indexes** where EXPLAIN shows seq scans (e.g. `event_signups(event_id,status)`
  exists; verify `notifications(profile_id, read_at)`, `chat_messages(thread_id, created_at)`
  [exists], `community_members(community_id, status)`, `events(community_id, …)`).
- **Cache** hot, expensive aggregates with explicit invalidation only where correctness allows.
- Chunk/queue fan-out (notifications, broadcasts) for large audiences.

## 3. Acceptance
1. Each audited **list endpoint is query-bounded**: query count does NOT grow with page
   size or row count (no per-row/per-thread queries) — assert via a query-count test.
2. At seeded scale (1000s/community), **p95 within budget** (propose ≤300ms app-server
   time for list endpoints; agree the number with Daniel).
3. EXPLAIN shows **index usage** (no seq scans) on the hot queries; missing indexes added
   via migration.
4. `GET /chats` and other unbounded lists are **paginated or capped**.
5. A short **load-test report** (before/after query counts + latencies) committed under
   `docs/` and the fan-out paths chunked.

## 4. Out of scope
- Horizontal Reverb cluster sizing / infra (separate ops ticket) — but document the
  connection/Redis requirements discovered here.
- App-side virtualization of very long lists (separate app ticket) — note any endpoints
  that hand back too much.

## Notes / provenance
Surfaced during NF-CHAT Phase 3 (`feat/chat-phase3-events-rsvp`, PR #18): `EventResource`
counts and `visibleThreads` unread loops were written correct-but-not-yet-optimized at
current scale. This ticket is the deliberate optimization pass before scaling up.
