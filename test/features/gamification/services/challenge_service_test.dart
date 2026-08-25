import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/services/challenge_service.dart';

ChallengeService _service(http.Response Function(http.BaseRequest) respond) {
  final client = MockClient((request) async => respond(request));
  return ChallengeService(
    authService: AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: client,
    ),
    httpClient: client,
  );
}

const String _completionBody = '''
{"success": true, "data": {
  "id": "cmp-1",
  "event_id": "evt-1",
  "challenger_profile_id": "me",
  "verifier_profile_id": "them",
  "status": "pending",
  "points_earned": 0,
  "created_at": "2026-08-22T18:00:00Z",
  "challenge_name": "Meet three new people",
  "challenger_name": "Ana"
}}''';

const String _verifiedBody = '''
{"success": true, "data": {
  "id": "cmp-1",
  "event_id": "evt-1",
  "challenger_profile_id": "them",
  "verifier_profile_id": "me",
  "status": "verified",
  "points_earned": 15,
  "created_at": "2026-08-22T18:00:00Z",
  "completed_at": "2026-08-22T18:05:00Z",
  "challenge_name": "Meet three new people",
  "challenger_name": "Ana"
}}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  group('initiateChallenge', () {
    test(
      'sends the challenge, event and the scanned peer as verifier',
      () async {
        Map<String, dynamic>? sent;
        final service = _service((request) {
          sent =
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>;
          return http.Response(_completionBody, 201);
        });

        final completion = await service.initiateChallenge(
          challengeId: 'ch-1',
          eventId: 'evt-1',
          verifierProfileId: 'them',
        );

        expect(sent, {
          'challenge_id': 'ch-1',
          'event_id': 'evt-1',
          'verifier_profile_id': 'them',
        });
        expect(completion.id, 'cmp-1');
        expect(completion.isPending, isTrue);
      },
    );

    // This is the failure the peer flow hits most: the pair scanned each other
    // without both checking in. It needs its own message, so its own kind.
    test('maps 422 to bothMustCheckIn', () async {
      final service = _service(
        (_) => http.Response('{"message":"not checked in"}', 422),
      );

      await expectLater(
        service.initiateChallenge(
          challengeId: 'ch-1',
          eventId: 'evt-1',
          verifierProfileId: 'them',
        ),
        throwsA(
          isA<ChallengeException>().having(
            (e) => e.kind,
            'kind',
            ChallengeFailure.bothMustCheckIn,
          ),
        ),
      );
    });

    test('maps 409 to conflict', () async {
      final service = _service((_) => http.Response('{"message":"dup"}', 409));

      await expectLater(
        service.initiateChallenge(
          challengeId: 'ch-1',
          eventId: 'evt-1',
          verifierProfileId: 'them',
        ),
        throwsA(
          isA<ChallengeException>().having(
            (e) => e.kind,
            'kind',
            ChallengeFailure.conflict,
          ),
        ),
      );
    });
  });

  group('verifyChallenge', () {
    test(
      'returns the settled completion with the points the server awarded',
      () async {
        final service = _service((_) => http.Response(_verifiedBody, 200));

        final completion = await service.verifyChallenge('cmp-1');

        expect(completion.isVerified, isTrue);
        expect(completion.pointsEarned, 15);
        expect(completion.challengerName, 'Ana');
      },
    );

    test(
      'maps 403 to forbidden — the scanner is not the designated verifier',
      () async {
        final service = _service((_) => http.Response('{}', 403));

        await expectLater(
          service.verifyChallenge('cmp-1'),
          throwsA(
            isA<ChallengeException>().having(
              (e) => e.kind,
              'kind',
              ChallengeFailure.forbidden,
            ),
          ),
        );
      },
    );

    test('maps 409 to conflict — already settled', () async {
      final service = _service((_) => http.Response('{}', 409));

      await expectLater(
        service.verifyChallenge('cmp-1'),
        throwsA(
          isA<ChallengeException>().having(
            (e) => e.kind,
            'kind',
            ChallengeFailure.conflict,
          ),
        ),
      );
    });
  });
}
