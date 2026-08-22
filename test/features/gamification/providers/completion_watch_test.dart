import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/providers/challenge_provider.dart';
import 'package:kolabing_app/features/gamification/providers/completion_watch_provider.dart';
import 'package:kolabing_app/features/gamification/services/challenge_service.dart';

String _listBody(String status, {int points = 0, String id = 'cmp-1'}) =>
    '''
{"success": true, "data": {
  "completions": [{
    "id": "$id",
    "event_id": "evt-1",
    "challenger_profile_id": "me",
    "verifier_profile_id": "them",
    "status": "$status",
    "points_earned": $points,
    "created_at": "2026-08-22T18:00:00Z",
    "challenge_name": "Meet three new people"
  }],
  "pagination": {"current_page": 1, "total_pages": 1, "total_count": 1, "per_page": 20}
}}''';

/// A container whose challenge service replays [bodies] one per request, then
/// keeps returning the last one.
ProviderContainer _container(List<String> bodies) {
  var call = 0;
  final client = MockClient((request) async {
    final body = bodies[call < bodies.length ? call : bodies.length - 1];
    call++;
    return http.Response(body, 200);
  });

  return ProviderContainer(
    overrides: [
      challengeServiceProvider.overrideWithValue(
        ChallengeService(
          authService: AuthService(
            secureStorage: const FlutterSecureStorage(),
            httpClient: client,
          ),
          httpClient: client,
        ),
      ),
      // Real timings would make this test take minutes.
      completionWatchConfigProvider.overrideWithValue(
        const CompletionWatchConfig(
          interval: Duration(milliseconds: 5),
          timeout: Duration(milliseconds: 200),
        ),
      ),
    ],
  );
}

/// Polls the container until [test] passes or the budget runs out, so the test
/// does not depend on exactly how many poll cycles have elapsed.
Future<CompletionWatchState> _settle(
  ProviderContainer container,
  String id,
  bool Function(CompletionWatchState) test,
) async {
  for (var i = 0; i < 200; i++) {
    final state = container.read(completionWatchProvider(id));
    if (test(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return container.read(completionWatchProvider(id));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  test(
    'reports verified once the verifier confirms, with the awarded XP',
    () async {
      final container = _container([
        _listBody('pending'),
        _listBody('pending'),
        _listBody('verified', points: 15),
      ]);
      addTearDown(container.dispose);

      // Subscribe so the notifier stays alive across polls.
      container.listen(
        completionWatchProvider('cmp-1'),
        (_, _) {},
        fireImmediately: true,
      );

      final state = await _settle(container, 'cmp-1', (s) => s.isVerified);

      expect(state.isVerified, isTrue);
      expect(state.completion?.pointsEarned, 15);
      expect(state.isSettled, isTrue);
    },
  );

  test('reports rejected when the verifier turns it down', () async {
    final container = _container([_listBody('pending'), _listBody('rejected')]);
    addTearDown(container.dispose);
    container.listen(
      completionWatchProvider('cmp-1'),
      (_, _) {},
      fireImmediately: true,
    );

    final state = await _settle(container, 'cmp-1', (s) => s.isRejected);

    expect(state.isRejected, isTrue);
    expect(state.isVerified, isFalse);
  });

  test('times out while it stays pending, and stops polling', () async {
    final container = _container([_listBody('pending')]);
    addTearDown(container.dispose);
    container.listen(
      completionWatchProvider('cmp-1'),
      (_, _) {},
      fireImmediately: true,
    );

    final state = await _settle(container, 'cmp-1', (s) => s.timedOut);

    expect(state.timedOut, isTrue);
    expect(state.polling, isFalse);
    // A timeout is not a failure: the completion is still pending server-side,
    // which is what lets the screen offer "keep waiting".
    expect(state.isSettled, isFalse);
    expect(state.completion?.isPending, isTrue);
  });

  test('ignores completions that are not the one being watched', () async {
    final container = _container([
      _listBody('verified', points: 30, id: 'someone-else'),
    ]);
    addTearDown(container.dispose);
    container.listen(
      completionWatchProvider('cmp-1'),
      (_, _) {},
      fireImmediately: true,
    );

    final state = await _settle(container, 'cmp-1', (s) => s.timedOut);

    expect(state.isVerified, isFalse);
    expect(state.completion, isNull);
    expect(state.timedOut, isTrue);
  });

  test('keeps polling through a transient server error', () async {
    var call = 0;
    final client = MockClient((request) async {
      call++;
      if (call == 1) return http.Response('{"message":"boom"}', 500);
      return http.Response(_listBody('verified', points: 5), 200);
    });

    final container = ProviderContainer(
      overrides: [
        challengeServiceProvider.overrideWithValue(
          ChallengeService(
            authService: AuthService(
              secureStorage: const FlutterSecureStorage(),
              httpClient: client,
            ),
            httpClient: client,
          ),
        ),
        completionWatchConfigProvider.overrideWithValue(
          const CompletionWatchConfig(
            interval: Duration(milliseconds: 5),
            timeout: Duration(milliseconds: 300),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      completionWatchProvider('cmp-1'),
      (_, _) {},
      fireImmediately: true,
    );

    final state = await _settle(container, 'cmp-1', (s) => s.isVerified);

    expect(state.isVerified, isTrue);
    expect(state.completion?.pointsEarned, 5);
  });
}
