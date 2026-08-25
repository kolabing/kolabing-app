import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/qr_payload.dart';
import 'package:kolabing_app/features/gamification/screens/challenge_verify_qr_screen.dart';

/// The verification QR is written by one half of the app and read by the other.
/// If the URL shape and the parser ever drift apart, the loop breaks silently:
/// the code renders fine and simply refuses to be recognised. These tests pin
/// the two halves together.
void main() {
  test('a generated verify QR parses back to the same completion id', () {
    final payload = QrPayload.parse(buildVerifyQrData('cmp-123'));

    expect(payload, isA<QrVerifyCompletion>());
    expect((payload as QrVerifyCompletion).completionId, 'cmp-123');
  });

  test('a UUID completion id survives the round-trip', () {
    const id = '9f1c2b7e-4d3a-4c1f-9a2b-7e4d3a4c1f9a';

    final payload = QrPayload.parse(buildVerifyQrData(id));

    expect((payload as QrVerifyCompletion).completionId, id);
  });

  test('the generated link is an https URL on the share host', () {
    final uri = Uri.parse(buildVerifyQrData('cmp-1'));

    expect(uri.scheme, 'https');
    expect(uri.host, isNotEmpty);
    expect(uri.pathSegments, ['qr', 'verify', 'cmp-1']);
  });

  test('a verify link is never mistaken for a peer profile link', () {
    expect(
      QrPayload.parse(buildVerifyQrData('cmp-1')),
      isNot(isA<QrPeerProfile>()),
    );
  });
}
