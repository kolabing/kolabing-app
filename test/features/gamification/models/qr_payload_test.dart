import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/qr_payload.dart';

void main() {
  group('QrPayload.parse — peer profile', () {
    test('recognises a peer URL on the prod share host', () {
      final result = QrPayload.parse('https://kolabing.com/u/abc-123');

      expect(result, isA<QrPeerProfile>());
      expect((result as QrPeerProfile).profileRef, 'abc-123');
    });

    test('recognises a peer URL on the dev share host', () {
      // The parser must key off the path, never the host: dev and prod builds
      // emit different hosts and matching on the host breaks dev entirely.
      final result = QrPayload.parse(
        'https://kolabing-v2-development-uhzrzd.laravel.cloud/u/9f1c',
      );

      expect(result, isA<QrPeerProfile>());
      expect((result as QrPeerProfile).profileRef, '9f1c');
    });

    test('recognises a peer URL on an unknown host', () {
      final result = QrPayload.parse('https://example.test/u/handle');

      expect(result, isA<QrPeerProfile>());
      expect((result as QrPeerProfile).profileRef, 'handle');
    });

    test('tolerates a trailing slash and a query string', () {
      final trailing = QrPayload.parse('https://kolabing.com/u/abc/');
      final query = QrPayload.parse('https://kolabing.com/u/abc?ref=qr');

      expect((trailing as QrPeerProfile).profileRef, 'abc');
      expect((query as QrPeerProfile).profileRef, 'abc');
    });

    test('tolerates an uppercase path segment', () {
      final result = QrPayload.parse('https://kolabing.com/U/abc');

      expect(result, isA<QrPeerProfile>());
    });
  });

  group('QrPayload.parse — verify completion', () {
    test('recognises a verify URL', () {
      final result = QrPayload.parse(
        'https://kolabing.com/qr/verify/completion-77',
      );

      expect(result, isA<QrVerifyCompletion>());
      expect((result as QrVerifyCompletion).completionId, 'completion-77');
    });

    test('does not confuse a verify URL with a peer URL', () {
      expect(
        QrPayload.parse('https://kolabing.com/qr/verify/1'),
        isA<QrVerifyCompletion>(),
      );
    });

    test('rejects a verify URL with a missing id', () {
      expect(
        QrPayload.parse('https://kolabing.com/qr/verify'),
        isA<QrUnknown>(),
      );
    });
  });

  group('QrPayload.parse — check-in token', () {
    test('recognises an opaque token', () {
      final result = QrPayload.parse('7f3ac91be4d2408fa1c65b0e9d7a2f31');

      expect(result, isA<QrCheckinToken>());
      expect(
        (result as QrCheckinToken).token,
        '7f3ac91be4d2408fa1c65b0e9d7a2f31',
      );
    });

    test('recognises a 64-char token', () {
      final token = 'a' * 64;

      expect(QrPayload.parse(token), isA<QrCheckinToken>());
    });

    test('accepts base64url characters', () {
      expect(QrPayload.parse('abc-DEF_123456789xyz'), isA<QrCheckinToken>());
    });

    test('trims surrounding whitespace', () {
      final result = QrPayload.parse('  7f3ac91be4d2408fa1c65b0e9d7a2f31  ');

      expect(
        (result as QrCheckinToken).token,
        '7f3ac91be4d2408fa1c65b0e9d7a2f31',
      );
    });
  });

  group('QrPayload.parse — unknown', () {
    test('rejects an empty string', () {
      expect(QrPayload.parse(''), isA<QrUnknown>());
      expect(QrPayload.parse('   '), isA<QrUnknown>());
    });

    test('rejects a token that is too short to be a check-in token', () {
      // The old scanner accepted anything >= 10 chars and POSTed it blindly.
      expect(QrPayload.parse('short'), isA<QrUnknown>());
    });

    test('rejects free text with spaces', () {
      expect(QrPayload.parse('join us at the pub tonight'), isA<QrUnknown>());
    });

    test('rejects an unrelated https URL', () {
      expect(
        QrPayload.parse('https://kolabing.com/events/42'),
        isA<QrUnknown>(),
      );
    });

    test('rejects a non-http URI scheme', () {
      expect(QrPayload.parse('mailto:hi@kolabing.com'), isA<QrUnknown>());
    });

    test('rejects a wifi-style QR payload', () {
      expect(QrPayload.parse('WIFI:S:Cafe;T:WPA;P:secret;;'), isA<QrUnknown>());
    });
  });
}
