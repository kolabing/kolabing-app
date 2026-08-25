import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/services/public_profile_service.dart';

/// The other member, as resolved from their scanned profile QR.
@immutable
class ScannedPeer {
  const ScannedPeer({required this.profileId, this.displayName});

  /// The reference to send as `verifier_profile_id`.
  ///
  /// Prefers the id the profile lookup returned (the QR may carry an `@handle`
  /// when the profile id was unavailable at render time), falling back to the
  /// scanned value.
  final String profileId;

  /// `null` when the lookup failed or the backend had no usable name — the UI
  /// then falls back to a name-free header rather than showing "Unknown".
  final String? displayName;
}

/// Resolves a scanned profile reference to a [ScannedPeer].
///
/// Best effort by design: pairing must work even when the lookup fails, so a
/// failure resolves to the scanned reference with no name rather than an error.
/// (`PublicProfileResource` is known to return an unusable `display_name` for
/// attendees — BACKLOG FX-16 — so a missing name is expected, not exceptional.)
final scannedPeerProvider = FutureProvider.family<ScannedPeer, String>((
  ref,
  profileRef,
) async {
  try {
    final profile = await PublicProfileService().getPublicProfile(profileRef);
    final name = profile.displayName.trim();
    final usable = name.isNotEmpty && name.toLowerCase() != 'unknown';
    return ScannedPeer(
      profileId: profile.id.isNotEmpty ? profile.id : profileRef,
      displayName: usable ? name : null,
    );
  } on Object catch (e) {
    debugPrint('scannedPeer: lookup failed for $profileRef: $e');
    return ScannedPeer(profileId: profileRef);
  }
});
