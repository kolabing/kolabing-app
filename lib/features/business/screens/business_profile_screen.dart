import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
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
import '../../../widgets/gallery/profile_gallery_section.dart';
import '../../event/widgets/past_events_section.dart';
import '../../settings/widgets/theme_selector_section.dart';

/// Business profile screen
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(profileProvider);
      if (!state.isLoading && !state.hasData && state.error == null) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

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

  void _handleManageSubscription() {
    context.push(KolabingRoutes.businessPlans);
  }

  void _handleViewPlans() {
    context.push(KolabingRoutes.businessPlans);
  }

  Future<void> _handleChangePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KolabingColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'Change Profile Photo',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KolabingColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: KolabingColors.primary,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KolabingColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    color: KolabingColors.info,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: KolabingSpacing.md),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading photo...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Read file and convert to base64
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = pickedFile.mimeType ?? 'image/jpeg';

      // Upload
      final success = await ref
          .read(profileProvider.notifier)
          .updateProfilePhoto(base64Image, mimeType);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated'),
              backgroundColor: KolabingColors.success,
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.darkBackground
          : KolabingColors.background,
      body: SafeArea(
        child: _buildBody(state, isDark),
      ),
    );
  }

  Widget _buildBody(ProfileState state, bool isDark) {
    // Profile content (prioritize rendering data if available)
    if (state.profile != null) {
      return _buildProfileContent(state, isDark);
    }

    // Loading state
    if (state.isLoading) {
      return _buildLoadingState(isDark);
    }

    // Error state without data
    if (state.error != null) {
      return _buildErrorState(state.error!, isDark);
    }

    // Initialized but no data and no error — something went wrong, show retry
    if (state.isInitialized) {
      return _buildErrorState('Failed to load profile', isDark);
    }

    // Initial state (before first load attempt)
    return _buildLoadingState(isDark);
  }

  Widget _buildLoadingState(bool isDark) => SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          children: [
            // Header shimmer
            Shimmer.fromColors(
              baseColor: isDark
                  ? KolabingColors.darkSurface
                  : KolabingColors.surfaceVariant,
              highlightColor: isDark
                  ? KolabingColors.darkBorder
                  : KolabingColors.surface,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KolabingRadius.borderRadiusLg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: KolabingSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: KolabingRadius.borderRadiusSm,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: KolabingRadius.borderRadiusSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            // Section shimmer
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: KolabingSpacing.md),
                child: Shimmer.fromColors(
                  baseColor: isDark
                      ? KolabingColors.darkSurface
                      : KolabingColors.surfaceVariant,
                  highlightColor: isDark
                      ? KolabingColors.darkBorder
                      : KolabingColors.surface,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? KolabingColors.darkSurface : Colors.white,
                      borderRadius: KolabingRadius.borderRadiusLg,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error, bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: KolabingColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertCircle,
                  size: 36,
                  color: KolabingColors.error,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'Something went wrong',
                style: KolabingTextStyles.headlineSmall.copyWith(
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                error,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                label: const Text('TRY AGAIN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.lg,
                    vertical: KolabingSpacing.sm,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfileContent(ProfileState state, bool isDark) {
    final profile = state.profile!;
    final about = profile.businessProfile?.about;
    final hasAbout = about != null && about.isNotEmpty;
    final isBusiness = profile.isBusiness;

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      color: KolabingColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            _buildProfileHeader(profile, state.isUpdating, isDark),

            const SizedBox(height: KolabingSpacing.md),

            // About Section
            if (hasAbout) ...[
              _buildAboutSection(about, isDark),
              const SizedBox(height: KolabingSpacing.md),
            ],

            // Subscription Section (Business only - prominently displayed)
            if (isBusiness) ...[
              _buildSubscriptionSection(state.subscription, isDark),
              const SizedBox(height: KolabingSpacing.md),
            ],

            // Gallery Section
            const ProfileGallerySection(),

            const SizedBox(height: KolabingSpacing.md),

            // Past Events Section
            const PastEventsSection(),

            const SizedBox(height: KolabingSpacing.md),

            // Contact Info Section
            _buildContactInfoSection(profile, isDark),

            const SizedBox(height: KolabingSpacing.md),

            // Notification Preferences Section
            _buildNotificationPreferencesSection(
              state.notificationPrefs,
              state.isUpdating,
              isDark,
            ),

            const SizedBox(height: KolabingSpacing.md),

            // Theme Selector Section
            const ThemeSelectorSection(),

            const SizedBox(height: KolabingSpacing.md),

            // Account Section
            _buildAccountSection(profile.email, state.isUpdating, isDark),

            const SizedBox(height: KolabingSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel profile, bool isUpdating, bool isDark) {
    final name = profile.businessProfile?.name ?? profile.displayName;
    final businessType = profile.businessProfile?.businessType ?? 'Business';
    final photoUrl =
        profile.businessProfile?.profilePhoto ?? profile.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              GestureDetector(
                onTap: isUpdating ? null : _handleChangePhoto,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KolabingColors.primary,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
                          )
                        : _buildAvatarPlaceholder(name),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUpdating ? null : _handleChangePhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: KolabingColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? KolabingColors.darkSurface
                            : KolabingColors.surface,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 16,
                      color: KolabingColors.onPrimary,
                    ),
                  ),
                ),
              ),
              if (isUpdating)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Name
          Text(
            name,
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: isDark
                  ? KolabingColors.textOnDark
                  : KolabingColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: KolabingSpacing.xs),

          // Business type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.softYellow,
              borderRadius: KolabingRadius.borderRadiusRound,
              border: Border.all(color: KolabingColors.softYellowBorder),
            ),
            child: Text(
              businessType.toUpperCase(),
              style: KolabingTextStyles.labelSmall.copyWith(
                color: KolabingColors.accentOrangeText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) => Container(
        color: KolabingColors.surfaceVariant,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: KolabingTextStyles.displaySmall.copyWith(
              color: KolabingColors.textTertiary,
            ),
          ),
        ),
      );

  Widget _buildAboutSection(String about, bool isDark) => _SectionCard(
        title: 'About',
        child: Text(
          about,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textSecondary,
          ),
        ),
      );

  Widget _buildSubscriptionSection(Subscription? subscription, bool isDark) {
    final hasSubscription = subscription != null;
    final isActive = subscription?.isActive ?? false;

    return _SectionCard(
      title: 'Subscription',
      titleIcon: LucideIcons.sparkles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? KolabingColors.success.withValues(alpha: 0.1)
                      : KolabingColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? LucideIcons.crown : LucideIcons.sparkles,
                  color: isActive
                      ? KolabingColors.success
                      : KolabingColors.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: KolabingSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Premium Plan' : 'No Active Plan',
                      style: KolabingTextStyles.titleMedium.copyWith(
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildStatusBadge(subscription?.status),
                  ],
                ),
              ),
            ],
          ),

          // Subscription details
          if (hasSubscription && isActive) ...[
            const SizedBox(height: KolabingSpacing.md),
            const Divider(height: 1, color: KolabingColors.border),
            const SizedBox(height: KolabingSpacing.md),

            // Renewal date
            if (subscription.currentPeriodEnd != null)
              _buildDetailRow(
                icon: LucideIcons.calendar,
                label: 'Renews',
                value: _formatDate(subscription.currentPeriodEnd!),
              ),

            // Days remaining
            if (subscription.daysRemaining != null) ...[
              const SizedBox(height: KolabingSpacing.sm),
              _buildDetailRow(
                icon: LucideIcons.clock,
                label: 'Remaining',
                value: '${subscription.daysRemaining} days',
              ),
            ],

            // Cancel warning
            if (subscription.cancelAtPeriodEnd) ...[
              const SizedBox(height: KolabingSpacing.md),
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.sm),
                decoration: BoxDecoration(
                  color: KolabingColors.warning.withValues(alpha: 0.1),
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(
                    color: KolabingColors.warning.withValues(alpha: 0.3),
                  ),
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
                        'Subscription ends at current billing period',
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: KolabingSpacing.md),

          // Action button
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
              label: const Text('UPGRADE TO PREMIUM'),
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

  Widget _buildStatusBadge(SubscriptionStatus? status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case SubscriptionStatus.active:
        bgColor = KolabingColors.activeBg;
        textColor = KolabingColors.success;
        label = 'Active';
      case SubscriptionStatus.cancelled:
        bgColor = KolabingColors.pendingBg;
        textColor = KolabingColors.warning;
        label = 'Cancelled';
      case SubscriptionStatus.pastDue:
        bgColor = KolabingColors.errorBg;
        textColor = KolabingColors.error;
        label = 'Past Due';
      default:
        bgColor = KolabingColors.surfaceVariant;
        textColor = KolabingColors.textTertiary;
        label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: KolabingRadius.borderRadiusSm,
      ),
      child: Text(
        label,
        style: KolabingTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Row(
        children: [
          Icon(icon, size: 16, color: KolabingColors.textTertiary),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            '$label: ',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Widget _buildContactInfoSection(UserModel profile, bool isDark) {
    final email = profile.email;
    final phone = profile.phoneNumber;
    final website = profile.businessProfile?.website;
    final instagram = profile.businessProfile?.instagram;
    final city = profile.businessProfile?.city?.name;

    return _SectionCard(
      title: 'Contact Info',
      child: Column(
        children: [
          _ContactInfoTile(icon: LucideIcons.mail, label: email),
          if (phone != null && phone.isNotEmpty)
            _ContactInfoTile(icon: LucideIcons.phone, label: phone),
          if (city != null && city.isNotEmpty)
            _ContactInfoTile(icon: LucideIcons.mapPin, label: city),
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
              onTap: () =>
                  launchUrl(Uri.parse('https://instagram.com/$instagram')),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesSection(
    NotificationPreferences? preferences,
    bool isUpdating,
    bool isDark,
  ) =>
      _SectionCard(
        title: 'Notifications',
        child: Column(
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

  Widget _buildAccountSection(String email, bool isUpdating, bool isDark) =>
      _SectionCard(
        title: 'Account',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            const SizedBox(height: KolabingSpacing.md),

            // Delete Account
            GestureDetector(
              onTap: isUpdating ? null : _handleDeleteAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
                child: Text(
                  'Delete Account',
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: isUpdating
                        ? KolabingColors.textTertiary
                        : KolabingColors.error,
                    decoration: TextDecoration.underline,
                    decorationColor: isUpdating
                        ? KolabingColors.textTertiary
                        : KolabingColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Section Card Wrapper
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleIcon,
  });

  final String title;
  final Widget child;
  final IconData? titleIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: isDark
            ? null
            : [
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
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  size: 20,
                  color: KolabingColors.primary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
              ],
              Text(
                title,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark
                  ? KolabingColors.textOnDark.withValues(alpha: 0.6)
                  : KolabingColors.textTertiary,
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: onTap != null
                      ? KolabingColors.info
                      : isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                LucideIcons.externalLink,
                size: 16,
                color: isDark
                    ? KolabingColors.textOnDark.withValues(alpha: 0.6)
                    : KolabingColors.textTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isUpdating ? 0.6 : 1.0,
      child: InkWell(
        onTap: isUpdating
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged(!value);
              },
        borderRadius: KolabingRadius.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? KolabingColors.textOnDark
                        : KolabingColors.textPrimary,
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
        ),
      ),
    );
  }
}
