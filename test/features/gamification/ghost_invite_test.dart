import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/models/encounter.dart';
import 'package:kolabing_app/features/gamification/services/encounter_service.dart';
import 'package:kolabing_app/services/deep_link_service.dart';

/// One meeting as `EncounterResource` sends it.
Map<String, dynamic> encounterJson({
  String? otherProfileId,
  String? ghostName = 'Ana',
  int pendingPoints = 15,
}) => {
  'id': 'enc-1',
  'other_profile_id': otherProfileId,
  'other_name': otherProfileId != null ? 'Ana' : null,
  'ghost_name': ghostName,
  'community_id': 'com-1',
  'first_met_event_id': 'ev-1',
  'first_met_at': '2026-08-27T18:00:00.000Z',
  'last_met_at': '2026-08-27T18:00:00.000Z',
  'times_met': 1,
  'pending_points': pendingPoints,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  EncounterService serviceWith(MockClient client) => EncounterService(
    authService: AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: client,
    ),
    httpClient: client,
  );

  group('an invite link is only followed when it really is one', () {
    test('a /i/CODE url yields the code, upper-cased', () {
      expect(
        DeepLinkService.inviteCodeFrom(
          Uri.parse('https://app.kolabing.com/i/k7f2qx'),
        ),
        'K7F2QX',
      );
    });

    test('other paths on our host are left alone', () {
      // Check-in URLs have their own handling. A service that quietly swallows
      // every link is one nobody can reason about.
      for (final url in [
        'https://app.kolabing.com/checkin/abc',
        'https://app.kolabing.com/c/real-run-club',
        'https://app.kolabing.com/',
      ]) {
        expect(
          DeepLinkService.inviteCodeFrom(Uri.parse(url)),
          isNull,
          reason: '$url is not an invite',
        );
      }
    });

    test('a code that cannot be one of ours is refused', () {
      // Guessing would open a sheet whose only possible answer is "no".
      for (final bad in ['ab', 'has-a-dash', 'way-too-long-to-be-a-code-x']) {
        expect(
          DeepLinkService.inviteCodeFrom(
            Uri.parse('https://app.kolabing.com/i/$bad'),
          ),
          isNull,
          reason: '$bad should not be treated as a code',
        );
      }
    });
  });

  group('creating a ghost invite', () {
    test('sends the name and omits an empty contact', () async {
      late Map<String, dynamic> sent;
      final service = serviceWith(
        MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'encounter': encounterJson(),
                'claim_code': 'K7F2QX',
                'invite_url': 'https://app.kolabing.com/i/K7F2QX',
                'expires_at': '2026-09-26T18:00:00.000Z',
              },
            }),
            201,
          );
        }),
      );

      final invite = await service.createGhostInvite(
        eventId: 'ev-1',
        challengeId: 'ch-1',
        ghostName: 'Ana',
        ghostContact: '   ',
      );

      expect(sent['ghost_name'], 'Ana');
      // Asking a stranger for their number is optional, so blank must not be
      // sent as if it were an answer.
      expect(sent.containsKey('ghost_contact'), isFalse);
      expect(invite.claimCode, 'K7F2QX');
      expect(invite.inviteUrl, contains('app.kolabing.com'));
      expect(invite.encounter.pendingPoints, 15);
      expect(invite.encounter.isGhost, isTrue);
      expect(invite.encounter.displayName, 'Ana');
    });

    test(
      'the refusal reason survives as something the UI can branch on',
      () async {
        final service = serviceWith(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': 'not_checked_in',
                // ASCII on purpose: http.Response encodes a String body as
                // latin1 unless the Content-Type names a charset, so a fixture
                // with an ellipsis in it fails to construct. The message is
                // never shown anyway — the UI localizes off `error`.
                'message': 'You have to be checked in.',
              }),
              409,
            ),
          ),
        );

        try {
          await service.createGhostInvite(
            eventId: 'ev-1',
            challengeId: 'ch-1',
            ghostName: 'Ana',
          );
          fail('a 409 should have thrown');
        } on EncounterException catch (e) {
          // The app localizes off this, never off the backend's English.
          expect(e.notCheckedIn, isTrue);
          expect(e.ghostLimitReached, isFalse);
        }
      },
    );

    test(
      'the whole surface goes quiet when the backend is not deployed',
      () async {
        final service = serviceWith(
          MockClient(
            (_) async => http.Response('{"message":"Not Found"}', 404),
          ),
        );

        try {
          await service.claim('K7F2QX');
          fail('a 404 should have thrown');
        } on EncounterException catch (e) {
          expect(e.isFeatureOff, isTrue);
        }

        // Reads degrade to empty rather than to an error about a feature nobody
        // has heard of.
        expect(
          await service.getMyEncounters().catchError((_) => <Encounter>[]),
          isEmpty,
        );
      },
    );
  });

  group('claiming', () {
    test('normalises what someone typed off a screen', () async {
      late Map<String, dynamic> sent;
      final service = serviceWith(
        MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'data': encounterJson(otherProfileId: 'p-1')}),
            200,
          );
        }),
      );

      await service.claim('  k7f2qx ');

      expect(sent['claim_code'], 'K7F2QX');
    });

    test('each refusal is distinguishable', () async {
      final cases = {
        'invalid_claim_code': (EncounterException e) => e.invalidClaimCode,
        'claim_expired': (EncounterException e) => e.claimExpired,
        'claim_requires_new_account': (EncounterException e) =>
            e.claimNotNewAccount,
        'claim_self': (EncounterException e) => e.claimSelf,
      };

      for (final entry in cases.entries) {
        final service = serviceWith(
          MockClient(
            (_) async => http.Response(
              jsonEncode({'error': entry.key, 'message': 'no'}),
              409,
            ),
          ),
        );

        try {
          await service.claim('K7F2QX');
          fail('${entry.key} should have thrown');
        } on EncounterException catch (e) {
          expect(entry.value(e), isTrue, reason: 'unmatched: ${entry.key}');
        }
      }
    });

    test('an html error page does not crash the caller', () async {
      // A 500 behind a proxy answers with HTML, and decoding that used to throw
      // a FormatException out of whatever call site was unlucky enough to hit it.
      final service = serviceWith(
        MockClient((_) async => http.Response('<html>502</html>', 502)),
      );

      try {
        await service.claim('K7F2QX');
        fail('a 502 should have thrown');
      } on EncounterException catch (e) {
        expect(e.statusCode, 502);
      }
    });
  });
}
