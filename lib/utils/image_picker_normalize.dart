import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// C10 fix: some sources (iOS Google Photos, certain cloud providers) return
/// an `XFile` whose `.path` is a content URI / asset identifier that the
/// `dart:io` `File` class cannot open. Uploads still succeed because the HTTP
/// layer pulls bytes from the XFile, but in-app previews built with
/// `Image.file(File(path))` end up blank.
///
/// This helper materialises the picked image to a real file under the app's
/// cache directory and returns its path, so every downstream consumer can
/// rely on `File(path)` working.
///
/// Returns the original path if it already points to a usable local file.
Future<String> normalizePickedImage(XFile picked) async {
  final candidate = File(picked.path);
  if (await _isReadable(candidate)) {
    return picked.path;
  }

  try {
    final bytes = await picked.readAsBytes();
    final cacheDir = Directory.systemTemp;
    final safeName = picked.name.isNotEmpty
        ? picked.name
        : 'picked_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final outPath = '${cacheDir.path}/normalized_$safeName';
    final out = File(outPath);
    await out.writeAsBytes(bytes, flush: true);
    debugPrint(
      '[C10] normalized picked image: ${picked.path} -> $outPath '
      '(${bytes.length} bytes)',
    );
    return outPath;
  } on Exception catch (e) {
    debugPrint('[C10] normalize failed for ${picked.path}: $e');
    // Returning the original path keeps the upload path working (uploads use
    // the XFile API internally) — only the preview suffers, which matches
    // the pre-fix behavior.
    return picked.path;
  }
}

Future<bool> _isReadable(File f) async {
  try {
    // Avoid materialising large reads — `length()` is enough to confirm the
    // dart:io File handle resolves the path.
    await f.length();
    return true;
  } on Exception {
    return false;
  }
}
