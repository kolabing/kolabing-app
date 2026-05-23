import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';

void main() {
  test('normalizes relative gallery URLs from API payloads', () {
    final photo = GalleryPhoto.fromJson(<String, dynamic>{
      'id': '1',
      'path': '/storage/gallery/photo-1.jpg',
    });

    expect(photo.url, 'https://kolabing.com/storage/gallery/photo-1.jpg');
  });

  test('supports nested media URL payloads', () {
    final photo = GalleryPhoto.fromJson(<String, dynamic>{
      'id': '2',
      'media': <String, dynamic>{'url': 'storage/gallery/photo-2.jpg'},
    });

    expect(photo.url, 'https://kolabing.com/storage/gallery/photo-2.jpg');
  });
}
