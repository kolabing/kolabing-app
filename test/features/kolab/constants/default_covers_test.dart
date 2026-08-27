import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/kolab/constants/default_covers.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';

void main() {
  group('pickDefaultCoverPathFor', () {
    test('returns a product cover path for productPromotion', () {
      final path = pickDefaultCoverPathFor(IntentType.productPromotion);
      expect(
        path,
        anyOf(
          '/storage/default-kolab-covers/product_cover_1.png',
          '/storage/default-kolab-covers/product_cover_2.png',
        ),
      );
    });

    test('returns a venue cover path for venuePromotion', () {
      final path = pickDefaultCoverPathFor(IntentType.venuePromotion);
      expect(
        path,
        anyOf(
          '/storage/default-kolab-covers/venue_1.png',
          '/storage/default-kolab-covers/venue_2.png',
        ),
      );
    });

    test(
      'returns a product cover path for communitySeeking (default fallback)',
      () {
        final path = pickDefaultCoverPathFor(IntentType.communitySeeking);
        expect(path, contains('product_cover_'));
      },
    );
  });

  group('isDefaultCoverUrl', () {
    test('matches a normalized absolute product cover URL', () {
      expect(
        isDefaultCoverUrl(
          'https://api.kolabing.com/storage/default-kolab-covers/product_cover_1.png',
        ),
        isTrue,
      );
    });

    test('matches a normalized absolute venue cover URL', () {
      expect(
        isDefaultCoverUrl(
          'https://api.kolabing.com/storage/default-kolab-covers/venue_2.png',
        ),
        isTrue,
      );
    });

    test('does not match a real uploaded photo URL', () {
      expect(
        isDefaultCoverUrl(
          'https://api.kolabing.com/storage/kolabs/some-upload.jpg',
        ),
        isFalse,
      );
    });

    test('does not match an empty string', () {
      expect(isDefaultCoverUrl(''), isFalse);
    });
  });
}
