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

  group('QrPayload.parse — canonical check-in link', () {
    // `App\Support\CheckinLink` is the backend's single source of truth for
    // what a check-in QR points at: a web URL carrying the SHORT code, chosen
    // so the QR stays version 3 and scans across a room. The web panel and
    // printed sheets emit this shape, so the app has to read it — otherwise a
    // code shown anywhere but the app itself is unreadable in the app.
    test('reads the short code out of a /checkin/{code} link', () {
      final result = QrPayload.parse('https://app.kolabing.com/checkin/K7Q2MX');

      expect(result, isA<QrCheckinToken>());
      expect((result as QrCheckinToken).token, 'K7Q2MX');
    });

    test('reads a long token off the same route', () {
      final token = 'a' * 64;

      final result = QrPayload.parse('https://app.kolabing.com/checkin/$token');

      expect((result as QrCheckinToken).token, token);
    });

    test('matches the path on any host (dev webapp, prod webapp)', () {
      for (final host in [
        'app.kolabing.com',
        'kolabing-v2-development-uhzrzd.laravel.cloud',
        'localhost:8000',
      ]) {
        expect(
          QrPayload.parse('https://$host/checkin/K7Q2MX'),
          isA<QrCheckinToken>(),
          reason: host,
        );
      }
    });

    test('tolerates a trailing slash', () {
      final result = QrPayload.parse(
        'https://app.kolabing.com/checkin/K7Q2MX/',
      );

      expect((result as QrCheckinToken).token, 'K7Q2MX');
    });

    test('a bare /checkin with no code is not a check-in', () {
      expect(
        QrPayload.parse('https://app.kolabing.com/checkin'),
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

    // The real token format is undocumented, so these shapes must not be
    // rejected: a token the parser refuses is a check-in that cannot happen.
    test('accepts a JWT-shaped token (dots)', () {
      const token =
          'eyJhbGciOiJIUzI1NiJ9.eyJldmVudCI6IjEyMyJ9.abcDEF-_123456789';

      expect(QrPayload.parse(token), isA<QrCheckinToken>());
    });

    test('accepts standard base64 padding and slashes', () {
      expect(QrPayload.parse('ab+cd/ef12345678=='), isA<QrCheckinToken>());
    });

    test('accepts a token containing a dot but no scheme', () {
      expect(
        QrPayload.parse('kolabing.checkin.abc12345'),
        isA<QrCheckinToken>(),
      );
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

    // Non-http payloads in the wild are all scheme-prefixed, which is how they
    // are told apart from an opaque token now that the charset is permissive.
    test('rejects other real-world QR schemes', () {
      for (final raw in [
        'tel:+34600123456',
        'geo:41.3874,2.1686',
        'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
        'otpauth://totp/Kolabing:me?secret=ABC123',
      ]) {
        expect(QrPayload.parse(raw), isA<QrUnknown>(), reason: raw);
      }
    });

    test('rejects a multi-line vcard payload', () {
      expect(
        QrPayload.parse('BEGIN:VCARD\nFN:Ana\nEND:VCARD'),
        isA<QrUnknown>(),
      );
    });
  });
}
