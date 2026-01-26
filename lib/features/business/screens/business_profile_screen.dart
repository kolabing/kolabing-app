import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../auth/models/user_model.dart';
import '../models/notification_preferences.dart';
import '../models/subscription.dart';
import '../providers/profile_provider.dart';

/// Business profile screen
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  // Profile is auto-loaded by the provider on initialization

  Future<void> _handleSignOut() async {
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
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(profileProvider.notifier).signOut();
      if (mounted) {
        context.go(KolabingRoutes.welcome);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(profileProvider.notifier).deleteAccount();
      if (success && mounted) {
        context.go(KolabingRoutes.welcome);
      }
    }
  }

  Future<void> _handleManageSubscription() async {
    final url = await ref.read(profileProvider.notifier).getBillingPortalUrl();
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleViewPlans() async {
    final url = await ref.read(profileProvider.notifier).getCheckoutUrl();
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    // Show error snackbar when error changes
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: KolabingColors.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ref.read(profileProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.background,
        elevation: 0,
        title: Text(
          'Profile',
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: KolabingColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ProfileState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(
        child: CircularProgressIndicator(
          color: KolabingColors.primary,
        ),
      );
    }

    if (state.error != null && !state.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: KolabingColors.error,
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                state.error!,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: KolabingColors.primary,
        ),
      );
    }

    final about = profile.businessProfile?.about;
    final hasAbout = about != null && about.isNotEmpty;
    final isBusiness = profile.isBusiness;

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            _buildProfileCard(profile),

            const SizedBox(height: KolabingSpacing.md),

            // About Section
            if (hasAbout) ...[
              _buildAboutSection(about),
              const SizedBox(height: KolabingSpacing.md),
            ],

            // Contact Info Section
            _buildContactInfoSection(profile),

            const SizedBox(height: KolabingSpacing.md),

            // Notification Preferences Section
            _buildNotificationPreferencesSection(
              state.notificationPrefs,
              state.isUpdating,
            ),

            const SizedBox(height: KolabingSpacing.md),

            // Subscription Section (Business only)
            if (isBusiness) ...[
              _buildSubscriptionSection(state.subscription),
              const SizedBox(height: KolabingSpacing.md),
            ],

            // Account Section
            _buildAccountSection(profile.email, state.isUpdating),

            const SizedBox(height: KolabingSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel profile) {
    final name = profile.businessProfile?.name ?? profile.displayName;
    final businessType = profile.businessProfile?.businessType ?? 'Business';
    final photoUrl =
        profile.businessProfile?.profilePhoto ?? profile.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KolabingColors.surfaceVariant,
              shape: BoxShape.circle,
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? const Icon(
                    LucideIcons.building2,
                    size: 32,
                    color: KolabingColors.textTertiary,
                  )
                : null,
          ),

          const SizedBox(width: KolabingSpacing.md),

          // Name and Type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: KolabingTextStyles.headlineSmall.copyWith(
                    color: KolabingColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: KolabingSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.softYellow,
                    borderRadius: KolabingRadius.borderRadiusSm,
                    border: Border.all(color: KolabingColors.softYellowBorder),
                  ),
                  child: Text(
                    businessType.toUpperCase(),
                    style: KolabingTextStyles.labelSmall.copyWith(
                      color: KolabingColors.accentOrangeText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: KolabingSpacing.sm),

          // Edit Button
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.textPrimary,
              side: const BorderSide(color: KolabingColors.border),
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm,
              ),
            ),
            child: Text(
              'EDIT',
              style: KolabingTextStyles.buttonSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String about) {
    return _SectionCard(
      title: 'About',
      child: Text(
        about,
        style: KolabingTextStyles.bodyMedium.copyWith(
          color: KolabingColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildContactInfoSection(UserModel profile) {
    final email = profile.email;
    final phone = profile.phoneNumber;
    final website = profile.businessProfile?.website;
    final instagram = profile.businessProfile?.instagram;
    final city = profile.businessProfile?.city?.name;

    return _SectionCard(
      title: 'Contact Info',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContactInfoTile(
            icon: LucideIcons.mail,
            label: email,
          ),
          if (phone != null && phone.isNotEmpty)
            _ContactInfoTile(
              icon: LucideIcons.phone,
              label: phone,
            ),
          if (city != null && city.isNotEmpty)
            _ContactInfoTile(
              icon: LucideIcons.mapPin,
              label: city,
            ),
          if (website != null && website.isNotEmpty)
            _ContactInfoTile(
              icon: LucideIcons.globe,
              label: website,
              onTap: () => launchUrl(Uri.parse(website)),
            ),
          if (instagram != null && instagram.isNotEmpty)
            _ContactInfoTile(
              icon: LucideIcons.instagram,
              label: '@$instagram',
              onTap: () => launchUrl(
                Uri.parse('https://instagram.com/$instagram'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesSection(
    NotificationPreferences? preferences,
    bool isUpdating,
  ) {
    return _SectionCard(
      title: 'Notification Preferences',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NotificationToggle(
            label: 'Email Notifications',
            value: preferences?.emailNotifications ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('email_notifications', value),
          ),
          _NotificationToggle(
            label: 'WhatsApp Notifications',
            value: preferences?.whatsappNotifications ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('whatsapp_notifications', value),
          ),
          _NotificationToggle(
            label: 'New Application Alerts',
            value: preferences?.newApplicationAlerts ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('new_application_alerts', value),
          ),
          _NotificationToggle(
            label: 'Collaboration Updates',
            value: preferences?.collaborationUpdates ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('collaboration_updates', value),
          ),
          _NotificationToggle(
            label: 'Marketing & Tips',
            value: preferences?.marketingTips ?? false,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('marketing_tips', value),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(Subscription? subscription) {
    final hasSubscription = subscription != null;
    final isActive = subscription?.isActive ?? false;

    Color getStatusColor(SubscriptionStatus? status) {
      switch (status) {
        case SubscriptionStatus.active:
          return KolabingColors.success;
        case SubscriptionStatus.cancelled:
          return KolabingColors.warning;
        case SubscriptionStatus.pastDue:
          return KolabingColors.error;
        default:
          return KolabingColors.textTertiary;
      }
    }

    Color getStatusBgColor(SubscriptionStatus? status) {
      switch (status) {
        case SubscriptionStatus.active:
          return KolabingColors.activeBg;
        case SubscriptionStatus.cancelled:
          return KolabingColors.pendingBg;
        case SubscriptionStatus.pastDue:
          return KolabingColors.errorBg;
        default:
          return KolabingColors.completedBg;
      }
    }

    String formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year}';
    }

    return _SectionCard(
      title: 'Subscription',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Badge
          Row(
            children: [
              Text(
                'Status:',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                  vertical: KolabingSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: getStatusBgColor(subscription?.status),
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
                child: Text(
                  subscription?.statusLabel ??
                      subscription?.status.label ??
                      'No Subscription',
                  style: KolabingTextStyles.labelSmall.copyWith(
                    color: getStatusColor(subscription?.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Period End
          if (hasSubscription && subscription.currentPeriodEnd != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  'Renews: ${formatDate(subscription.currentPeriodEnd!)}',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Days Remaining
          if (hasSubscription && subscription.daysRemaining != null) ...[
            const SizedBox(height: KolabingSpacing.xxs),
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  '${subscription.daysRemaining} days remaining',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Cancel at period end warning
          if (hasSubscription && subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              padding: const EdgeInsets.all(KolabingSpacing.sm),
              decoration: BoxDecoration(
                color: KolabingColors.warning.withValues(alpha: 0.1),
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(
                    color: KolabingColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 16,
                    color: KolabingColors.warning,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Expanded(
                    child: Text(
                      'Subscription will end at the current billing period',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: KolabingSpacing.md),

          // Action Buttons
          if (isActive)
            OutlinedButton.icon(
              onPressed: _handleManageSubscription,
              icon: const Icon(LucideIcons.settings, size: 18),
              label: const Text('MANAGE SUBSCRIPTION'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _handleViewPlans,
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: const Text('VIEW PLANS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(String email, bool isUpdating) {
    return _SectionCard(
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email
          Row(
            children: [
              const Icon(
                LucideIcons.mail,
                size: 20,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  email,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: KolabingColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Sign Out Button
          OutlinedButton.icon(
            onPressed: isUpdating ? null : _handleSignOut,
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: const Text('SIGN OUT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.error,
              side: const BorderSide(color: KolabingColors.error),
              padding: const EdgeInsets.symmetric(
                vertical: KolabingSpacing.sm,
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.sm),

          // Delete Account Button
          TextButton(
            onPressed: isUpdating ? null : _handleDeleteAccount,
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.error,
            ),
            child: Text(
              'Delete Account',
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.error,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Section Card Wrapper
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Contact Info Tile
// -----------------------------------------------------------------------------

class _ContactInfoTile extends StatelessWidget {
  const _ContactInfoTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KolabingRadius.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: KolabingColors.textTertiary,
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: onTap != null
                      ? KolabingColors.primary
                      : KolabingColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.externalLink,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Notification Toggle
// -----------------------------------------------------------------------------

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.label,
    required this.value,
    required this.isUpdating,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: isUpdating ? null : onChanged,
            activeThumbColor: KolabingColors.primary,
            activeTrackColor: KolabingColors.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
