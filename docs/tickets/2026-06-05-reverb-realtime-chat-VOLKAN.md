# Ticket (for Volkan) — Turn on real-time chat with Laravel Reverb (NF-16 B4)

> **Owner:** Volkan (backend/infra + a bit of Flutter).
> **Repos:** `kolabing-v2` (Laravel, ops) + `kolabing-app` (Flutter client).
> **Status:** the message-broadcast CODE exists; this is a wiring/ops job + a
> Flutter client. Today chat messages only appear on manual refresh because
> nothing is delivering them live.

## Why
Community / event / kolab chats work, but a new message doesn't show until the
user reloads the thread. Reverb (Laravel's first-party WebSocket server, speaks
the Pusher protocol) pushes new messages to open threads instantly.

## What already exists (do NOT rebuild)
- `App\Events\NewChatMessage` implements `ShouldBroadcast` (QUEUED) and broadcasts
  on `PrivateChannel("chat.thread.{threadId}")` with the message payload. It is
  dispatched when a message is sent.
- `/broadcasting/auth` is registered (`withBroadcasting()` in `bootstrap/app.php`)
  behind `auth:sanctum`.

So the app emits broadcasts already — they just go nowhere until the server is
running and a client subscribes.

---

## PART A — Backend / ops (kolabing-v2)

### A1. Channel authorization (verify / add)
In `routes/channels.php`, authorize the private channel so a user can only
subscribe to threads they may access:
```php
use App\Models\Profile;
use App\Services\ChatService;

Broadcast::channel('chat.thread.{threadId}', function (Profile $user, string $threadId) {
    $thread = \App\Models\ChatThread::find($threadId);
    return $thread !== null && app(ChatService::class)->canAccessThread($user, $thread);
});
```
`canAccessThread` already encodes all the rules (collab participants,
community_main = members, community_custom = tier `chat_channels`, event/series =
going sign-up or manager). Reuse it — do not duplicate the logic.

### A2. Production env
```
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=...           REVERB_APP_KEY=...      REVERB_APP_SECRET=...
REVERB_HOST=ws.kolabing.com REVERB_PORT=443         REVERB_SCHEME=https
# client-facing (exposed to the app build):
REVERB_APP_KEY (same), REVERB_HOST, REVERB_PORT, REVERB_SCHEME
```

### A3. Run the Reverb daemon  ← required
`php artisan reverb:start` must run as a **persistent Forge daemon**
(Supervisor-managed, auto-restart on deploy). Forge → Daemons → command
`php artisan reverb:start`, directory = site root.

### A4. Run a queue worker  ← #1 cause of "it's silent"
`NewChatMessage` is **queued**, so broadcasts never fire without a worker:
`php artisan queue:work --queue=default` as a **second Forge daemon**. If you skip
this, everything looks wired but no message is ever delivered.

### A5. Nginx / TLS for WebSockets
Expose `wss://` on 443 to the Reverb port. Easiest: a subdomain
`ws.kolabing.com` whose Nginx `location /` proxies to `127.0.0.1:8080` (Reverb)
with the upgrade headers:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "Upgrade";
proxy_http_version 1.1;
```
Forge's built-in Reverb integration sets most of this up — prefer it if available.

### A6. Smoke test (server side)
With both daemons up: send a message via the API, then `php artisan reverb:start`
logs should show a broadcast on `chat.thread.{id}`. `laravel.log` queue entries
should drain (not pile up).

---

## PART B — Flutter client (kolabing-app)

This is the `TODO(NF-16 B4)` in `lib/features/chat/screens/chat_thread_screen.dart`.

### B1. Add an Echo/Pusher-protocol client
Add `laravel_echo` + a Pusher-channels client (Reverb speaks the Pusher
protocol). Point it at the Reverb host/key from env; auth via an **authorizer**
that POSTs `/broadcasting/auth` with the Sanctum bearer token
(`AuthService.getToken()`), exactly like every other authed call (build the URL
from `ApiConfig.baseUrl`).

### B2. Subscribe in the thread screen
In `ChatThreadScreen` `initState`/`didChangeDependencies`:
- `echo.private('chat.thread.${thread.id}').listen('NewChatMessage', (e) { append message to the list state })`.
- Replace the manual "reload on return" with live append; keep a reload as a
  reconnect fallback.
- **Unsubscribe + disconnect in `dispose()`** (leak/duplicate-listener guard).

### B3. Inbox badge (nice-to-have)
Optionally bump `chatUnreadProvider` when a message lands on a thread you're not
currently viewing.

---

## Acceptance criteria
- Two simulators, same thread: a message sent on A appears on B **without
  refresh**, < 1s.
- A user who is NOT allowed in the thread is rejected at `/broadcasting/auth`
  (cannot subscribe).
- Killing the queue worker stops delivery (confirms the queue path); restarting
  resumes it.
- App reconnects after backgrounding (Echo auto-reconnect) and still receives.

## Gotchas
- **No queue worker = no delivery** (A4) — check this first if it's silent.
- The authorizer MUST send the Sanctum token, or every private subscribe 403s.
- Use `wss://` (not `ws://`) in production or iOS ATS blocks it.
- One Echo instance app-wide; subscribe per open thread, unsubscribe on dispose.

## References
- App entry point: `lib/features/chat/screens/chat_thread_screen.dart` (the TODO).
- Access rules: `app/Services/ChatService.php::canAccessThread`.
- Broadcast auth registration: `bootstrap/app.php` (`withBroadcasting`).
