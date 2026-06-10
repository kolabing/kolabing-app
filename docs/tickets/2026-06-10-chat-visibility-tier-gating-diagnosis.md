# Diagnosis + fix — attendee "not all chats appear available" (#4)

> **Verdict:** NOT a data/sync bug. The tier-gating worked as designed; the
> *default* was the problem — newly created custom chats were hidden from everyone
> until a leader explicitly granted each tier access.
>
> **✅ DECISION (Daniel, 2026-06-10): Option A — default-open.** Implemented in
> `kolabing-v2` `ChatService::createCustomChat` (+ new `grantChatToAllTiers`
> helper): a new ungated chat now appends its slug to every tier's
> `permissions.chat_channels`, so it is visible to all members immediately. The
> leader can still RESTRICT it afterwards via the per-chat Access picker.
> **Pending push + deploy + verify.**

## What the app does
Nothing. `ChatsScreen` renders whatever `GET /chats` returns; there is **no
client-side filtering** of threads by tier/slug/type. The `slug` field is only
used by the leader's per-chat "Access" picker UI. So the gap is 100% backend
(`ChatService::visibleThreads`).

## Backend logic (`kolabing-v2/app/Services/ChatService.php`)
A community member who is **not** the owner and **not** `can_manage` sees a
**custom** community chat only when:
```php
in_array($thread->slug, $tier->permissions['chat_channels'], true)   // L490
```
- The **CommunityMain** chat is always visible (L471-472).
- The **default tier** every member joins on is created with
  `'chat_channels' => []` (`CommunityService::createDefaultTier`, L103).
- `createCustomChat` (L262) does **not** add the new chat's slug to any tier's
  `chat_channels`.

**Result:** create a custom chat → it is invisible to all non-manager members
(they only see the main chat) until the leader opens the per-chat Access picker
and grants each tier. Members with `tier_id = null` see no custom chats either.

## Recommended fix (needs approval — changes gating default)
**Option A (default-open, recommended):** when `createCustomChat` runs, append
the new slug to the **default tier's** `permissions.chat_channels` (or all tiers)
so a new chat is visible by default; the leader can still *restrict* it later via
the existing Access picker. Matches the natural expectation "I made a chat, my
members can see it."

**Option B (keep default-closed, fix UX):** leave gating as-is but surface in the
leader UI that a brand-new chat is hidden until access is granted, and badge
ungranted chats.

## Why held, not applied
CLAUDE.md / ROLES docs: "if a fix seems to contradict these docs, STOP and ask
before changing role behaviour." Default-open vs default-closed is a product
decision on community access, so this is documented, not silently flipped.

## Acceptance (once a direction is chosen)
1. Attendee on the default tier sees the chats Daniel intends (all custom, or a
   clearly-communicated subset).
2. Leader can still restrict a chat to specific tiers via the Access picker.
3. `GET /chats` for the attendee returns exactly that set — verified live.
