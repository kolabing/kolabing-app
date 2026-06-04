# Bug — community lists don't refresh after a mutation (APP-side, NF-6)

> **Repo:** `kolabing-app` (Flutter). **Branch:** `community-member-flow`.
> **Symptom:** create/delete a tier (also create community, add/remove member)
> succeeds on the server, but the visible list **does not update until the app
> is fully closed and reopened.**

## Reproduce
1. Log in as a community user (e.g. `realrunclub@gmail.com`).
2. Community tab → Add tier (or tap a tier → Delete).
3. The tier is saved server-side, but the on-screen list is unchanged.
4. Kill + reopen the app → the list is now correct.

## Evidence (device logs, debug build)
```
🏘️ createTier → HTTP 201 ... parsed OK id=019e9249-...   ← server write OK
🏘️ tier saved → invalidated tiers for 019e91a3-...        ← refresh signal fired
   (NO "🏘️ getTiers refetched N tiers" line follows)       ← provider never re-ran
```
So the mutation and the refresh trigger both run, but the read-provider
(`communityTiersProvider`) **does not recompute** → its watching widget keeps the
stale `AsyncData`.

## Root cause
The community read-providers
(`community_providers.dart`: `myCommunitiesProvider`, `communityProvider`,
`communityTiersProvider`, `communityMembersProvider`, `myMembershipsProvider`)
are `FutureProvider` / `FutureProvider.family`. They are watched by widgets that
live **inside the role `IndexedStack`** (`community_main_screen.dart`), so those
widgets are **kept alive** the whole session.

Two refresh strategies were tried and **both failed the same way**:
1. `ref.invalidate(communityTiersProvider(id))` after the mutation.
2. A watched `CommunityRefreshTick` Notifier bumped after the mutation
   (each read-provider does `ref.watch(communityRefreshTick)`).

In Riverpod 3.x, neither reliably forced these kept-alive `FutureProvider`s to
**recompute** when triggered from the pushed editor screen's `ref`. (Note: Riverpod
3.0 also removed `StateProvider`, and changed autoDispose/keep-alive defaults — the
provider-graph reactivity here is not behaving like Riverpod 2.x.)

## Recommended fix (high confidence)
Convert the community read-providers from `FutureProvider` to
**`AsyncNotifier` / family `AsyncNotifier`** with an explicit `reload()` that sets
`state` directly — this bypasses dependency-graph reactivity entirely:

```dart
class CommunityTiersNotifier
    extends FamilyAsyncNotifier<List<CommunityTier>, String> {
  @override
  Future<List<CommunityTier>> build(String communityId) async {
    final tiers = await ref.read(communityServiceProvider).getTiers(communityId);
    return [...tiers]..sort((a, b) => b.rank.compareTo(a.rank));
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg)); // arg = communityId
  }
}

final communityTiersProvider =
    AsyncNotifierProvider.family<CommunityTiersNotifier, List<CommunityTier>, String>(
        CommunityTiersNotifier.new);
```
After each mutation, call:
```dart
ref.read(communityTiersProvider(communityId).notifier).reload();
```
`state = ...` on a Notifier is an unconditional emit → the watching widget
rebuilds immediately, regardless of keep-alive/IndexedStack. Do the same for
communities (`reload` myCommunities) and members. Then remove the
`communityRefreshTick` tick and the leftover `🏘️` debug prints.

### Mutation call sites to update (all currently call `bumpCommunityRefresh(ref)`)
- `tier_editor_screen.dart` — `_save` (create/update) and `_delete`
- `create_community_screen.dart` — `_submit`
- `roster_screen.dart` — `_MemberEditSheet._save` / `_remove`, and `_invite`
- pull-to-refresh / retry in `community_hub_screen.dart` + `my_communities_screen.dart`

## Acceptance
- Add a tier → it appears immediately (no restart). Log shows
  `getTiers refetched N+1` right after the create.
- Delete a tier → it disappears immediately.
- Same for create community, add/remove member.
- Remove the temporary `🏘️` debug prints once confirmed.
