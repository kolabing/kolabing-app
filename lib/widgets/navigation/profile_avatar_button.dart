import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants/spacing.dart';
import '../../config/theme/colors.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/business/screens/business_profile_screen.dart';
import '../../features/community/screens/community_profile_screen.dart';
import '../../features/gamification/screens/attendee_profile_screen.dart';

/// App-bar avatar that opens the current user's profile (NF-12).
///
/// Community + attendee no longer have a Profile bottom-nav tab — this is the
/// entry point to their (now hidden/pushed) profile, reachable from any tab.
/// Business keeps its Profile tab; tapping here still opens it.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(authProvider).user?.userType;
    return Padding(
      padding: const EdgeInsets.only(right: KolabingSpacing.md),
      child: GestureDetector(
        onTap: () => _openProfile(context, type),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: KolabingColors.charcoal,
          child: Icon(
            Icons.person,
            size: 18,
            color: KolabingColors.navBarBackground,
          ),
        ),
      ),
    );
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
            backgroundColor: KolabingColors.navBarBackground,
            foregroundColor: KolabingColors.charcoal,
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
