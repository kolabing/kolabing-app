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
import '../../../widgets/gallery/profile_gallery_section.dart';
import '../../../widgets/glass_button.dart';
import '../../auth/models/user_model.dart';
import '../../business/models/notification_preferences.dart';
import '../../business/providers/profile_provider.dart';
import '../../event/widgets/past_events_section.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Community profile screen
class CommunityProfileScreen extends ConsumerStatefulWidget {
  const CommunityProfileScreen({super.key});

  @override
  ConsumerState<CommunityProfileScreen> createState() =>
      _CommunityProfileScreenState();
}

class _CommunityProfileScreenState
    extends ConsumerState<CommunityProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Profile auto-loads in ProfileNotifier.build()
    // Only trigger a re-load if we had a previous error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(profileProvider);
      if (state.error != null && !state.isLoading) {
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
        context.go(KolabingRoutes.login);
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
                  color: KolabingColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'Change Profile Photo',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.onSurface,
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

      // Upload the picked image as a multipart file. The backend validates
      // profile_photo as an uploaded image file (a base64 string is rejected
      // with 422), so we pass the file path.
      final success = await ref
          .read(profileProvider.notifier)
          .updateProfilePhoto(pickedFile.path);

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
          ? KolabingColors.surface
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
                      : KolabingColors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                error,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              GlassButton(
                label: 'try again',
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadProfile(),
                intent: GlassButtonIntent.primary,
                icon: LucideIcons.rotateCcw,
              ),
            ],
          ),
        ),
      );

  Widget _buildProfileContent(ProfileState state, bool isDark) {
    final profile = state.profile!;
    final about = profile.communityProfile?.about;
    final hasAbout = about != null && about.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileScreenHeader(isDark),
        Expanded(
          child: RefreshIndicator(
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

            // Account Section
            _buildAccountSection(profile.email, state.isUpdating, isDark),

            const SizedBox(height: KolabingSpacing.xxl),
          ],
        ),
      ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScreenHeader(bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.md,
      KolabingSpacing.md,
      KolabingSpacing.xs,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'PROFILE',
            style: KolabingTextStyles.headlineLarge.copyWith(
              color: isDark ? KolabingColors.textOnDark : KolabingColors.onSurface,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Icon(
          LucideIcons.pencil,
          size: 20,
          color: KolabingColors.onSurfaceVariant,
        ),
      ],
    ),
  );

  Widget _buildProfileHeader(UserModel profile, bool isUpdating, bool isDark) {
    final name = profile.communityProfile?.name ?? profile.displayName;
    final communityType =
        profile.communityProfile?.communityTypeLabel ?? 'Community';
    final photoUrl =
        profile.communityProfile?.profilePhoto ?? profile.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: const Color(0xFFEAE3D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with edit button
          Stack(
            children: [
              GestureDetector(
                onTap: isUpdating ? null : _handleChangePhoto,
                child: Container(
                  width: 96,
                  height: 96,
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
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarPlaceholder(name),
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
                      color: Color(0xFF5C4A12),
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
            style: KolabingTextStyles.titleLarge.copyWith(
              color: isDark
                  ? KolabingColors.textOnDark
                  : KolabingColors.onSurface,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: KolabingSpacing.xs),

          // Community type badge — slate palette
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E9F2),
              borderRadius: KolabingRadius.borderRadiusRound,
            ),
            child: Text(
              communityType,
              style: KolabingTextStyles.labelSmall.copyWith(
                color: const Color(0xFF3D4A5C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.xs),

          // XP level chip
          Consumer(
            builder: (_, ref, __) {
              final wallet = ref.watch(walletSummaryProvider);
              if (wallet == null) return const SizedBox.shrink();
              final level = wallet.level;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                  vertical: KolabingSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: KolabingColors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusRound,
                  border: Border.all(color: KolabingColors.softYellowBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shield, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'LVL ${level.number} · ${level.title} · ${wallet.totalXp} XP',
                      style: KolabingTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            },
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
            color: KolabingColors.onSurfaceVariant,
          ),
        ),
      );

  Widget _buildContactInfoSection(UserModel profile, bool isDark) {
    final email = profile.email;
    final phone = profile.phoneNumber;
    final website = profile.communityProfile?.website;
    final instagram = profile.communityProfile?.instagram;
    final tiktok = profile.communityProfile?.tiktok;
    final city = profile.communityProfile?.city?.name;

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
          if (tiktok != null && tiktok.isNotEmpty)
            _ContactInfoTile(
              icon: LucideIcons.music2,
              label: '@$tiktok',
              onTap: () => launchUrl(Uri.parse('https://tiktok.com/@$tiktok')),
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
              label: 'Messages',
              value: preferences?.messagesEnabled ?? true,
              isUpdating: isUpdating,
              onChanged: (value) => ref
                  .read(profileProvider.notifier)
                  .updateNotificationPreference('messages_enabled', value),
            ),
            _NotificationToggle(
              label: 'Application Alerts',
              value: preferences?.applicationsEnabled ?? true,
              isUpdating: isUpdating,
              onChanged: (value) => ref
                  .read(profileProvider.notifier)
                  .updateNotificationPreference('applications_enabled', value),
            ),
            _NotificationToggle(
              label: 'Kolab Updates',
              value: preferences?.collaborationsEnabled ?? true,
              isUpdating: isUpdating,
              onChanged: (value) => ref
                  .read(profileProvider.notifier)
                  .updateNotificationPreference('collaborations_enabled', value),
            ),
            _NotificationToggle(
              label: 'Rewards & Wallet',
              value: preferences?.rewardsEnabled ?? true,
              isUpdating: isUpdating,
              onChanged: (value) => ref
                  .read(profileProvider.notifier)
                  .updateNotificationPreference('rewards_enabled', value),
            ),
            _NotificationToggle(
              label: 'Marketing & Tips',
              value: preferences?.marketingEnabled ?? false,
              isUpdating: isUpdating,
              onChanged: (value) => ref
                  .read(profileProvider.notifier)
                  .updateNotificationPreference('marketing_enabled', value),
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
                Icon(
                  LucideIcons.mail,
                  size: 20,
                  color: isDark
                      ? KolabingColors.textOnDark.withValues(alpha: 0.6)
                      : KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Text(
                    email,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: KolabingSpacing.lg),

            // Sign Out Button
            GlassButton(
              label: 'sign out',
              onPressed: isUpdating ? null : _handleSignOut,
              intent: GlassButtonIntent.destructive,
              icon: LucideIcons.logOut,
            ),

            const SizedBox(height: KolabingSpacing.md),

            // Delete Account
            GestureDetector(
              onTap: isUpdating ? null : _handleDeleteAccount,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
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
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: const Color(0xFFEAE3D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: KolabingTextStyles.labelLarge.copyWith(
              color: KolabingColors.textTertiary,
              letterSpacing: 1.0,
            ),
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
                      ? const Color(0xFF5A5470)
                      : isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.onSurface,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.externalLink,
                size: 16,
                color: Color(0xFF5A5470),
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
                        : KolabingColors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: isUpdating ? null : onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: KolabingColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
