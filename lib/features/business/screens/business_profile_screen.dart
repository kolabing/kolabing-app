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
import '../../../l10n/app_localizations.dart';
import '../../../widgets/gallery/profile_gallery_section.dart';
import '../../../widgets/glass_button.dart';
import '../../auth/models/user_model.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../models/notification_preferences.dart';
import '../models/subscription.dart';
import '../providers/profile_provider.dart';
import '../../event/widgets/past_events_section.dart';

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
        title: Text(AppLocalizations.of(context).businessProfileSignOutTitle),
        content: Text(
          AppLocalizations.of(context).businessProfileSignOutMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(AppLocalizations.of(context).businessProfileSignOut),
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
        title: Text(
          AppLocalizations.of(context).businessProfileDeleteAccountTitle,
        ),
        content: Text(
          AppLocalizations.of(context).businessProfileDeleteAccountMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(AppLocalizations.of(context).businessProfileDelete),
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

  Future<void> _handleViewPlans() async {
    // Upgrade entry point: show the same two-plan paywall modal used at publish
    // time (monthly + 3-month picker), not the legacy single-plan screen.
    final subscribed = await SubscriptionPaywall.checkAndShow(context, ref);
    if (subscribed && mounted) {
      await ref.read(profileProvider.notifier).refreshSubscription();
    }
  }

  Future<void> _handleChangePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.surface,
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
                  color: context.colors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                AppLocalizations.of(context).businessProfileChangePhotoTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    color: context.colors.primary,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context).businessProfileTakePhoto,
                ),
                subtitle: Text(
                  AppLocalizations.of(context).businessProfileTakePhotoSubtitle,
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.image, color: context.colors.info),
                ),
                title: Text(
                  AppLocalizations.of(context).businessProfileChooseFromGallery,
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  ).businessProfileChooseFromGallerySubtitle,
                ),
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
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).businessProfileUploadingPhoto,
                ),
              ],
            ),
            duration: const Duration(seconds: 30),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context).businessProfilePhotoUpdated,
              ),
              backgroundColor: context.colors.success,
            ),
          );
        }
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).businessProfilePhotoUpdateFailed,
            ),
            backgroundColor: context.colors.error,
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
            backgroundColor: context.colors.error,
            action: SnackBarAction(
              label: AppLocalizations.of(context).businessProfileDismiss,
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
          ? context.colors.surface
          : context.colors.background,
      body: SafeArea(child: _buildBody(state, isDark)),
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
      return _buildErrorState(
        AppLocalizations.of(context).businessProfileLoadFailed,
        isDark,
      );
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
              ? context.colors.darkSurface
              : context.colors.surfaceVariant,
          highlightColor: isDark
              ? context.colors.darkBorder
              : context.colors.surface,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? context.colors.darkSurface : Colors.white,
              borderRadius: KolabingRadius.borderRadiusLg,
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? context.colors.darkSurface : Colors.white,
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
                          color: isDark
                              ? context.colors.darkSurface
                              : Colors.white,
                          borderRadius: KolabingRadius.borderRadiusSm,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark
                              ? context.colors.darkSurface
                              : Colors.white,
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
                  ? context.colors.darkSurface
                  : context.colors.surfaceVariant,
              highlightColor: isDark
                  ? context.colors.darkBorder
                  : context.colors.surface,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? context.colors.darkSurface : Colors.white,
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
            decoration: BoxDecoration(
              color: context.colors.errorBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.alertCircle,
              size: 36,
              color: context.colors.error,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).businessProfileSomethingWrong,
            style: KolabingTextStyles.headlineSmall.copyWith(
              color: isDark
                  ? context.colors.textOnDark
                  : context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          GlassButton(
            label: AppLocalizations.of(context).businessProfileTryAgain,
            onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
            intent: GlassButtonIntent.primary,
            icon: LucideIcons.rotateCcw,
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
      color: context.colors.primary,
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
              _buildSubscriptionSection(
                state.subscription,
                isDark,
                state.isSubscribed,
              ),
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
    );
  }

  Widget _buildProfileHeader(UserModel profile, bool isUpdating, bool isDark) {
    final name = profile.businessProfile?.name ?? profile.displayName;
    final businessType =
        profile.businessProfile?.businessTypesSummary ??
        AppLocalizations.of(context).businessProfileBusinessFallback;
    final photoUrl = profile.businessProfile?.profilePhoto ?? profile.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
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
                    border: Border.all(color: context.colors.primary, width: 3),
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
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? context.colors.darkSurface
                            : context.colors.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      size: 16,
                      color: context.colors.onPrimary,
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
                  ? context.colors.textOnDark
                  : context.colors.onSurface,
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
              color: context.colors.softYellow,
              borderRadius: KolabingRadius.borderRadiusRound,
              border: Border.all(color: context.colors.softYellowBorder),
            ),
            child: Text(
              businessType,
              style: KolabingTextStyles.labelSmall.copyWith(
                color: context.colors.accentOrangeText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) => Container(
    color: context.colors.surfaceVariant,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: KolabingTextStyles.displaySmall.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
    ),
  );

  Widget _buildAboutSection(String about, bool isDark) => _SectionCard(
    title: AppLocalizations.of(context).businessProfileAbout,
    child: Text(
      about,
      style: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildSubscriptionSection(
    Subscription? subscription,
    bool isDark,
    bool isSubscribed,
  ) {
    final hasSubscription = subscription != null;
    final isActive = isSubscribed;

    return _SectionCard(
      title: AppLocalizations.of(context).businessProfileSubscription,
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
                      ? context.colors.success.withValues(alpha: 0.1)
                      : context.colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? LucideIcons.crown : LucideIcons.sparkles,
                  color: isActive
                      ? context.colors.success
                      : context.colors.textTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: KolabingSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? AppLocalizations.of(
                              context,
                            ).businessProfilePremiumPlan
                          : AppLocalizations.of(
                              context,
                            ).businessProfileNoActivePlan,
                      style: KolabingTextStyles.titleMedium.copyWith(
                        color: context.colors.onSurface,
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
            Divider(height: 1, color: context.colors.darkBorder),
            const SizedBox(height: KolabingSpacing.md),

            // Renewal date
            if (subscription.currentPeriodEnd != null)
              _buildDetailRow(
                icon: LucideIcons.calendar,
                label: AppLocalizations.of(context).businessProfileRenews,
                value: _formatDate(subscription.currentPeriodEnd!),
              ),

            // Days remaining
            if (subscription.daysRemaining != null) ...[
              const SizedBox(height: KolabingSpacing.sm),
              _buildDetailRow(
                icon: LucideIcons.clock,
                label: AppLocalizations.of(context).businessProfileRemaining,
                value: AppLocalizations.of(
                  context,
                ).businessProfileDaysRemaining(subscription.daysRemaining!),
              ),
            ],

            // Cancel warning
            if (subscription.cancelAtPeriodEnd) ...[
              const SizedBox(height: KolabingSpacing.md),
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.1),
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(
                    color: context.colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: context.colors.warning,
                    ),
                    const SizedBox(width: KolabingSpacing.xs),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).businessProfileSubscriptionEnding,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.warning,
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
            GlassButton(
              label: AppLocalizations.of(
                context,
              ).businessProfileManageSubscription,
              onPressed: _handleManageSubscription,
              intent: GlassButtonIntent.neutral,
              icon: LucideIcons.settings,
            )
          else
            GlassButton(
              label: AppLocalizations.of(context).businessProfileUpgradePremium,
              onPressed: _handleViewPlans,
              intent: GlassButtonIntent.primary,
              icon: LucideIcons.sparkles,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SubscriptionStatus? status) {
    final l10n = AppLocalizations.of(context);
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case SubscriptionStatus.active:
        bgColor = context.colors.activeBg;
        textColor = context.colors.success;
        label = l10n.businessProfileStatusActive;
      case SubscriptionStatus.cancelled:
        bgColor = context.colors.pendingBg;
        textColor = context.colors.warning;
        label = l10n.businessProfileStatusCancelled;
      case SubscriptionStatus.pastDue:
        bgColor = context.colors.errorBg;
        textColor = context.colors.error;
        label = l10n.businessProfileStatusPastDue;
      default:
        bgColor = context.colors.surfaceVariant;
        textColor = context.colors.textTertiary;
        label = l10n.businessProfileStatusInactive;
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
  }) => Row(
    children: [
      Icon(icon, size: 16, color: context.colors.textTertiary),
      const SizedBox(width: KolabingSpacing.xs),
      Text(
        '$label: ',
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      Text(
        value,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Widget _buildContactInfoSection(UserModel profile, bool isDark) {
    final email = profile.email;
    final phone = profile.phoneNumber;
    final website = profile.businessProfile?.website;
    final instagram = profile.businessProfile?.instagram;
    final city = profile.businessProfile?.city?.name;

    return _SectionCard(
      title: AppLocalizations.of(context).businessProfileContactInfo,
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
  ) => _SectionCard(
    title: AppLocalizations.of(context).businessProfileNotifications,
    child: Column(
      children: [
        _NotificationToggle(
          label: AppLocalizations.of(context).businessProfileNotifMessages,
          value: preferences?.messagesEnabled ?? true,
          isUpdating: isUpdating,
          onChanged: (value) => ref
              .read(profileProvider.notifier)
              .updateNotificationPreference('messages_enabled', value),
        ),
        _NotificationToggle(
          label: AppLocalizations.of(context).businessProfileNotifApplications,
          value: preferences?.applicationsEnabled ?? true,
          isUpdating: isUpdating,
          onChanged: (value) => ref
              .read(profileProvider.notifier)
              .updateNotificationPreference('applications_enabled', value),
        ),
        _NotificationToggle(
          label: AppLocalizations.of(context).businessProfileNotifKolabUpdates,
          value: preferences?.collaborationsEnabled ?? true,
          isUpdating: isUpdating,
          onChanged: (value) => ref
              .read(profileProvider.notifier)
              .updateNotificationPreference('collaborations_enabled', value),
        ),
        _NotificationToggle(
          label: AppLocalizations.of(context).businessProfileNotifRewards,
          value: preferences?.rewardsEnabled ?? true,
          isUpdating: isUpdating,
          onChanged: (value) => ref
              .read(profileProvider.notifier)
              .updateNotificationPreference('rewards_enabled', value),
        ),
        _NotificationToggle(
          label: AppLocalizations.of(context).businessProfileNotifMarketing,
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
        title: AppLocalizations.of(context).businessProfileAccount,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            Row(
              children: [
                Icon(
                  LucideIcons.mail,
                  size: 20,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Text(
                    email,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: KolabingSpacing.sm),

            // Language
            _ContactInfoTile(
              icon: LucideIcons.globe,
              label: AppLocalizations.of(context).settingsLanguage,
              onTap: () => context.push(KolabingRoutes.language),
            ),

            const SizedBox(height: KolabingSpacing.lg),

            // Sign Out Button
            GlassButton(
              label: AppLocalizations.of(context).businessProfileSignOut,
              onPressed: isUpdating ? null : _handleSignOut,
              intent: GlassButtonIntent.destructive,
              icon: LucideIcons.logOut,
            ),

            const SizedBox(height: KolabingSpacing.md),

            // Delete Account
            GestureDetector(
              onTap: isUpdating ? null : _handleDeleteAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.xs,
                ),
                child: Text(
                  AppLocalizations.of(context).businessProfileDeleteAccount,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: isUpdating
                        ? context.colors.textTertiary
                        : context.colors.error,
                    decoration: TextDecoration.underline,
                    decorationColor: isUpdating
                        ? context.colors.textTertiary
                        : context.colors.error,
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
        color: isDark ? context.colors.darkSurface : context.colors.surface,
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
                Icon(titleIcon, size: 20, color: context.colors.primary),
                const SizedBox(width: KolabingSpacing.xs),
              ],
              Text(
                title,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface,
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
  const _ContactInfoTile({required this.icon, required this.label, this.onTap});

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
                  ? context.colors.textOnDark.withValues(alpha: 0.6)
                  : context.colors.textTertiary,
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: onTap != null
                      ? context.colors.info
                      : isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                LucideIcons.externalLink,
                size: 16,
                color: isDark
                    ? context.colors.textOnDark.withValues(alpha: 0.6)
                    : context.colors.textTertiary,
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
                        ? context.colors.textOnDark
                        : context.colors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: isUpdating ? null : onChanged,
                activeThumbColor: context.colors.primary,
                activeTrackColor: context.colors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
