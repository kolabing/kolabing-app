# Event Reminders + Calendar Invitations — App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Flutter app able to receive, route, and opt out of the two new
event-reminder pushes (`event_reminder_24h`, `event_reminder_1h`) that kolabing-v2 will
send 24 hours and 1 hour before an event an attendee signed up for.

**Architecture:** Pure plumbing — no new screens and no scheduling logic in the app. The
backend owns the schedule and the calendar invitation (see the backend contract). The app
adds two enum values, deep-links both to the existing `EventDetailScreen`, and exposes one
`events_enabled` toggle. **Trap to remember:**
`NotificationSettingsNotifier._payload` is a hand-written key whitelist that does *not*
call `NotificationPreferences.toJson()`, so a new preference must be added in **both**
places or the toggle silently never reaches the server.

**Tech Stack:** Flutter, Riverpod 3 (`NotifierProvider`), GoRouter, gen-l10n (en/es/ca ARBs),
`flutter_test`.

**Scope:** App half of issue [#191](https://github.com/kolabing/kolabing-app/issues/191)
only. Design: [`2026-08-28-event-reminders-calendar-invites-design.md`](./2026-08-28-event-reminders-calendar-invites-design.md).
Backend: [`../tickets/2026-08-28-event-reminders-calendar-invites-backend.md`](../tickets/2026-08-28-event-reminders-calendar-invites-backend.md).

**Worktree:** `~/.config/superpowers/worktrees/kolabing-app/feat-event-reminders-calendar-invites`
on branch `feat/event-reminders-calendar-invites` (off `origin/master` @ `ce1da60`).
Run every command from there.

**Testing note:** this repo has 18 pre-existing failures in the full suite and
`dart format lib/` rewrites ~143 untouched files. Run **only the test files this plan
touches**, and format **only** the files you changed. Leave the full suite to CI.

---

### Task 1: Two new `NotificationType` values

**Files:**
- Modify: `lib/features/notification/models/app_notification.dart` (enum body, `fromString`, `toJson`)
- Test: `test/features/notification/models/app_notification_test.dart`

**Step 1: Write the failing test**

Append inside `main()` in `test/features/notification/models/app_notification_test.dart`:

```dart
  test('fromJson parses the event reminder types and round-trips them', () {
    const cases = <String, NotificationType>{
      'event_reminder_24h': NotificationType.eventReminder24h,
      'event_reminder_1h': NotificationType.eventReminder1h,
    };

    cases.forEach((rawType, expectedType) {
      final notification = AppNotification.fromJson(<String, dynamic>{
        'id': 'notif-$rawType',
        'type': rawType,
        'title': 'Reminder',
        'body': 'Your event is coming up',
        'is_read': false,
        'created_at': '2026-08-28T10:20:30Z',
        'target_id': 'event-1',
        'target_type': 'event',
      });

      expect(notification.type, expectedType);
      expect(notification.rawType, rawType);
      expect(expectedType.toJson(), rawType);
    });
  });
```

**Step 2: Run it to make sure it fails**

Run: `flutter test test/features/notification/models/app_notification_test.dart`
Expected: compile error — `eventReminder24h` isn't a member of `NotificationType`.

**Step 3: Implement the minimal code**

In `lib/features/notification/models/app_notification.dart`, add the two values to the
enum immediately after `collabFollowUpReminder` (line 33) so reminders sit together:

```dart
  /// Event reminder, 24 hours before an event the user signed up for
  eventReminder24h,

  /// Event reminder, 1 hour before (catch-up window means it can arrive later —
  /// copy is rendered server-side and is duration-relative, never "in 1 hour")
  eventReminder1h,
```

Add to `fromString`, after the `collab_followup_reminder` case:

```dart
      case 'event_reminder_24h':
        return NotificationType.eventReminder24h;
      case 'event_reminder_1h':
        return NotificationType.eventReminder1h;
```

Add to `toJson`, after the `collabFollowUpReminder` case:

```dart
      case NotificationType.eventReminder24h:
        return 'event_reminder_24h';
      case NotificationType.eventReminder1h:
        return 'event_reminder_1h';
```

**Step 4: Run the tests and make sure they pass**

Run: `flutter test test/features/notification/models/app_notification_test.dart`
Expected: PASS (5 tests).

Note: `toJson`'s switch is exhaustive with no `default`, so the analyzer will point at any
other `switch (NotificationType)` in the codebase that now misses a case. Fix any it finds
before committing — that is the compiler doing the audit for you.

**Step 5: Commit**

```bash
git add lib/features/notification/models/app_notification.dart \
        test/features/notification/models/app_notification_test.dart
git commit -m "feat(notifications): add event_reminder_24h and event_reminder_1h types"
```

---

### Task 2: Route both reminder types to the event detail screen

**Files:**
- Modify: `lib/features/notification/utils/notification_navigation.dart:40-50`
- Test: `test/features/notification/utils/notification_navigation_test.dart`

Background: `/event/{id}` **deeplinks already resolve** (`_isSupportedNotificationPath`,
line 96). This task covers the fallback path, for when the push carries only `type` +
`target_id` and no usable deeplink.

**Step 1: Write the failing test**

Append inside `main()`:

```dart
  test('resolveNotificationRoute routes event reminders to event detail', () {
    for (final type in const ['event_reminder_24h', 'event_reminder_1h']) {
      expect(
        resolveNotificationRoute(type: type, id: 'event-1'),
        '/event/event-1',
        reason: '$type should open the event, not the notifications list',
      );
    }
  });

  test('resolveNotificationRoute keeps an event deeplink over the type branch', () {
    expect(
      resolveNotificationRoute(
        type: 'event_reminder_1h',
        id: 'event-1',
        deeplink: 'kolabing://event/event-2',
      ),
      '/event/event-2',
    );
  });
```

**Step 2: Run it to make sure it fails**

Run: `flutter test test/features/notification/utils/notification_navigation_test.dart`
Expected: FAIL — first test gets `/notifications` (the `default` branch). The second test
should already pass; that is fine, it is a regression guard.

**Step 3: Implement the minimal code**

In `lib/features/notification/utils/notification_navigation.dart`, add a case group to the
`switch (type)` before `default:`:

```dart
    case 'event_reminder_24h':
    case 'event_reminder_1h':
      return KolabingRoutes.eventDetail.replaceFirst(':id', normalizedId);
```

`KolabingRoutes.eventDetail` is `'/event/:id'` (`lib/config/routes/routes.dart:363`).

**Step 4: Run the tests and make sure they pass**

Run: `flutter test test/features/notification/utils/notification_navigation_test.dart`
Expected: PASS (11 tests).

**Step 5: Commit**

```bash
git add lib/features/notification/utils/notification_navigation.dart \
        test/features/notification/utils/notification_navigation_test.dart
git commit -m "feat(notifications): deep-link event reminders to event detail"
```

---

### Task 3: `eventsEnabled` on `NotificationPreferences`

**Files:**
- Modify: `lib/features/business/models/notification_preferences.dart`
- Test: Create `test/features/business/models/notification_preferences_test.dart`

**Step 1: Write the failing test**

Create `test/features/business/models/notification_preferences_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';

void main() {
  test('eventsEnabled defaults on when the backend omits the key', () {
    final prefs = NotificationPreferences.fromJson(<String, dynamic>{});

    // Opt-out semantics: a missing row/key must never mute an existing user.
    expect(prefs.eventsEnabled, isTrue);
  });

  test('eventsEnabled round-trips through fromJson and toJson', () {
    final prefs = NotificationPreferences.fromJson(<String, dynamic>{
      'events_enabled': false,
    });

    expect(prefs.eventsEnabled, isFalse);
    expect(prefs.toJson()['events_enabled'], isFalse);
  });

  test('copyWith can flip eventsEnabled without touching the rest', () {
    const prefs = NotificationPreferences();
    final updated = prefs.copyWith(eventsEnabled: false);

    expect(updated.eventsEnabled, isFalse);
    expect(updated.messagesEnabled, prefs.messagesEnabled);
    expect(updated.marketingEnabled, prefs.marketingEnabled);
  });
}
```

**Step 2: Run it to make sure it fails**

Run: `flutter test test/features/business/models/notification_preferences_test.dart`
Expected: compile error — no `eventsEnabled` getter.

**Step 3: Implement the minimal code**

Four edits to `lib/features/business/models/notification_preferences.dart`, mirroring
`rewardsEnabled` exactly:

1. Constructor (after `rewardsEnabled`): `this.eventsEnabled = true,`
2. `fromJson` (after `rewardsEnabled`): `eventsEnabled: json['events_enabled'] as bool? ?? true,`
3. Field (after `final bool rewardsEnabled;`): `final bool eventsEnabled;`
4. `toJson` (after `'rewards_enabled'`): `'events_enabled': eventsEnabled,`
5. `copyWith` — add `bool? eventsEnabled,` to the parameter list and
   `eventsEnabled: eventsEnabled ?? this.eventsEnabled,` to the returned constructor.

Default is `true` on purpose: opt-out, not opt-in, so the filter landing in kolabing-v2
cannot silence users who never opened Settings.

**Step 4: Run the tests and make sure they pass**

Run: `flutter test test/features/business/models/notification_preferences_test.dart`
Expected: PASS (3 tests).

**Step 5: Commit**

```bash
git add lib/features/business/models/notification_preferences.dart \
        test/features/business/models/notification_preferences_test.dart
git commit -m "feat(settings): add events_enabled to NotificationPreferences"
```

---

### Task 4: Make the toggle actually reach the server (the trap)

**Files:**
- Modify: `lib/features/settings/providers/notification_settings_provider.dart:44-53`
- Test: Create `test/features/settings/providers/notification_settings_provider_test.dart`

`setPreference` does **not** send `NotificationPreferences.toJson()`. It sends a
hand-written `_payload` whitelist. Task 3 alone therefore leaves a dead switch: the UI
flips, and `events_enabled` is never PUT. This task closes that, and the test exists
specifically to stop it regressing the next time someone adds a preference.

**Step 1: Write the failing test**

Create `test/features/settings/providers/notification_settings_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';
import 'package:kolabing_app/features/settings/providers/notification_settings_provider.dart';

class _RecordingProfileService extends ProfileService {
  Map<String, bool>? lastPayload;

  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    lastPayload = prefs;
    return NotificationPreferences.fromJson(
      prefs.map((k, v) => MapEntry<String, dynamic>(k, v)),
    );
  }
}

void main() {
  test('setPreference PUTs events_enabled', () async {
    final service = _RecordingProfileService();
    final container = ProviderContainer(
      overrides: [profileServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(notificationSettingsProvider.notifier);
    await notifier.setPreference(
      const NotificationPreferences().copyWith(eventsEnabled: false),
    );

    expect(
      service.lastPayload,
      containsPair('events_enabled', false),
      reason: '_payload is a hand-written whitelist — a new pref must be added there too',
    );
  });
}
```

**Step 2: Run it to make sure it fails**

Run: `flutter test test/features/settings/providers/notification_settings_provider_test.dart`
Expected: FAIL — `lastPayload` has no `events_enabled` key.

**Step 3: Implement the minimal code**

Add one line to `_payload` in
`lib/features/settings/providers/notification_settings_provider.dart`, after
`'marketing_enabled'`:

```dart
    'events_enabled': p.eventsEnabled,
```

**Step 4: Run the tests and make sure they pass**

Run: `flutter test test/features/settings/providers/notification_settings_provider_test.dart`
Expected: PASS (1 test).

If `_RecordingProfileService` fails to construct, `ProfileService`'s constructor is
`ProfileService({AuthService? authService, http.Client? httpClient})` — both optional, so a
bare `super()` is fine and no explicit constructor is needed.

**Step 5: Commit**

```bash
git add lib/features/settings/providers/notification_settings_provider.dart \
        test/features/settings/providers/notification_settings_provider_test.dart
git commit -m "fix(settings): send events_enabled in the notification prefs payload"
```

---

### Task 5: i18n for the toggle — all three ARBs

**Files:**
- Modify: `lib/l10n/app_en.arb` (near `notifSettingsCollaborations`, ~line 7016)
- Modify: `lib/l10n/app_es.arb` (~line 1658)
- Modify: `lib/l10n/app_ca.arb` (~line 1658)
- Generated: `lib/l10n/app_localizations*.dart` (via `flutter gen-l10n`, commit the output)

CLAUDE.md: a widget is not done until its strings exist in all three ARBs. `es` is
**European/Castilian** Spanish; `ca` is Catalan.

**Step 1: Add the English keys**

In `lib/l10n/app_en.arb`, directly after the `@notifSettingsCollaborationsSubtitle` block:

```json
  "notifSettingsEvents": "Event reminders",
  "@notifSettingsEvents": {
    "description": "Notification settings: event reminders toggle"
  },
  "notifSettingsEventsSubtitle": "A day before and an hour before events you're going to",
  "@notifSettingsEventsSubtitle": {
    "description": "Notification settings: event reminders subtitle"
  },
```

**Step 2: Add the Spanish keys**

In `lib/l10n/app_es.arb`, after `notifSettingsCollaborationsSubtitle`:

```json
  "notifSettingsEvents": "Recordatorios de eventos",
  "notifSettingsEventsSubtitle": "Un día antes y una hora antes de los eventos a los que vas",
```

**Step 3: Add the Catalan keys**

In `lib/l10n/app_ca.arb`, after `notifSettingsCollaborationsSubtitle`:

```json
  "notifSettingsEvents": "Recordatoris d'esdeveniments",
  "notifSettingsEventsSubtitle": "Un dia abans i una hora abans dels esdeveniments on vas",
```

**Step 4: Regenerate and verify**

Run: `flutter gen-l10n`
Expected: no errors, no "missing translation" warnings for the two new keys.

Verify all three landed:

Run: `grep -c "notifSettingsEvents" lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_es.dart lib/l10n/app_localizations_ca.dart`
Expected: a non-zero count for each of the three files.

**Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "i18n(settings): event reminder toggle strings in en/es/ca"
```

---

### Task 6: The toggle in the settings screen

**Files:**
- Modify: `lib/features/settings/screens/notification_settings_screen.dart:98-104` (inside `_Toggles`)
- Test: Create `test/features/settings/screens/notification_settings_screen_test.dart`

**Step 1: Write the failing test**

`_Toggles` is private, so drive the whole screen with the provider overridden. Create
`test/features/settings/screens/notification_settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';
import 'package:kolabing_app/features/settings/screens/notification_settings_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

class _StubProfileService extends ProfileService {
  NotificationPreferences saved = const NotificationPreferences();

  @override
  Future<NotificationPreferences> getNotificationPreferences() async => saved;

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    saved = saved.copyWith(eventsEnabled: prefs['events_enabled']);
    return saved;
  }
}

