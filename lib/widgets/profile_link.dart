import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants/radius.dart';
import '../config/routes/routes.dart';
import '../features/auth/providers/auth_provider.dart';

/// Makes an identity block — avatar, name, type badge — a way into that profile.
///
/// ROLES §4.2 says that inside the app every authenticated viewer gets the full
/// profile, and a review already links to its reviewer. Everywhere else a
/// business or community was *named*, the name was inert: `/profile/{id}` was
/// reachable from four screens in the whole app, so the profile most people
/// never saw was the one the product treats as its centre.
///
/// **The paywall vetoes this.** A free business sees a community's name and logo
/// BLURRED and must not reach the profile behind them (§2.5). Pass
/// `enabled: !hideCreatorIdentity` and the child renders identically — no
/// ripple, no tap target, nothing to discover. The blur is not a hint that
/// something is one tap away.
///
/// **Attendees are linkable too.** They have no *public* page (§4.2), but
/// `PublicProfileScreen` branches to the member view for one, which is how the
/// community roster already opens its members.
class ProfileLink extends ConsumerWidget {
  const ProfileLink({
    required this.child,
    this.profileId,
    this.communityId,
    this.enabled = true,
    this.borderRadius,
    super.key,
  });

  final Widget child;

  /// A `profiles.id`. Keys the business-shaped `PublicProfileScreen`.
  final String? profileId;

  /// A `communities.id`. NOT interchangeable with [profileId] — pushing one into
  /// `/profile/{id}` 404s every profile endpoint.
  final String? communityId;

  /// The paywall's veto, and the "we have no id" case. False renders [child]
  /// untouched.
  final bool enabled;

  final BorderRadius? borderRadius;

  static bool _has(String? id) => id != null && id.isNotEmpty;

  /// Whether there is anywhere to go. Callers that build their own tap target
  /// (a menu item, a trailing chevron) use this to decide whether to show it.
  static bool canOpen({String? profileId, String? communityId}) =>
      _has(profileId) || _has(communityId);

  /// The one place the destination is decided.
  ///
  /// It is viewer-scoped: a business viewer keeps the profile-id-keyed page
  /// because its Send-Kolab flow starts there, while everyone else gets the
  /// community-keyed page when the identity is a community. Returns false when
  /// there was nowhere to go, so a caller can stay silent instead of pushing a
  /// route that 404s.
  static bool open(
    BuildContext context,
    WidgetRef ref, {
    String? profileId,
    String? communityId,
  }) {
    final viewerIsBusiness = ref.read(authProvider).user?.isBusiness ?? false;

    if (viewerIsBusiness && _has(profileId)) {
      context.push('/profile/$profileId');
      return true;
    }
    if (_has(communityId)) {
      context.push(KolabingRoutes.buildCommunityProfilePath(communityId!));
      return true;
    }
    if (_has(profileId)) {
      context.push('/profile/$profileId');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled || !canOpen(profileId: profileId, communityId: communityId)) {
      return child;
    }

    return InkWell(
      onTap: () =>
          open(context, ref, profileId: profileId, communityId: communityId),
      borderRadius: borderRadius ?? BorderRadius.circular(KolabingRadius.md),
      child: child,
    );
  }
}
