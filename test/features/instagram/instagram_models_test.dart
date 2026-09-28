import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/instagram/models/instagram_models.dart';
import 'package:kolabing_app/features/instagram/models/instagram_return_link.dart';
import 'package:kolabing_app/services/deep_link_service.dart';

void main() {
  group('InstagramStatus', () {
    test('parses the GET /me/instagram contract', () {
      final status = InstagramStatus.fromJson(const <String, dynamic>{
        'connected': true,
        'username': 'realrunclub',
        'account_type': 'business',
        'profile_picture_url': 'https://cdn.example/p.jpg',
        'connected_at': '2026-09-28T10:00:00Z',
        'last_synced_at': '2026-09-28T11:00:00Z',
        'enabled': true,
      });

      expect(status.enabled, isTrue);
      expect(status.connected, isTrue);
      expect(status.username, 'realrunclub');
      expect(status.accountType, 'BUSINESS');
      expect(status.isPersonalAccount, isFalse);
      expect(status.profilePictureUrl, 'https://cdn.example/p.jpg');
      expect(status.connectedAt, DateTime.utc(2026, 9, 28, 10));
      expect(status.lastSyncedAt, DateTime.utc(2026, 9, 28, 11));
    });

    test('strips a leading @ and accepts 0/1 and "true" flags', () {
      final status = InstagramStatus.fromJson(const <String, dynamic>{
        'connected': 1,
        'enabled': 'true',
        'username': '@goodripple',
        'account_type': 'PERSONAL',
      });
      expect(status.connected, isTrue);
      expect(status.enabled, isTrue);
      expect(status.username, 'goodripple');
      expect(status.isPersonalAccount, isTrue);
    });

    test('an empty or garbage payload is disabled and not connected', () {
      final status = InstagramStatus.fromJson(const <String, dynamic>{
        'connected': 'nope',
        'username': '',
        'connected_at': 42,
      });
      expect(status.enabled, isFalse);
      expect(status.connected, isFalse);
      expect(status.username, isNull);
      expect(status.connectedAt, isNull);
    });
  });

  group('InstagramMedia', () {
    test('parses an item and picks the right preview per type', () {
      final video = InstagramMedia.fromJson(const <String, dynamic>{
        'id': 17900001,
        'media_type': 'VIDEO',
        'media_url': 'https://cdn.example/v.mp4',
        'thumbnail_url': 'https://cdn.example/v.jpg',
        'permalink': 'https://www.instagram.com/reel/abc/',
        'caption': 'Sunday run',
        'timestamp': '2026-09-20T08:00:00+0000',
        'imported': false,
      });
      expect(video.id, '17900001');
      expect(video.isVideo, isTrue);
      expect(video.previewUrl, 'https://cdn.example/v.jpg');
      expect(video.timestamp, isNotNull);

      final image = InstagramMedia.fromJson(const <String, dynamic>{
        'id': 'a',
        'media_type': 'IMAGE',
        'media_url': 'https://cdn.example/i.jpg',
        'imported': true,
      });
      expect(image.isVideo, isFalse);
      expect(image.imported, isTrue);
      expect(image.previewUrl, 'https://cdn.example/i.jpg');

      final carousel = InstagramMedia.fromJson(const <String, dynamic>{
        'id': 'c',
        'media_type': 'CAROUSEL_ALBUM',
        'media_url': 'https://cdn.example/c.jpg',
      });
      expect(carousel.isCarousel, isTrue);
    });

    test('unknown media types fall back to image', () {
      expect(
        InstagramMediaType.fromString('SOMETHING_NEW'),
        InstagramMediaType.image,
      );
      expect(InstagramMediaType.fromString(null), InstagramMediaType.image);
      expect(InstagramMediaType.fromString('REELS'), InstagramMediaType.video);
    });
  });

  group('InstagramMediaPage', () {
    test('parses {items, next_cursor}', () {
      final page = InstagramMediaPage.fromJson(const <String, dynamic>{
        'items': [
          {'id': '1', 'media_type': 'IMAGE'},
          {'id': '2', 'media_type': 'VIDEO'},
          {'media_type': 'IMAGE'}, // no id: dropped
          'garbage',
        ],
        'next_cursor': 'QVFIU',
      });
      expect(page.items.map((m) => m.id), ['1', '2']);
      expect(page.nextCursor, 'QVFIU');
      expect(page.hasMore, isTrue);
    });

    test('an empty or missing cursor is the last page', () {
      expect(
        InstagramMediaPage.fromJson(const <String, dynamic>{
          'items': <Object>[],
          'next_cursor': '',
        }).hasMore,
        isFalse,
      );
      expect(
        InstagramMediaPage.fromJson(const <String, dynamic>{
          'items': <Object>[],
        }).hasMore,
        isFalse,
      );
    });

    test('tolerates a bare list and null', () {
      expect(
        InstagramMediaPage.fromJson(const [
          {'id': 'x'},
        ]).items.single.id,
        'x',
      );
      expect(InstagramMediaPage.fromJson(null).items, isEmpty);
    });
  });

  group('InstagramImportResult', () {
    test('counts the created gallery items (bare list)', () {
      expect(
        InstagramImportResult.fromJson(const [
          {'id': 1},
          {'id': 2},
        ]).importedCount,
        2,
      );
    });

    test('reads items plus skipped/failed', () {
      final result = InstagramImportResult.fromJson(const <String, dynamic>{
        'items': [
          {'id': 1},
        ],
        'skipped': ['9'],
        'failed': 1,
      });
      expect(result.importedCount, 1);
      expect(result.skipped, 2);
    });

    test('reads an explicit imported count; garbage is zero', () {
      expect(
        InstagramImportResult.fromJson(const <String, dynamic>{
          'imported': 3,
        }).importedCount,
        3,
      );
      expect(InstagramImportResult.fromJson('ok').importedCount, 0);
    });
  });

  group('InstagramReturnLink', () {
    test('the raw custom-scheme link (host = instagram)', () {
      final ok = InstagramReturnLink.tryParse(
        Uri.parse('kolabing://instagram/connected?status=ok'),
      );
      expect(ok, isNotNull);
      expect(ok!.ok, isTrue);

      final err = InstagramReturnLink.tryParse(
        Uri.parse('kolabing://instagram/connected?status=error&reason=x'),
      );
      expect(err!.ok, isFalse);
      expect(err.reason, 'x');
    });

    test('path-only shapes a platform may forward to the router', () {
      expect(
        InstagramReturnLink.tryParse(
          Uri.parse('/instagram/connected?status=ok'),
        )?.ok,
        isTrue,
      );
      expect(
        InstagramReturnLink.tryParse(Uri.parse('/connected?status=error'))?.ok,
        isFalse,
      );
    });

    test('a missing status is a failure, not a success', () {
      expect(
        InstagramReturnLink.tryParse(
          Uri.parse('kolabing://instagram/connected'),
        )?.ok,
        isFalse,
      );
    });

    test('other links are not claimed', () {
      for (final raw in [
        'kolabing://subscription/success',
        'kolabing://reset-password?token=t&email=e',
        'https://app.kolabing.com/instagram/connected?status=ok',
        '/connected',
        '/instagram/import',
        'kolabing://instagram/other?status=ok',
      ]) {
        expect(
          InstagramReturnLink.tryParse(Uri.parse(raw)),
          isNull,
          reason: raw,
        );
      }
    });

    test('recognises a personal-account failure', () {
      expect(
        InstagramReturnLink.tryParse(
          Uri.parse(
            'kolabing://instagram/connected?status=error&reason=not_professional',
          ),
        )!.isPersonalAccountError,
        isTrue,
      );
      expect(
        const InstagramReturnLink(
          ok: false,
          reason: 'denied',
        ).isPersonalAccountError,
        isFalse,
      );
    });

    test('the Universal-Link parsers do not claim the Instagram return', () {
      final uri = Uri.parse('kolabing://instagram/connected?status=ok');
      expect(DeepLinkService.inviteCodeFrom(uri), isNull);
      expect(DeepLinkService.kolabIdFrom(uri), isNull);
    });
  });

  group('InstagramReturnBus', () {
    test(
      'drops the duplicate that arrives through the second channel',
      () async {
        var now = DateTime.utc(2026, 9, 28, 12);
        final bus = InstagramReturnBus(clock: () => now);
        final received = <InstagramReturnLink>[];
        final sub = bus.stream.listen(received.add);

        const link = InstagramReturnLink(ok: true);
        expect(bus.add(link), isTrue);
        expect(bus.add(link), isFalse); // app_links + GoRouter, same moment

        now = now.add(const Duration(seconds: 10));
        expect(bus.add(link), isTrue); // a genuinely new connect later

        await Future<void>.delayed(Duration.zero);
        expect(received, hasLength(2));
        await sub.cancel();
      },
    );

    test('a different outcome is never deduplicated', () {
      final bus = InstagramReturnBus(clock: () => DateTime.utc(2026));
      expect(bus.add(const InstagramReturnLink(ok: false)), isTrue);
      expect(bus.add(const InstagramReturnLink(ok: true)), isTrue);
    });
  });
}
