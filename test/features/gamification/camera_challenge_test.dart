import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';
import 'package:kolabing_app/features/gamification/models/challenge.dart';
import 'package:kolabing_app/features/gamification/services/challenge_photo_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed JSON for a challenge as the CURRENT backend sends it — i.e. with none
/// of #183's fields. Every assertion about defaults reads off this.
Map<String, dynamic> legacyChallengeJson() => {
  'id': 'ch-1',
  'name': 'Swap a recommendation',
  'description': 'Tell each other one thing worth trying.',
  'difficulty': 'medium',
  'points': 15,
  'is_system': true,
  'created_at': '2026-08-01T10:00:00.000Z',
  'updated_at': '2026-08-01T10:00:00.000Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('capture type degrades rather than breaking', () {
    test('a challenge from a backend without #183 needs no camera', () {
      final challenge = Challenge.fromJson(legacyChallengeJson());

      expect(challenge.captureType, ChallengeCaptureType.none);
      expect(challenge.participation, ChallengeParticipation.pair);
      expect(challenge.needsCamera, isFalse);
      expect(challenge.isSolo, isFalse);
    });

    test('a capture_type this build has never heard of falls back to none', () {
      // The point of the fallback: a challenge authored against a newer backend
      // still WORKS here, it just works without a camera. Never a dead end.
      final challenge = Challenge.fromJson({
        ...legacyChallengeJson(),
        'capture_type': 'hologram',
        'participation': 'quartet',
      });

      expect(challenge.captureType, ChallengeCaptureType.none);
      expect(challenge.needsCamera, isFalse);
      // An unknown participation reads as a pair, which is how every challenge
      // behaved before the field existed.
      expect(challenge.participation, ChallengeParticipation.pair);
    });

    test('a photo challenge round-trips through JSON', () {
      final challenge = Challenge.fromJson({
        ...legacyChallengeJson(),
        'capture_type': 'photo',
        'participation': 'solo',
        'capture_hint': 'Find something yellow in the venue.',
      });

      expect(challenge.needsCamera, isTrue);
      expect(challenge.isSolo, isTrue);
      expect(challenge.captureHint, 'Find something yellow in the venue.');

      final round = Challenge.fromJson(challenge.toJson());
      expect(round.captureType, ChallengeCaptureType.photo);
      expect(round.participation, ChallengeParticipation.solo);
      expect(round.captureHint, challenge.captureHint);
    });
  });

  group('the photo queue never stands between a person and their XP', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth_token': 'token-123',
      });
      tempDir = await Directory.systemTemp.createTemp('photo_queue_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    File writeFrame(String name) {
      final f = File('${tempDir.path}/$name')..writeAsBytesSync([1, 2, 3]);
      return f;
    }

    EventService withClient(MockClient client) => EventService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );

    /// An EventService whose uploads always fail, standing in for venue wifi.
    EventService failingUploads() => withClient(
      MockClient((_) async => http.Response('{"message":"gateway"}', 502)),
    );

    /// An EventService whose uploads always succeed.
    EventService succeedingUploads() => withClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            // The real endpoint answers with the updated event, and
            // addEventPhotos parses it — so the fake has to be a parseable
            // Event or the "success" path throws and looks like a failure.
            'data': {
              'id': 'ev-1',
              'name': 'Sunset Run',
              'date': '2026-08-27T18:00:00.000Z',
              'created_at': '2026-08-01T10:00:00.000Z',
            },
          }),
          200,
        ),
      ),
    );

    test('a frame whose file has vanished is dropped, not retried', () async {
      final frame = writeFrame('gone.jpg');
      final queue = ChallengePhotoQueue(eventService: failingUploads());

      await queue.enqueue(eventId: 'ev-1', filePath: frame.path);
      frame.deleteSync();
      await queue.drain();

      // The user was paid long ago. There is nothing left to recover, so the
      // entry goes rather than rattling around the queue forever.
      expect(await queue.pendingCount(), 0);
    });

    test('the same frame cannot be queued twice', () async {
      final frame = writeFrame('once.jpg');
      final queue = ChallengePhotoQueue(eventService: failingUploads());

      await queue.enqueue(eventId: 'ev-1', filePath: frame.path);
      await queue.enqueue(eventId: 'ev-1', filePath: frame.path);

      expect(await queue.pendingCount(), 1);
    });

    test('a failed upload is kept and retried, then given up on', () async {
      final frame = writeFrame('flaky.jpg');
      final queue = ChallengePhotoQueue(eventService: failingUploads());

      // enqueue kicks a drain of its own, which is attempt 1. Joining it and
      // then draining three more times takes the count to four — one short of
      // the ceiling.
      await queue.enqueue(eventId: 'ev-1', filePath: frame.path);
      for (var i = 0; i < 4; i++) {
        await queue.drain();
      }
      expect(
        await queue.pendingCount(),
        1,
        reason: 'a bad connection must not cost the frame before the ceiling',
      );

      await queue.drain();
      expect(
        await queue.pendingCount(),
        0,
        reason: 'after the ceiling it is abandoned silently',
      );
    });

    test('a successful upload clears the queue', () async {
      final frame = writeFrame('lands.jpg');
      final queue = ChallengePhotoQueue(eventService: succeedingUploads());

      await queue.enqueue(eventId: 'ev-1', filePath: frame.path);
      await queue.drain();

      expect(await queue.pendingCount(), 0);
    });

    test('a corrupt stored queue resets instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'challenge_photo_queue_v1': 'not json at all',
      });
      final queue = ChallengePhotoQueue(eventService: failingUploads());

      expect(await queue.pendingCount(), 0);
      await queue.drain();
    });
  });
}
