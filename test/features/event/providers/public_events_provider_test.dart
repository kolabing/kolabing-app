import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/models/public_event.dart';
import 'package:kolabing_app/features/event/providers/event_provider.dart';
import 'package:kolabing_app/features/event/providers/public_events_provider.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(EventService service) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthedNotifier(_attendee('a-1'))),
        eventServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    container
      ..read(authProvider)
      ..read(publicEventsProvider);
    return container;
  }

  test('loads the public-events feed for an authenticated attendee', () async {
    final service = _ScriptedEventService(
      page: _pageOf(<String>['event-1', 'event-2']),
    );
    final container = containerWith(service);

    // Let the build()-time auto-load microtask settle, then force a reload so
    // the result is deterministic regardless of microtask ordering.
    await Future<void>.delayed(Duration.zero);
    await container.read(publicEventsProvider.notifier).refresh();

    final state = container.read(publicEventsProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.events.map((e) => e.id), <String>['event-1', 'event-2']);
    expect(state.totalCount, 2);
  });

  test(
    'markGoing optimistically bumps the going-count for one event',
    () async {
      final service = _ScriptedEventService(page: _pageOf(<String>['event-1']));
      final container = containerWith(service);
      await Future<void>.delayed(Duration.zero);
      await container.read(publicEventsProvider.notifier).refresh();

      final before = container
          .read(publicEventsProvider)
          .events
          .first
          .goingCount;
      container.read(publicEventsProvider.notifier).markGoing('event-1');
      final after = container
          .read(publicEventsProvider)
          .events
          .first
          .goingCount;

      expect(after, before + 1);
    },
  );

  test('surfaces an error when the feed fails to load', () async {
    final service = _ScriptedEventService(error: Exception('boom'));
    final container = containerWith(service);

    await Future<void>.delayed(Duration.zero);
    await container.read(publicEventsProvider.notifier).refresh();

    final state = container.read(publicEventsProvider);
    expect(state.events, isEmpty);
    expect(state.error, isNotNull);
  });
}

UserModel _attendee(String id) =>
    UserModel(id: id, email: '$id@example.com', userType: UserType.attendee);

PublicEvent _event(String id) => PublicEvent(
  id: id,
  name: 'Event $id',
  date: DateTime.parse('2026-07-01T18:00:00Z'),
  visibility: EventVisibility.public,
  goingCount: 5,
  community: PublicEventCommunity(id: 'c-$id', name: 'Community $id'),
);

PublicEventsPage _pageOf(List<String> ids) => PublicEventsPage(
  events: ids.map(_event).toList(),
  currentPage: 1,
  totalPages: 1,
  totalCount: ids.length,
  perPage: 15,
);

class _AuthedNotifier extends AuthNotifier {
  _AuthedNotifier(this._user);

  final UserModel _user;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: _user,
    token: 'token-${_user.id}',
  );
}

class _ScriptedEventService extends EventService {
  _ScriptedEventService({this.page, this.error})
    : super(authService: AuthService());

  final PublicEventsPage? page;
  final Object? error;

  @override
  Future<PublicEventsPage> getDiscovery({
    int page = 1,
    int perPage = 15,
  }) async {
    if (error != null) throw error!;
    return this.page!;
  }
}