void main() {
  testWidgets('event reminders toggle renders and writes through', (tester) async {
    final service = _StubProfileService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggle = find.widgetWithText(SwitchListTile, 'Event reminders');
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(service.saved.eventsEnabled, isFalse);
  });
}
```

**Step 2: Run it to make sure it fails**

Run: `flutter test test/features/settings/screens/notification_settings_screen_test.dart`
Expected: FAIL — `findsOneWidget` finds nothing; no such tile exists yet.

**Step 3: Implement the minimal code**

In `_Toggles.build`, insert between the collaborations tile and the marketing tile — after
the event reminders belong with the transactional toggles, above "Tips & updates":

```dart
        SwitchListTile(
          value: prefs.eventsEnabled,
          title: Text(l10n.notifSettingsEvents),
          subtitle: Text(l10n.notifSettingsEventsSubtitle),
          onChanged: (v) => _save(context, ref, prefs.copyWith(eventsEnabled: v)),
        ),
```

**Step 4: Run the tests and make sure they pass**

Run: `flutter test test/features/settings/screens/notification_settings_screen_test.dart`
Expected: PASS (1 test).

If `pumpAndSettle` times out, the notifier's `Future.microtask(reload)` may still be
pending — replace it with `await tester.pump(); await tester.pump(Duration.zero);` before
`pumpAndSettle()`.

**Step 5: Commit**

```bash
git add lib/features/settings/screens/notification_settings_screen.dart \
        test/features/settings/screens/notification_settings_screen_test.dart
