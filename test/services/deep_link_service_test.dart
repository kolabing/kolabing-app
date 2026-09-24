import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/environment.dart';
import 'package:kolabing_app/services/deep_link_service.dart';

/// Shared Kolab links (kolabing-v2 BE-NF-69). `/c/` carries both a Kolab UUID
/// and a community's invite slug; only the UUID shape is a Kolab, mirroring the
/// backend's apple-app-site-association pattern.
void main() {
  const kolabId = '01a0d39f-075b-71d5-9364-f976d764a257';

  group('a Kolab link is only followed when it really is one', () {
    test('/c/{uuid} — how the app shares a Kolab — yields the id', () {
      expect(
        DeepLinkService.kolabIdFrom(
          Uri.parse('https://app.kolabing.com/c/$kolabId'),
        ),
        kolabId,
      );
    });

    test("/kolabs/{uuid} — the web panel's copied link — yields the id", () {
      expect(
        DeepLinkService.kolabIdFrom(
          Uri.parse('https://app.kolabing.com/kolabs/$kolabId?apply=1'),
        ),
        kolabId,
      );
    });

    test('an upper-case id is normalised', () {
      expect(
        DeepLinkService.kolabIdFrom(
          Uri.parse('https://app.kolabing.com/c/${kolabId.toUpperCase()}'),
        ),
        kolabId,
      );
    });

    test('a community invite /c/{slug} is left to its web join page', () {
      for (final url in [
        'https://app.kolabing.com/c/barcelona-run-club',
        'https://app.kolabing.com/c/',
        'https://app.kolabing.com/kolabs',
        'https://app.kolabing.com/kolabs/create',
        'https://app.kolabing.com/c/$kolabId/extra',
        'https://app.kolabing.com/checkin/ABC123',
        'https://app.kolabing.com/i/K7F2QX',
      ]) {
        expect(
          DeepLinkService.kolabIdFrom(Uri.parse(url)),
          isNull,
          reason: '$url is not a Kolab link',
        );
      }
    });

    test('an invite link is still an invite, not a Kolab', () {
      final invite = Uri.parse('https://app.kolabing.com/i/k7f2qx');
      expect(DeepLinkService.inviteCodeFrom(invite), 'K7F2QX');
      expect(DeepLinkService.kolabIdFrom(invite), isNull);
    });
  });

  test('Kolabs are shared on the host the app is associated with', () {
    // `applinks:app.kolabing.com` is the only associated domain; a kolabing.com
    // link can never open the app.
    if (Environment.isProd) {
      expect(Environment.kolabShareHost, 'app.kolabing.com');
    } else {
      expect(Environment.kolabShareHost, isNotEmpty);
    }
  });
}
