import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/business/screens/business_profile_screen.dart';
import '../../features/community/screens/community_profile_screen.dart';
import '../../features/gamification/screens/attendee_profile_screen.dart';
import '../../utils/remote_media_url.dart';

/// Canonical app-bar avatar that opens the current user's profile (NF-12).
///
/// 38px circle with a hairline border. Loads the user's profile photo
/// (relative URLs normalised via [normalizeRemoteMediaUrlOrNull]), falling back
/// to the user's initial, then to a person icon.
///
/// Community + attendee no longer have a Profile bottom-nav tab — this is the
/// entry point to their (now hidden/pushed) profile, reachable from any tab.
/// Business keeps its Profile tab; tapping here still opens it.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final type = user?.userType;
    final photoUrl = normalizeRemoteMediaUrlOrNull(user?.profilePhotoUrl);
    final initial = _initialOf(user);

    return GestureDetector(
      onTap: () => _openProfile(context, type),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.darkBorder, width: 1.5),
          color: context.colors.surfaceContainerLow,
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(context, initial),
                )
              : _fallback(context, initial),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context, String? initial) {
    if (initial != null && initial.isNotEmpty) {
      return Center(
        child: Text(
          initial,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Icon(
      LucideIcons.user,
      size: 20,
      color: context.colors.onSurfaceVariant,
    );
  }

  String? _initialOf(UserModel? user) {
    final name = user?.displayName.trim();
    if (name == null || name.isEmpty) return null;
    return name.substring(0, 1).toUpperCase();
  }

  void _openProfile(BuildContext context, UserType? type) {
    final Widget screen = switch (type) {
      UserType.business => const BusinessProfileScreen(),
      UserType.community => const CommunityProfileScreen(),
      _ => const AttendeeProfileScreen(),
    };
    // The profile screens were built as nav-tab bodies (no app bar of their
    // own), so when pushed they need a Scaffold + AppBar to provide the back
    // button — otherwise there is no way to exit (NF-12 regression fix).
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: context.colors.navBarBackground,
            foregroundColor: context.colors.charcoal,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text('Profile'),
          ),
          body: screen,
        ),
      ),
    );
  }
}
