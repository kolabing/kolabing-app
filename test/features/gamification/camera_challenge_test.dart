import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/services/challenge_service.dart';
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

  group('proof_type degrades rather than breaking', () {
    test('a challenge from a backend without the column needs no camera', () {
      final challenge = Challenge.fromJson(legacyChallengeJson());

      expect(challenge.proofType, ChallengeProofType.text);
      expect(challenge.needsCamera, isFalse);
    });

    test('a proof_type this build has never heard of falls back to text', () {
      // The point of the fallback: a challenge authored against a newer backend
      // still WORKS here, it just works without a camera. Never a dead end.
      final challenge = Challenge.fromJson({
        ...legacyChallengeJson(),
        'proof_type': 'hologram',
      });

      expect(challenge.proofType, ChallengeProofType.text);
      expect(challenge.needsCamera, isFalse);
    });

    test('a photo challenge round-trips through JSON', () {
      final challenge = Challenge.fromJson({
        ...legacyChallengeJson(),
        'proof_type': 'photo',
      });

      expect(challenge.needsCamera, isTrue);

      final round = Challenge.fromJson(challenge.toJson());
      expect(round.proofType, ChallengeProofType.photo);
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

    ChallengeService withClient(MockClient client) => ChallengeService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );

    /// Uploads that always fail, standing in for venue wifi.
    ChallengeService failingUploads() => withClient(
      MockClient((_) async => http.Response('{"message":"gateway"}', 502)),
    );

    /// Uploads that always succeed.
    ChallengeService succeedingUploads() => withClient(
      MockClient(
        (_) async => http.Response(jsonEncode({'success': true}), 200),
      ),
    );

    test('a frame whose file has vanished is dropped, not retried', () async {
      final frame = writeFrame('gone.jpg');
      final queue = ChallengePhotoQueue(challengeService: failingUploads());

      await queue.enqueue(completionId: 'cc-1', filePath: frame.path);
      frame.deleteSync();
      await queue.drain();

      // The user was paid long ago. There is nothing left to recover, so the
      // entry goes rather than rattling around the queue forever.
      expect(await queue.pendingCount(), 0);
    });

    test('the same frame cannot be queued twice', () async {
      final frame = writeFrame('once.jpg');
      final queue = ChallengePhotoQueue(challengeService: failingUploads());

      await queue.enqueue(completionId: 'cc-1', filePath: frame.path);
      await queue.enqueue(completionId: 'cc-1', filePath: frame.path);

      expect(await queue.pendingCount(), 1);
    });

    test('a failed upload is kept and retried, then given up on', () async {
      final frame = writeFrame('flaky.jpg');
      final queue = ChallengePhotoQueue(challengeService: failingUploads());

      // enqueue kicks a drain of its own, which is attempt 1. Joining it and
      // then draining three more times takes the count to four — one short of
      // the ceiling.
      await queue.enqueue(completionId: 'cc-1', filePath: frame.path);
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
      final queue = ChallengePhotoQueue(challengeService: succeedingUploads());

      await queue.enqueue(completionId: 'cc-1', filePath: frame.path);
      await queue.drain();

      expect(await queue.pendingCount(), 0);
    });

    test('a corrupt stored queue resets instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'challenge_photo_queue_v1': 'not json at all',
      });
      final queue = ChallengePhotoQueue(challengeService: failingUploads());

      expect(await queue.pendingCount(), 0);
      await queue.drain();
    });
  });
}
