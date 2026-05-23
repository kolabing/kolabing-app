import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kolabing_app/features/onboarding/widgets/photo_upload_widget.dart';

void main() {
  test('materializes picked images with unreadable source paths', () async {
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
    final picked = XFile.fromData(
      bytes,
      path: 'content://google-photos/logo.jpg',
      name: 'logo.jpg',
      mimeType: 'image/jpeg',
    );

    final file = await materializePickedImageFile(picked);

    expect(file.existsSync(), isTrue);
    expect(file.readAsBytesSync(), bytes);
  });
}
