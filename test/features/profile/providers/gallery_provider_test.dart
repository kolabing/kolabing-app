import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/constants/api.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';

void main() {
  // Stored media is resolved against the API HOST ROOT (scheme+host, dropping
  // `/api/v1`). Mirror that derivation so the expected host comes from config
  // rather than a hardcoded literal.
  final apiUri = Uri.parse(ApiConfig.baseUrl);
  final hostRoot = Uri(
    scheme: apiUri.scheme,
    host: apiUri.host,
    port: apiUri.hasPort ? apiUri.port : null,
    path: '/',
  );
  String expectedMediaUrl(String relative) {
    final trimmed = relative.startsWith('/') ? relative.substring(1) : relative;
    return hostRoot.resolve(trimmed).toString();
  }

  test('normalizes relative gallery URLs from API payloads', () {
    final photo = GalleryPhoto.fromJson(<String, dynamic>{
      'id': '1',
      'path': '/storage/gallery/photo-1.jpg',
    });

    expect(photo.url, expectedMediaUrl('/storage/gallery/photo-1.jpg'));
  });

  test('supports nested media URL payloads', () {
    final photo = GalleryPhoto.fromJson(<String, dynamic>{
      'id': '2',
      'media': <String, dynamic>{'url': 'storage/gallery/photo-2.jpg'},
    });

    expect(photo.url, expectedMediaUrl('storage/gallery/photo-2.jpg'));
  });
}
