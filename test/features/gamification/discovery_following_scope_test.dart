import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/gamification/providers/discovery_provider.dart';
import 'package:kolabing_app/features/gamification/services/discovery_service.dart';

/// The Following scope on the attendee feed (#142).
///
/// What is worth testing here is not that a flag reaches a query string, but
/// what the notifier DECIDES to send: Following asks about a relationship, so
/// the place and category filters have to drop away, and the city has to
/// survive in state so switching back does not make the attendee pick it again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the service', () {
    test('sends following=1 and nothing when it is false', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
      });

      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        return http.Response(
          '{"success":true,"data":{"events":[],"pagination":'
          '{"current_page":1,"total_pages":1,"total_count":0,"per_page":10}}}',
          200,
        );
      });
      final service = DiscoveryService(
        authService: AuthService(
          secureStorage: const FlutterSecureStorage(),
          httpClient: client,
        ),
        httpClient: client,
      );

      await service.discoverEvents(following: true);
      await service.discoverEvents(cityId: 'city-1');

      expect(seen.first.queryParameters['following'], '1');
      expect(seen.first.queryParameters.containsKey('city_id'), isFalse);
      // Absent, not "0": the backend strips a falsy `following`, and sending it
      // would say something we do not mean.
      expect(seen.last.queryParameters.containsKey('following'), isFalse);
    });
  });

  group('the notifier', () {
    test(
      'Following drops the city and the type, and keeps them in state',
      () async {
        final service = _RecordingDiscoveryService();
        final container = _container(service);

        await container
            .read(discoveryProvider.notifier)
            .setCityAndDiscover('city-1', 'Barcelona');
        await container
            .read(discoveryProvider.notifier)
            .setTypeFilter(typeSlug: 'run_club', typeName: 'Run club');

        await container.read(discoveryProvider.notifier).setFollowing(true);

        final call = service.calls.last;
        expect(call.following, isTrue);
        expect(
          call.cityId,
          isNull,
          reason: 'a followed community can be anywhere',
        );
        expect(
          call.typeSlug,
          isNull,
          reason: 'you already know who you follow',
        );
        expect(call.latitude, isNull);

        // Kept, not cleared — switching back must not cost the attendee a choice.
        final state = container.read(discoveryProvider);
        expect(state.cityId, 'city-1');
        expect(state.cityName, 'Barcelona');
        expect(state.typeSlug, 'run_club');
      },
    );

    test('switching back to All restores the city scope', () async {
      final service = _RecordingDiscoveryService();
      final container = _container(service);
      final notifier = container.read(discoveryProvider.notifier);

      await notifier.setCityAndDiscover('city-1', 'Barcelona');
      await notifier.setFollowing(true);
      await notifier.setFollowing(false);

      final call = service.calls.last;
      expect(call.following, isFalse);
      expect(call.cityId, 'city-1');
    });

    test('the date filter still composes with Following', () async {
      final service = _RecordingDiscoveryService();
      final container = _container(service);
      final notifier = container.read(discoveryProvider.notifier);

      await notifier.setFollowing(true);
      await notifier.setDateRange(DiscoveryDateRange.today);

      expect(service.calls.last.following, isTrue);
      expect(service.calls.last.date, 'today');
    });

    /// The reason `canQuery` had to change: with no city ever picked, the feed
    /// would otherwise render the "choose a city" prompt over the Following
    /// scope and never call the API at all.
    test('Following queries with no city and no location', () async {
      final service = _RecordingDiscoveryService();
      final container = _container(service);

      expect(container.read(discoveryProvider).canQuery, isFalse);

      await container.read(discoveryProvider.notifier).setFollowing(true);

      expect(container.read(discoveryProvider).canQuery, isTrue);
      expect(service.calls, hasLength(1));
    });

    test('a repeated switch to the same scope does not refetch', () async {
      final service = _RecordingDiscoveryService();
      final container = _container(service);
      final notifier = container.read(discoveryProvider.notifier);

      await notifier.setFollowing(true);
      await notifier.setFollowing(true);

      expect(service.calls, hasLength(1));
    });
  });
}

ProviderContainer _container(DiscoveryService service) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(_AuthenticatedAttendee.new),
      discoveryServiceProvider.overrideWith((ref) => service),
    ],
  );
  addTearDown(container.dispose);
  container
    ..read(authProvider)
    ..read(discoveryProvider);
  return container;
}

class _AuthenticatedAttendee extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: 'attendee-1',
      email: 'attendee-1@example.com',
      userType: UserType.attendee,
    ),
    token: 'token-attendee-1',
  );
}

class _Call {
  const _Call({
    required this.following,
    required this.cityId,
    required this.typeSlug,
    required this.date,
    required this.latitude,
  });

  final bool following;
  final String? cityId;
  final String? typeSlug;
  final String? date;
  final double? latitude;
}

class _RecordingDiscoveryService extends DiscoveryService {
  _RecordingDiscoveryService() : super(authService: AuthService());

  final List<_Call> calls = <_Call>[];

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
    calls.add(
      _Call(
        following: following,
        cityId: cityId,
        typeSlug: typeSlug,
        date: date,
        latitude: latitude,
      ),
    );
    return const DiscoverEventsResponse(
      events: <Event>[],
      pagination: EventPagination(
        currentPage: 1,
        totalPages: 1,
        totalCount: 0,
        perPage: 10,
      ),
    );
  }
}
