import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/gamification/providers/discovery_provider.dart';
import 'package:kolabing_app/features/gamification/services/discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'attendee discovery ignores stale load completion from a previous session',
    () async {
      final authNotifier = _MutableAuthNotifier(_attendeeUser('attendee-1'));
      final service = _ScriptedDiscoveryService(
        responses: <Object>[
          Completer<DiscoverEventsResponse>(),
          _responseFor(_event('event-2')),
        ],
      );

      final firstLoad =
          service.responses.first as Completer<DiscoverEventsResponse>;

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => authNotifier),
          discoveryServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      container
        ..read(authProvider)
        ..read(discoveryProvider);

      unawaited(
        container
            .read(discoveryProvider.notifier)
            .setLocationAndDiscover(41.0, 2.0),
      );
      await Future<void>.delayed(Duration.zero);

      authNotifier.signOut();
      await Future<void>.delayed(Duration.zero);

      authNotifier.signIn(_attendeeUser('attendee-2'));
      await Future<void>.delayed(Duration.zero);

      await container
          .read(discoveryProvider.notifier)
          .setLocationAndDiscover(40.0, 3.0);

      firstLoad.complete(_responseFor(_event('event-1')));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(discoveryProvider);
      expect(state.latitude, 40.0);
      expect(state.longitude, 3.0);
      expect(state.events.map((e) => e.id), <String>['event-2']);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    },
  );
}

UserModel _attendeeUser(String id) =>
    UserModel(id: id, email: '$id@example.com', userType: UserType.attendee);

Event _event(String id) => Event(
  id: id,
  name: 'Event $id',
  partner: EventPartner(name: 'Partner $id', type: PartnerType.business),
  date: DateTime.parse('2026-05-24T00:00:00Z'),
  attendeeCount: 10,
  photos: const [],
  createdAt: DateTime.parse('2026-05-24T10:00:00Z'),
  updatedAt: DateTime.parse('2026-05-24T10:00:00Z'),
);

DiscoverEventsResponse _responseFor(Event event) => DiscoverEventsResponse(
  events: <Event>[event],
  pagination: const EventPagination(
    currentPage: 1,
    totalPages: 1,
    totalCount: 1,
    perPage: 10,
  ),
);

class _MutableAuthNotifier extends AuthNotifier {
  _MutableAuthNotifier(this._initialUser);

  final UserModel _initialUser;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: _initialUser,
    token: 'token-${_initialUser.id}',
  );

  void signOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void signIn(UserModel user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: 'token-${user.id}',
    );
  }
}

class _ScriptedDiscoveryService extends DiscoveryService {
  _ScriptedDiscoveryService({required this.responses})
    : super(authService: AuthService());

  final List<Object> responses;
  int _index = 0;

  @override
  Future<DiscoverEventsResponse> discoverEvents({
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
    String? cityId,
    String? date,
    String? typeSlug,
    bool following = false,
    int page = 1,
    int limit = 10,
  }) async {
    final response =
        responses[_index < responses.length ? _index++ : responses.length - 1];
    if (response is Completer<DiscoverEventsResponse>) {
      return response.future;
    }
    if (response is DiscoverEventsResponse) {
      return response;
    }
    throw StateError('Unexpected discovery response: $response');
  }
}
