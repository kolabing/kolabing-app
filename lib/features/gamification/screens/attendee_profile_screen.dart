import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/stat_card.dart';

/// Attendee profile screen
class AttendeeProfileScreen extends ConsumerWidget {
  const AttendeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final attendeeProfile = user?.attendeeProfile;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.onSurface;
    final secondaryTextColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.onSurfaceVariant;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: KolabingSpacing.lg),

            // Profile avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KolabingColors.primary.withValues(alpha: 0.2),
                border: Border.all(
                  color: KolabingColors.primary,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(user?.displayName ?? 'A'),
                  style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 36, fontWeight: FontWeight.w700, color: KolabingColors.primary),
                ),
              ),
            ),

            const SizedBox(height: KolabingSpacing.md),

            // Name
            Text(
              user?.displayName ?? 'Attendee',
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
            ),

            // Email
            Text(
              user?.email ?? '',
              style: KolabingTextStyles.bodySmall.copyWith(color: secondaryTextColor),
            ),

            const SizedBox(height: KolabingSpacing.lg),

            const SizedBox(height: KolabingSpacing.xl),

            // Stats section
            Text(
              'YOUR STATS',
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: secondaryTextColor, letterSpacing: 1.2),
            ),

            const SizedBox(height: KolabingSpacing.md),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: LucideIcons.star,
                    iconColor: KolabingColors.primary,
                    label: 'Total Points',
                    value: '${attendeeProfile?.totalPoints ?? 0}',
                    showBackground: true,
                  ),
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: StatCard(
                    icon: LucideIcons.target,
                    iconColor: KolabingColors.success,
                    label: 'Challenges',
                    value: '${attendeeProfile?.totalChallengesCompleted ?? 0}',
                    showBackground: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: KolabingSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: LucideIcons.calendar,
                    iconColor: KolabingColors.info,
                    label: 'Events Attended',
                    value: '${attendeeProfile?.totalEventsAttended ?? 0}',
                    showBackground: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: KolabingSpacing.xxl),

            // Settings section
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? KolabingColors.darkBorder : KolabingColors.darkBorder,
                ),
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: LucideIcons.user,
                    label: 'Edit Profile',
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? KolabingColors.darkBorder
                        : KolabingColors.darkBorder,
                  ),
                  _SettingsItem(
                    icon: LucideIcons.bell,
                    label: 'Notifications',
                    onTap: () {
                      // TODO: Navigate to notifications settings
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? KolabingColors.darkBorder
                        : KolabingColors.darkBorder,
                  ),
                  _SettingsItem(
                    icon: LucideIcons.helpCircle,
                    label: 'Help & Support',
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: KolabingSpacing.lg),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KolabingColors.error,
                  side: const BorderSide(color: KolabingColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: KolabingSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go(KolabingRoutes.login);
      }
    }
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: KolabingColors.onSurfaceVariant,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: KolabingColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
