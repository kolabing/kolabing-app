import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/services/checkin_service.dart';

/// Builds a service whose every request gets [respond].
CheckinService _service(http.Response Function(http.BaseRequest) respond) {
  final client = MockClient((request) async => respond(request));
  return CheckinService(
    authService: AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: client,
    ),
    httpClient: client,
  );
}

const String _okBody = '''
{"success": true, "data": {
  "id": "chk-1",
  "event_id": "evt-1",
  "profile_id": "me",
  "checked_in_at": "2026-08-22T18:00:00Z",
  "created_at": "2026-08-22T18:00:00Z",
  "event_name": "Sunset Run",
  "points_earned": 5
}}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  group('CheckinService.checkIn', () {
    test('returns the check-in, including the event and the points awarded',
        () async {
      final service = _service((_) => http.Response(_okBody, 200));

      final checkin = await service.checkIn('a' * 32);

      expect(checkin.eventId, 'evt-1');
      expect(checkin.eventName, 'Sunset Run');
      // The scanner shows this figure; it must come from the server.
      expect(checkin.pointsEarned, 5);
    });

    test('posts the scanned token in the body', () async {
      String? sentBody;
      final service = _service((request) {
        sentBody = (request as http.Request).body;
        return http.Response(_okBody, 200);
      });

      await service.checkIn('token-abcdefghij');

      expect(sentBody, contains('token-abcdefghij'));
    });

    // The failure kind — not the message — is what the UI branches on, so each
    // status has to map to the right one.
    test('maps 404 to invalidToken', () async {
      final service = _service((_) => http.Response('{"message":"nope"}', 404));

      await expectLater(
        service.checkIn('a' * 32),
        throwsA(
          isA<CheckinException>().having(
            (e) => e.kind,
            'kind',
            CheckinFailure.invalidToken,
          ),
        ),
      );
    });

    test('maps 409 to alreadyCheckedIn', () async {
      final service = _service((_) => http.Response('{"message":"dup"}', 409));

      await expectLater(
        service.checkIn('a' * 32),
        throwsA(
          isA<CheckinException>().having(
            (e) => e.kind,
            'kind',
            CheckinFailure.alreadyCheckedIn,
          ),
        ),
      );
    });

    test('maps 422 to notAcceptingCheckins and keeps the backend message',
        () async {
      final service = _service(
        (_) => http.Response('{"message":"Event has ended"}', 422),
      );

      await expectLater(
        service.checkIn('a' * 32),
        throwsA(
          isA<CheckinException>()
              .having(
                (e) => e.kind,
                'kind',
                CheckinFailure.notAcceptingCheckins,
              )
              .having((e) => e.message, 'message', 'Event has ended'),
        ),
      );
    });

    test('maps an unexpected status to unknown', () async {
      final service = _service((_) => http.Response('{"message":"boom"}', 500));

      await expectLater(
        service.checkIn('a' * 32),
        throwsA(
          isA<CheckinException>().having(
            (e) => e.kind,
            'kind',
            CheckinFailure.unknown,
          ),
        ),
      );
    });
  });

  group('CheckinService.generateQRToken', () {
    test('returns the organizer token', () async {
      final service = _service(
        (_) => http.Response(
          '{"success":true,"data":{"checkin_token":"tok-64-chars"}}',
          200,
        ),
      );

      expect(await service.generateQRToken('evt-1'), 'tok-64-chars');
    });

    test('maps 403 to unauthorized', () async {
      final service = _service((_) => http.Response('{}', 403));

      await expectLater(
        service.generateQRToken('evt-1'),
        throwsA(
          isA<CheckinException>().having(
            (e) => e.kind,
            'kind',
            CheckinFailure.unauthorized,
          ),
        ),
      );
    });
  });
}
