import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/models/attendee_profile_detail.dart';
import 'package:kolabing_app/features/gamification/providers/attendee_profile_provider.dart';
import 'package:kolabing_app/features/gamification/services/attendee_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('attendeeProfileDetailProvider', () {
    test('fetches the profile for the requested id', () async {
      final service = _FakeAttendeeProfileService(
        profile: _detail(name: 'Ada'),
      );
      final container = ProviderContainer(
        overrides: [
          attendeeProfileServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        attendeeProfileDetailProvider('p1').future,
      );

      expect(result.identity.name, 'Ada');
      expect(service.requestedProfileIds, <String>['p1']);
    });
  });

  group('eventsAttendedProvider', () {
    test('loadFirstPage populates events and pagination metadata', () async {
      final service = _FakeAttendeeProfileService(
        pages: <AttendedEventsPage>[
          _page(
            ids: <String>['e1', 'e2'],
            currentPage: 1,
            lastPage: 2,
            total: 3,
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          attendeeProfileServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      await container.read(eventsAttendedProvider.notifier).loadFirstPage();

      final state = container.read(eventsAttendedProvider);
      expect(state.isLoading, isFalse);
      expect(state.events.map((e) => e.eventId), <String>['e1', 'e2']);
      expect(state.currentPage, 1);
      expect(state.lastPage, 2);
      expect(state.total, 3);
      expect(state.hasMore, isTrue);
    });

    test('loadMore appends the next page and stops at the last page', () async {
      final service = _FakeAttendeeProfileService(
        pages: <AttendedEventsPage>[
          _page(
            ids: <String>['e1', 'e2'],
            currentPage: 1,
            lastPage: 2,
            total: 3,
          ),
          _page(ids: <String>['e3'], currentPage: 2, lastPage: 2, total: 3),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          attendeeProfileServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(eventsAttendedProvider.notifier);
      await notifier.loadFirstPage();
      await notifier.loadMore();

      final state = container.read(eventsAttendedProvider);
      expect(state.events.map((e) => e.eventId), <String>['e1', 'e2', 'e3']);
      expect(state.currentPage, 2);
      expect(state.hasMore, isFalse);

      // No more pages — loadMore is a no-op and does not hit the service again.
      await notifier.loadMore();
      expect(service.eventsCallCount, 2);
    });

    test('surfaces an error from the service on first page', () async {
      final service = _FakeAttendeeProfileService(throwOnEvents: true);
      final container = ProviderContainer(
        overrides: [
          attendeeProfileServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      await container.read(eventsAttendedProvider.notifier).loadFirstPage();

      final state = container.read(eventsAttendedProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.events, isEmpty);
    });
  });
}

AttendeeProfileDetail _detail({required String name}) => AttendeeProfileDetail(
  identity: AttendeeIdentity(id: 'p1', name: name),
  gamification: const AttendeeGamification(points: 0),
  communities: const <AttendeeCommunity>[],
  eventsAttended: const AttendeeEventsAttended(),
);

AttendedEventsPage _page({
  required List<String> ids,
  required int currentPage,
  required int lastPage,
  required int total,
}) => AttendedEventsPage(
  events: ids
      .map((id) => AttendedEvent(eventId: id, eventName: 'Event $id'))
      .toList(),
  currentPage: currentPage,
  lastPage: lastPage,
  perPage: 20,
  total: total,
);

class _FakeAttendeeProfileService extends AttendeeProfileService {
  _FakeAttendeeProfileService({
    AttendeeProfileDetail? profile,
    List<AttendedEventsPage>? pages,
    this.throwOnEvents = false,
  }) : _profile = profile,
       _pages = pages ?? const <AttendedEventsPage>[],
       super(authService: AuthService());

  final AttendeeProfileDetail? _profile;
  final List<AttendedEventsPage> _pages;
  final bool throwOnEvents;

  final List<String> requestedProfileIds = <String>[];
  int eventsCallCount = 0;

  @override
  Future<AttendeeProfileDetail> getAttendeeProfile(String profileId) async {
    requestedProfileIds.add(profileId);
    final profile = _profile;
    if (profile == null) {
      throw const AttendeeProfileException('no profile');
    }
    return profile;
  }

  @override
  Future<AttendedEventsPage> getMyEventsAttended({
    int page = 1,
    int perPage = 20,
  }) async {
    if (throwOnEvents) {
      throw const AttendeeProfileException('boom');
    }
    final result =
        _pages[eventsCallCount < _pages.length
            ? eventsCallCount
            : _pages.length - 1];
    eventsCallCount += 1;
    return result;
  }
}
