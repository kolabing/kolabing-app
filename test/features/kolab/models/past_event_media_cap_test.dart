import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';

void main() {
  PastEvent event({
    List<String> photos = const [],
    List<String> videos = const [],
  }) => PastEvent(
    name: 'Launch',
    date: DateTime(2026, 1, 1),
    photos: photos,
    videos: videos,
  );

  group('PastEvent media limits', () {
    test('exposes backend media limits (3 photos, 1 video)', () {
      expect(PastEvent.maxPhotos, 3);
      expect(PastEvent.maxVideos, 1);
    });

    test('capMedia keeps at most 3 photos, preserving order', () {
      final capped = event(photos: ['a', 'b', 'c', 'd', 'e']).capMedia();
      expect(capped.photos, ['a', 'b', 'c']);
    });

    test('capMedia keeps at most 1 video', () {
      final capped = event(videos: ['v1', 'v2', 'v3']).capMedia();
      expect(capped.videos, ['v1']);
    });

    test('capMedia is a no-op when within limits', () {
      final original = event(photos: ['a', 'b'], videos: ['v1']);
      final capped = original.capMedia();
      expect(capped.photos, ['a', 'b']);
      expect(capped.videos, ['v1']);
    });

    test('exceedsMediaLimit is true only when over a limit', () {
      expect(event(photos: ['a', 'b', 'c']).exceedsMediaLimit, isFalse);
      expect(event(photos: ['a', 'b', 'c', 'd']).exceedsMediaLimit, isTrue);
      expect(event(videos: ['v1']).exceedsMediaLimit, isFalse);
      expect(event(videos: ['v1', 'v2']).exceedsMediaLimit, isTrue);
    });
  });
}
