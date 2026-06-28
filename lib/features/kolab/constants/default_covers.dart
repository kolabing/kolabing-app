import 'dart:math';

import '../enums/intent_type.dart';

/// Relative storage paths for the 2 product-Kolab default cover variants.
/// Resolved to absolute URLs via `normalizeRemoteMediaUrl()` at the call site
/// (see media_screen.dart) — these are NOT directly usable as `KolabMedia.url`.
const productDefaultCoverPaths = <String>[
  '/storage/default-kolab-covers/product_cover_1.png',
  '/storage/default-kolab-covers/product_cover_2.png',
];

/// Relative storage paths for the 2 venue-Kolab default cover variants.
const venueDefaultCoverPaths = <String>[
  '/storage/default-kolab-covers/venue_1.png',
  '/storage/default-kolab-covers/venue_2.png',
];

final _random = Random();

/// Picks one of the 2 default cover variants for [intent] at random, so not
/// every Kolab of the same type looks identical on Explore. Falls back to
/// the product set for `communitySeeking`, which doesn't use this feature
/// today but keeps the function total rather than nullable.
String pickDefaultCoverPathFor(IntentType intent) {
  final paths = intent == IntentType.venuePromotion
      ? venueDefaultCoverPaths
      : productDefaultCoverPaths;
  return paths[_random.nextInt(paths.length)];
}

/// Whether [url] (already normalized to an absolute URL) points at one of
/// the 4 known default cover variants.
bool isDefaultCoverUrl(String url) {
  if (url.isEmpty) return false;
  return productDefaultCoverPaths.any(url.endsWith) ||
      venueDefaultCoverPaths.any(url.endsWith);
}
