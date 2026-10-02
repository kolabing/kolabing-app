import 'dart:async';

import 'package:flutter/foundation.dart';

/// The link the backend's `/instagram/callback` sends the app back to:
/// `kolabing://instagram/connected?status=ok|error[&reason=...]`.
///
/// It can reach the app two ways, and both are handled:
/// - Flutter's own deep linking hands it to GoRouter (caught by
///   [instagramReturnRedirect] in `routes.dart`, so it never lands on the
///   "page not found" screen);
/// - `app_links` hands it to `DeepLinkService`.
///
/// Both feed [InstagramReturnBus], which drops the duplicate.
@immutable
class InstagramReturnLink {
  const InstagramReturnLink({required this.ok, this.reason});

  final bool ok;

  /// Optional machine reason on failure (e.g. `not_professional`).
  final String? reason;

  /// Instagram only allows Professional accounts; the backend may say so on
  /// the way back. Accept the likely spellings.
  bool get isPersonalAccountError {
    final r = reason?.toLowerCase();
    return !ok &&
        r != null &&
        (r.contains('personal') || r.contains('professional'));
  }

  /// Returns the parsed link, or null when [uri] is not the Instagram return.
  ///
  /// Shapes accepted:
  /// - `kolabing://instagram/connected?status=ok` (the raw custom-scheme URI;
  ///   `instagram` is the URI *host* here, not a path segment);
  /// - `/instagram/connected?status=ok` (a platform that forwards host+path);
  /// - `/connected?status=ok` (a platform that forwards only the path).
  static InstagramReturnLink? tryParse(Uri uri) {
    final path = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    final status = uri.queryParameters['status'];

    final bool matches;
    if (uri.scheme == 'kolabing') {
      matches = uri.host == 'instagram' && path == '/connected';
    } else if (!uri.hasScheme || uri.scheme.isEmpty) {
      matches =
          path == '/instagram/connected' ||
          (path == '/connected' && status != null);
    } else {
      matches = false;
    }
    if (!matches) return null;

    final reason =
        uri.queryParameters['reason'] ?? uri.queryParameters['error'];
    return InstagramReturnLink(
      ok: status?.toLowerCase() == 'ok',
      reason: (reason == null || reason.isEmpty) ? null : reason,
    );
  }
}

/// App-wide channel for [InstagramReturnLink]s.
///
/// Module-level on purpose, like the deep-link and notification routers: the
/// link arrives outside any widget, and the connect card that cares about it
/// may or may not be on screen.
class InstagramReturnBus {
  InstagramReturnBus({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static final InstagramReturnBus instance = InstagramReturnBus();

  /// The same link can arrive through GoRouter and `app_links` within a few
  /// milliseconds; anything inside this window counts once.
  static const Duration dedupeWindow = Duration(seconds: 3);

  final DateTime Function() _clock;
  final StreamController<InstagramReturnLink> _controller =
      StreamController<InstagramReturnLink>.broadcast();
  DateTime? _lastAt;
  InstagramReturnLink? _last;

  Stream<InstagramReturnLink> get stream => _controller.stream;

  /// Publish a return link. Returns false when it was a duplicate.
  bool add(InstagramReturnLink link) {
    final now = _clock();
    final last = _last;
    final lastAt = _lastAt;
    if (last != null &&
        lastAt != null &&
        last.ok == link.ok &&
        last.reason == link.reason &&
        now.difference(lastAt) < dedupeWindow) {
      return false;
    }
    _last = link;
    _lastAt = now;
    _controller.add(link);
    return true;
  }
}

/// GoRouter top-level `redirect` hook for the Instagram return link.
///
/// Returns null when [uri] is not the return link (the router carries on as
/// before). Otherwise it publishes the link on [bus] and answers with where
/// the app already is ([currentLocation]), so the platform's deep link does not
/// open the "page not found" screen. The page under the person keeps its key,
/// so a profile screen opened on top of it (a tab, or a pushed pageless route)
/// stays put. On a cold start there is no current location: [fallback].
///
/// A redirect rather than GoRouter's `onEnter`: any `onEnter` makes every
/// navigation in the app asynchronous, including the first frame at launch.
String? instagramReturnRedirect(
  Uri uri, {
  required String? Function() currentLocation,
  required String fallback,
  InstagramReturnBus? bus,
}) {
  final link = InstagramReturnLink.tryParse(uri);
  if (link == null) return null;
  (bus ?? InstagramReturnBus.instance).add(link);
  return currentLocation() ?? fallback;
}
