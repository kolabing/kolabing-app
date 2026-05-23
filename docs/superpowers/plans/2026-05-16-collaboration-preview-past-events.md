# Collaboration Preview + Past Events Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a business-faithful preview mode for community-owned published collaborations and embed recent past events on the shared collaboration detail screen, with working read-only event drill-in.

**Architecture:** Reuse `CommunityOfferDetailScreen` as the single business-facing source of truth. Add role-aware preview state and a dedicated embedded past-events section on that screen, then extend event detail loading so public/read-only event cards can open without relying on the owner’s editable event cache.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_test

---

### Task 1: Lock failing tests for shared detail behavior

**Files:**
- Create: `test/features/business/screens/community_offer_detail_screen_test.dart`
- Modify: `lib/features/business/screens/community_offer_detail_screen.dart`
- Modify: `lib/features/event/providers/event_provider.dart`

- [ ] **Step 1: Write the failing widget tests**

```dart
testWidgets('shows preview banner and disabled CTA for owned published community offer', (tester) async {
  final opportunity = Opportunity(
    id: 'opp-1',
    title: 'Brunch collab',
    description: 'Host our community for a brunch event.',
    businessOffer: const BusinessOffer(venue: true),
    communityDeliverables: const CommunityDeliverables(socialMediaContent: true),
    categories: const ['Food'],
    availabilityMode: AvailabilityMode.oneTime,
    availabilityStart: DateTime(2026, 6, 1),
    availabilityEnd: DateTime(2026, 6, 1),
    venueMode: VenueMode.businessVenue,
    preferredCity: 'Barcelona',
    status: OpportunityStatus.published,
    creatorProfile: const CreatorProfile(
      id: 'community-profile-1',
      userType: 'community',
      displayNameValue: 'Barcelona Creators',
    ),
    isOwn: true,
  );

  await tester.pumpWidget(_buildTestApp(
    user: const UserModel(
      id: 'user-1',
      email: 'community@example.com',
      userType: UserType.community,
      communityProfile: CommunityProfile(id: 'community-profile-1', name: 'Barcelona Creators'),
    ),
    opportunity: opportunity,
    events: const [],
  ));

  expect(find.text('You are previewing this collaboration as businesses see it'), findsOneWidget);
  final ElevatedButton button = tester.widget(find.widgetWithText(ElevatedButton, 'PREVIEW MODE'));
  expect(button.onPressed, isNull);
});

testWidgets('shows past events section with newest events first and hides it when empty', (tester) async {
  final opportunity = _testOpportunity();
  final events = [
    _testEvent(id: 'event-old', name: 'Spring Meetup', date: DateTime(2025, 4, 1)),
    _testEvent(id: 'event-new', name: 'Summer Meetup', date: DateTime(2025, 7, 1)),
  ];

  await tester.pumpWidget(_buildTestApp(
    user: _businessUser(),
    opportunity: opportunity,
    events: events,
  ));

  expect(find.text('Past events from this community'), findsOneWidget);
  expect(find.text('Summer Meetup'), findsOneWidget);
  expect(find.text('Spring Meetup'), findsOneWidget);
});
```

- [ ] **Step 2: Run the new screen test file to verify it fails**

Run: `flutter test test/features/business/screens/community_offer_detail_screen_test.dart`
Expected: FAIL because the detail screen does not yet expose preview mode UI or an embedded past-events section.

- [ ] **Step 3: Add event-provider seams needed for read-only event data overrides**

```dart
final eventServiceProvider = Provider<EventService>((ref) => EventService());

final profileEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, profileId) async {
  final service = ref.watch(eventServiceProvider);
  final result = await service.getEvents(profileId: profileId);
  return result.events;
});
```

- [ ] **Step 4: Re-run the screen test file and confirm it still fails for the intended missing UI**

Run: `flutter test test/features/business/screens/community_offer_detail_screen_test.dart`
Expected: FAIL on missing banner/section assertions, not on provider wiring errors.

### Task 2: Implement preview mode and embedded past events on the shared detail screen

**Files:**
- Modify: `lib/features/business/screens/community_offer_detail_screen.dart`
- Modify: `lib/features/auth/models/user_model.dart`
- Test: `test/features/business/screens/community_offer_detail_screen_test.dart`

- [ ] **Step 1: Implement preview-state derivation from the current community user and owned published opportunity**

```dart
bool _isPreviewMode(UserModel? user, Opportunity opportunity) {
  final communityProfileId = user?.communityProfile?.id;
  if (communityProfileId == null) return false;
  if (!user!.isCommunity) return false;
  if (opportunity.status != OpportunityStatus.published) return false;

  return opportunity.isOwn == true ||
      opportunity.creatorProfile?.id == communityProfileId;
}
```

- [ ] **Step 2: Add preview chrome and CTA state to `CommunityOfferDetailScreen`**

```dart
if (isPreviewMode) ...[
  _PreviewBanner(),
  const SizedBox(height: KolabingSpacing.md),
]
```