git commit -m "feat(settings): event reminders toggle"
```

---

### Task 7: Verify, format, and open the PR

**Step 1: Analyze**

Run: `flutter analyze lib/features/notification lib/features/settings lib/features/business/models`
Expected: `No issues found!` — and specifically no "missing case" warnings from the two new
enum values.

**Step 2: Format only what changed**

`dart format lib/` rewrites ~143 untouched files in this repo. Format the touched files
only:

```bash
git diff --name-only origin/master...HEAD -- '*.dart' | xargs dart format
```

**Step 3: Run every test file this plan touched**

```bash
flutter test \
  test/features/notification/ \
  test/features/business/models/notification_preferences_test.dart \
  test/features/settings/
```
Expected: all pass. Do **not** run the full suite locally — 18 failures pre-date this work.

**Step 4: Commit any formatting churn**

```bash
git add -A && git commit -m "chore: dart format touched files" || echo "nothing to format"
```

**Step 5: Open the PR**

Use `.github/pull_request_template.md` and fill **every** section. Specifics for this PR:

- **Screenshots:** required — the Settings ▸ Notifications list with the new "Event
  reminders" toggle, iOS and Android. This is a UI change; the template's "no UI change"
  box must stay unticked.
- **How to test:** affected role is Community Member / attendee. Steps: sign in as an
  attendee → Settings ▸ Notifications → confirm "Event reminders" appears between
  "Collaboration updates" and "Tips & updates" → toggle it off → confirm the PUT carries
  `events_enabled: false` (check the network log) → reopen the screen and confirm it
  persisted.
- **Production needs:** state plainly that the app half is inert until kolabing-v2 ships
  the backend contract — no reminder can arrive until `events:send-reminders` is
  registered, and **no calendar invitation can be sent until a production mailer is
  wired** (`POSTMARK_API_KEY` / `MAIL_MAILER=postmark` are unset).
- Link `Closes #191` only if you consider the app half to close the issue; otherwise use
  `Refs #191` and leave the issue open for the backend work.

```bash
gh pr create --repo kolabing/kolabing-app --base master \
  --title "Event reminders: notification types, deep link, and opt-out toggle" \
  --body-file <filled-in template>
```

---

## Not in this plan

The backend half — the sweep, the ICS builder, the lifecycle mails, and the global
`NotificationPreference` filter — lives in kolabing-v2 and is specified in
[`../tickets/2026-08-28-event-reminders-calendar-invites-backend.md`](../tickets/2026-08-28-event-reminders-calendar-invites-backend.md).
Nothing in this plan can be verified end-to-end until at least §B1–B2 of that ticket ship;
until then the app changes are provably correct in isolation (tests above) and inert in
production.

An optional "Add to calendar" button on `EventDetailScreen` (via `add_2_calendar`, a native
sheet, for attendees who don't use an email calendar) was discussed and deliberately left
out — it is a separate, independent change and does not belong in this PR.

## Update `BACKLOG.md` when the app half lands

IF-40's status line says "Design approved; app + backend not started". Change it to record
what shipped and what is still blocked, per the maintenance rules — an Incomplete Feature
is only removed once it is verified working end-to-end, which needs the backend.
