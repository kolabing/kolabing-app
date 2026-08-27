import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Universal Links (iOS) and App Links (Android) (#183, kolabing-v2#246).
///
/// The app is registered for **`app.kolabing.com`**, not the marketing domain:
/// the association files (`apple-app-site-association`, `assetlinks.json`) are
/// served from there, and a link on `kolabing.com` would open a browser even on
/// a phone that has Kolabing installed.
///
/// This handles the half of an invite that a link *can* do — the phone that
/// already has the app. The other half cannot be done with a link at all: a
/// Universal Link carries no state through the App Store, so the same code is
/// also printed on the landing page for someone to type in afterwards. That is
/// what `ClaimCodeSheet` is for.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// Start listening, and hand back the link the app was launched with if there
  /// was one.
  ///
  /// [onInviteCode] fires for `/i/{code}`. Nothing else is claimed here on
  /// purpose: check-in URLs already have their own handling, and a service that
  /// quietly swallows every link is one nobody can reason about.
  Future<void> start({required void Function(String code) onInviteCode}) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _dispatch(initial, onInviteCode);

      _subscription = _appLinks.uriLinkStream.listen(
        (uri) => _dispatch(uri, onInviteCode),
        // A dead link stream must not take the app with it. Deep links are a
        // convenience; every destination they reach is reachable by hand.
        onError: (Object e) => debugPrint('🔗 Deep link stream error: $e'),
      );
    } catch (e) {
      debugPrint('🔗 Deep links unavailable: $e');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _dispatch(Uri uri, void Function(String code) onInviteCode) {
    final code = inviteCodeFrom(uri);
    if (code != null) {
      debugPrint('🔗 Invite link: $code');
      onInviteCode(code);
    }
  }

  /// The claim code in an invite URL, or null if this is not one.
  ///
  /// Static and pure so the parsing can be tested without a platform channel —
  /// which is the only part of this worth testing.
  @visibleForTesting
  static String? inviteCodeFrom(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length < 2 || segments.first != 'i') return null;

    final code = segments[1].trim().toUpperCase();
    // Codes are six characters from an unambiguous alphabet. Anything else
    // arrived from a link that is not ours, and guessing would send someone to
    // a sheet that can only tell them they are wrong.
    if (!RegExp(r'^[A-Z0-9]{4,16}$').hasMatch(code)) return null;

    return code;
  }
}