```dart
if (isPreviewMode) {
  return _buildDisabledBottomAction(
    label: 'PREVIEW MODE',
    icon: LucideIcons.eye,
  );
}
```

- [ ] **Step 3: Append the embedded past-events section using the creator profile ID**

```dart
if (creatorProfileId != null) ...[
  _CommunityPastEventsSection(profileId: creatorProfileId),
]
```

```dart
final sorted = [...events]..sort((a, b) => b.date.compareTo(a.date));
final visibleEvents = sorted.take(5).toList();
if (visibleEvents.isEmpty) return const SizedBox.shrink();
```

- [ ] **Step 4: Re-run the shared detail test file and make it pass**

Run: `flutter test test/features/business/screens/community_offer_detail_screen_test.dart`
Expected: PASS

### Task 3: Lock failing tests for read-only event detail opens

**Files:**
- Create: `test/features/event/screens/event_detail_screen_test.dart`
- Modify: `lib/features/event/screens/event_detail_screen.dart`
- Modify: `lib/features/event/providers/event_provider.dart`

- [ ] **Step 1: Write the failing event-detail tests**

```dart
testWidgets('loads event detail from read-only provider when event is not in owner cache', (tester) async {
  await tester.pumpWidget(_buildEventApp(
    eventId: 'event-1',
    state: const EventsState(events: []),
    readOnlyEvent: _testEvent(id: 'event-1', name: 'Public Event'),
  ));

  await tester.pumpAndSettle();

  expect(find.text('Public Event'), findsOneWidget);
  expect(find.text('DELETE EVENT'), findsNothing);
});
```

- [ ] **Step 2: Run the event-detail test file to verify it fails**

Run: `flutter test test/features/event/screens/event_detail_screen_test.dart`
Expected: FAIL because the screen currently renders `Event not found` when the event is not in `eventsProvider`.

- [ ] **Step 3: Add a dedicated read-only event-by-id provider**

```dart
final eventDetailProvider =
    FutureProvider.family<Event, String>((ref, eventId) async {
  final service = ref.watch(eventServiceProvider);
  return service.getEvent(eventId);
});
```

- [ ] **Step 4: Re-run the event-detail tests and confirm they still fail only on the missing screen behavior**

Run: `flutter test test/features/event/screens/event_detail_screen_test.dart`
Expected: FAIL on UI assertions, not provider lookup errors.

### Task 4: Implement read-only event detail and community preview entry point

**Files:**
- Modify: `lib/features/event/screens/event_detail_screen.dart`
- Modify: `lib/features/community/screens/my_opportunities_screen.dart`
- Modify: `lib/features/kolab/widgets/my_kolab_card.dart`
- Test: `test/features/event/screens/event_detail_screen_test.dart`

- [ ] **Step 1: Make `EventDetailScreen` fall back to the read-only provider**

```dart
final ownState = ref.watch(eventsProvider);
final cachedEvent = _getEvent(ownState);
final asyncReadOnlyEvent = cachedEvent == null
    ? ref.watch(eventDetailProvider(widget.eventId))
    : null;
```

```dart
final canDelete = cachedEvent != null;
if (canDelete) ...[
  OutlinedButton.icon(
    onPressed: () => _handleDelete(event),
    icon: const Icon(LucideIcons.trash2, size: 18),
    label: const Text('DELETE EVENT'),
  ),
]
```

- [ ] **Step 2: Add a `View` action to published community items**

```dart
if (kolab.status == 'published' && onView != null) {
  actions.add(
    _ActionButton(
      label: 'View',
      icon: LucideIcons.eye,
      onTap: onView!,
      primary: true,
    ),
  );
}
```

```dart
onView: kolab.id != null
    ? () => context.push('/opportunity/${kolab.id}')
    : null,
```

- [ ] **Step 3: Re-run the event-detail tests and ensure they pass**

Run: `flutter test test/features/event/screens/event_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Run both targeted test files together**

Run: `flutter test test/features/business/screens/community_offer_detail_screen_test.dart test/features/event/screens/event_detail_screen_test.dart`
Expected: PASS

### Task 5: Verify touched surfaces with analyzer

**Files:**
- Modify: `lib/features/business/screens/community_offer_detail_screen.dart`
- Modify: `lib/features/event/providers/event_provider.dart`
- Modify: `lib/features/event/screens/event_detail_screen.dart`
- Modify: `lib/features/community/screens/my_opportunities_screen.dart`
- Modify: `lib/features/kolab/widgets/my_kolab_card.dart`

- [ ] **Step 1: Run analyzer on touched files**

Run: `flutter analyze lib/features/business/screens/community_offer_detail_screen.dart lib/features/event/providers/event_provider.dart lib/features/event/screens/event_detail_screen.dart lib/features/community/screens/my_opportunities_screen.dart lib/features/kolab/widgets/my_kolab_card.dart`
Expected: 0 issues found

- [ ] **Step 2: Re-run the targeted widget tests after analyzer cleanup**

Run: `flutter test test/features/business/screens/community_offer_detail_screen_test.dart test/features/event/screens/event_detail_screen_test.dart`
Expected: PASS
