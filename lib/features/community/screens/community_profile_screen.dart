import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/gallery/profile_gallery_section.dart';
import '../../../widgets/glass_button.dart';
import '../../auth/models/user_model.dart';
import '../../business/models/notification_preferences.dart';
import '../../business/providers/profile_provider.dart';
import '../../event/widgets/past_events_section.dart';
import '../models/verification_channel.dart';
import '../widgets/public_channels_row.dart';
import '../widgets/verification_channel_repeater.dart';
import '../providers/community_providers.dart';
import '../../rewards/providers/wallet_provider.dart';
import '../../../widgets/verified_tick.dart';

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
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.communityProfileSignOutTitle),
          content: Text(l10n.communityProfileSignOutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              child: Text(l10n.communityProfileSignOutConfirm),
            ),
          ],
        );
      },
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
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.communityProfileDeleteAccountTitle),
          content: Text(l10n.communityProfileDeleteAccountBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              child: Text(l10n.communityProfileDeleteAccountConfirm),
            ),
          ],
        );
      },
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
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
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
                  l10n.communityProfileChangePhotoTitle,
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
                  title: Text(l10n.communityProfileTakePhoto),
                  subtitle: Text(l10n.communityProfileTakePhotoSubtitle),
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
                  title: Text(l10n.communityProfileChooseFromGallery),
                  subtitle: Text(
                    l10n.communityProfileChooseFromGallerySubtitle,
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],
            ),
          ),
        );
      },
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
                  AppLocalizations.of(context).communityProfileUploadingPhoto,
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

      if (success) {
        // Same image: the backend mirrored the photo to communities.avatar_url,
        // so reload the community providers and the hub/detail/my-communities
        // avatars match immediately.
        ref.read(communityManageProvider.notifier).reloadCommunities();
        ref.read(myMembershipsProvider.notifier).reload();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).communityProfilePhotoUpdated,
              ),
              backgroundColor: context.colors.success,
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).communityProfilePhotoUpdateFailed(e.toString()),
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
              label: AppLocalizations.of(context).communityProfileDismiss,
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
        AppLocalizations.of(context).communityProfileLoadFailed,
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

  Widget _buildErrorState(String error, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Center(
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
              l10n.communityProfileErrorTitle,
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
              label: l10n.communityProfileTryAgain,
              onPressed: () => ref.read(profileProvider.notifier).loadProfile(),
              intent: GlassButtonIntent.primary,
              icon: LucideIcons.rotateCcw,
            ),
          ],
        ),
      ),
    );
  }

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

                  // Compact Contact & links (merges contact + channels). Sits right
                  // under the header, above gallery / past-events.
                  _buildContactAndLinks(profile, state.isUpdating, isDark),

                  const SizedBox(height: KolabingSpacing.md),

                  // About Section
                  if (hasAbout) ...[
                    _buildAboutSection(about, isDark),
                    const SizedBox(height: KolabingSpacing.md),
                  ],

                  // Community details (editable: community size)
                  _buildCommunityDetailsSection(
                    profile,
                    state.isUpdating,
                    isDark,
                  ),

                  const SizedBox(height: KolabingSpacing.md),

                  // Gallery Section
                  const ProfileGallerySection(),

                  const SizedBox(height: KolabingSpacing.md),

                  // Past Events Section
                  const PastEventsSection(),

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
              color: context.colors.onSurface,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildProfileHeader(UserModel profile, bool isUpdating, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final name = profile.communityProfile?.name ?? profile.displayName;
    final communityType =
        profile.communityProfile?.communityTypeLabel ??
        l10n.communityProfileCommunityFallback;
    final photoUrl =
        profile.communityProfile?.profilePhoto ?? profile.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.hairline),
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

          // Name (+ verified tick when verified)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: KolabingTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? context.colors.textOnDark
                        : context.colors.onSurface,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (profile.communityProfile?.isVerified ?? false) ...[
                const SizedBox(width: KolabingSpacing.xs),
                const VerifiedTick(isVerified: true, size: 18),
              ],
            ],
          ),

          const SizedBox(height: KolabingSpacing.xs),

          // Community type badge — slate palette
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.colors.info.withValues(alpha: 0.1),
              borderRadius: KolabingRadius.borderRadiusRound,
              border: Border.all(
                color: context.colors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              communityType,
              style: KolabingTextStyles.labelSmall.copyWith(
                color: context.colors.info,
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
                  color: context.colors.softYellow,
                  borderRadius: KolabingRadius.borderRadiusRound,
                  border: Border.all(color: context.colors.softYellowBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shield, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      l10n.communityProfileLevelChip(
                        level.number,
                        level.title,
                        wallet.totalXp,
                      ),
                      style: KolabingTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
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
    title: AppLocalizations.of(context).communityProfileAboutSection,
    child: Text(
      about,
      style: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildCommunityDetailsSection(
    UserModel profile,
    bool isUpdating,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    final size = profile.communityProfile?.communitySize;
    final sizeLabel = size != null ? '$size' : l10n.communityProfileSizeNotSet;

    return _SectionCard(
      title: l10n.communityProfileDetailsSection,
      child: InkWell(
        onTap: isUpdating ? null : () => _handleEditCommunitySize(size),
        borderRadius: KolabingRadius.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
          child: Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 20,
                color: isDark
                    ? context.colors.textOnDark.withValues(alpha: 0.6)
                    : context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.communityInfoCommunitySizeLabel,
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: context.colors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sizeLabel,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? context.colors.textOnDark
                            : context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.pencil,
                size: 16,
                color: isDark
                    ? context.colors.textOnDark.withValues(alpha: 0.6)
                    : context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditCommunitySize(int? current) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: current != null ? '$current' : '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.communityInfoCommunitySizeLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.communityStep1SizeHelper,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.communityInfoCommunitySizeHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(int.tryParse(controller.text.trim()) ?? -1),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    controller.dispose();

    // Dialog dismissed without saving.
    if (result == null) return;
    // -1 sentinel means the field was left empty / invalid; ignore.
    if (result < 0) return;

    await ref.read(profileProvider.notifier).updateProfile({
      'community_size': result,
    });
  }

  /// Compact "Contact & links" card: the public-icons row + a Manage button
  /// (owner). Merges the old buried Contact Info + Verification sections.
  Widget _buildContactAndLinks(
    UserModel profile,
    bool isUpdating,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    final cp = profile.communityProfile;
    final publicChannels = cp?.publicChannels ?? const <VerificationChannel>[];

    final isVerified = cp?.isVerified ?? false;

    return _SectionCard(
      title: l10n.contactAndLinksTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVerified) ...[
            Row(
              children: [
                const VerifiedTick(isVerified: true, size: 16),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  l10n.verificationStatusVerified,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.sm),
          ],
          if (publicChannels.isEmpty)
            Text(
              l10n.contactAndLinksEmptyOwner,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else
            PublicChannelsRow(channels: publicChannels, verified: isVerified),
          const SizedBox(height: KolabingSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isUpdating ? null : () => _openManageSheet(profile),
              icon: const Icon(LucideIcons.settings2, size: 18),
              label: Text(l10n.contactAndLinksManage),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManageSheet(UserModel profile) async {
    final cp = profile.communityProfile;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ManageContactSheet(
        isVerified: cp?.isVerified ?? false,
        verificationStatus: cp?.verificationStatus,
        rejectionReason: cp?.verificationRejectionReason,
        initialChannels: cp?.verificationChannels ?? const [],
        onSave: (channels) async {
          await ref.read(profileProvider.notifier).updateProfile({
            'verification_channels': channels.map((c) => c.toJson()).toList(),
          });
        },
      ),
    );
  }

  Widget _buildNotificationPreferencesSection(
    NotificationPreferences? preferences,
    bool isUpdating,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.communityProfileNotificationsSection,
      child: Column(
        children: [
          _NotificationToggle(
            label: l10n.communityProfileNotifMessages,
            value: preferences?.messagesEnabled ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('messages_enabled', value),
          ),
          _NotificationToggle(
            label: l10n.communityProfileNotifApplications,
            value: preferences?.applicationsEnabled ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('applications_enabled', value),
          ),
          _NotificationToggle(
            label: l10n.communityProfileNotifKolabUpdates,
            value: preferences?.collaborationsEnabled ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('collaborations_enabled', value),
          ),
          _NotificationToggle(
            label: l10n.communityProfileNotifRewards,
            value: preferences?.rewardsEnabled ?? true,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('rewards_enabled', value),
          ),
          _NotificationToggle(
            label: l10n.communityProfileNotifMarketing,
            value: preferences?.marketingEnabled ?? false,
            isUpdating: isUpdating,
            onChanged: (value) => ref
                .read(profileProvider.notifier)
                .updateNotificationPreference('marketing_enabled', value),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(String email, bool isUpdating, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.communityProfileAccountSection,
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
                    ? context.colors.textOnDark.withValues(alpha: 0.6)
                    : context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  email,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? context.colors.textOnDark
                        : context.colors.onSurface,
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

          const SizedBox(height: KolabingSpacing.sm),

          // Notification preferences
          _ContactInfoTile(
            icon: LucideIcons.bell,
            label: AppLocalizations.of(context).notifSettingsTitle,
            onTap: () => context.push(KolabingRoutes.notificationSettings),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Sign Out Button
          GlassButton(
            label: l10n.communityProfileSignOutButton,
            onPressed: isUpdating ? null : _handleSignOut,
            intent: GlassButtonIntent.destructive,
            icon: LucideIcons.logOut,
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Delete Account
          GestureDetector(
            onTap: isUpdating ? null : _handleDeleteAccount,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
              child: Text(
                l10n.communityProfileDeleteAccountLink,
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
}

// -----------------------------------------------------------------------------
// Section Card Wrapper
// -----------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: KolabingTextStyles.labelLarge.copyWith(
              color: context.colors.textTertiary,
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

// -----------------------------------------------------------------------------
// Manage Contact & links sheet (owner): Contact + Channels groups, each row a
// type + value + public eye toggle, plus a verification status line + Save.
// -----------------------------------------------------------------------------

class _ManageContactSheet extends StatefulWidget {
  const _ManageContactSheet({
    required this.isVerified,
    required this.verificationStatus,
    required this.rejectionReason,
    required this.initialChannels,
    required this.onSave,
  });

  final bool isVerified;
  final String? verificationStatus;
  final String? rejectionReason;
  final List<VerificationChannel> initialChannels;
  final Future<void> Function(List<VerificationChannel>) onSave;

  @override
  State<_ManageContactSheet> createState() => _ManageContactSheetState();
}

class _ManageContactSheetState extends State<_ManageContactSheet> {
  // Two partitions: contact (email/phone) and channels (the rest).
  late List<VerificationChannel> _contact;
  late List<VerificationChannel> _channels;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.initialChannels
        .where((c) => c.type.isContact)
        .toList(growable: true);
    _channels = widget.initialChannels
        .where((c) => !c.type.isContact)
        .toList(growable: true);
  }

  /// Merged, validated, trimmed channels (min 1 channel required for
  /// verification is enforced by the repeater floor on the channels group).
  List<VerificationChannel> get _validChannels => [..._contact, ..._channels]
      .where((c) => isValidChannelValue(c.type, c.url))
      .map((c) => c.copyWith(url: c.url.trim()))
      .toList(growable: false);

  ({String label, Color color}) _status(AppLocalizations l10n) {
    if (widget.isVerified) {
      return (
        label: l10n.verificationStatusVerified,
        color: KolabingColors.activeText,
      );
    }
    final status = widget.verificationStatus?.toLowerCase();
    if (status == 'pending' || status == 'in_review') {
      return (
        label: l10n.verificationStatusPending,
        color: context.colors.onSurfaceVariant,
      );
    }
    if (status == 'rejected') {
      return (
        label: l10n.verificationStatusRejected,
        color: context.colors.error,
      );
    }
    return (
      label: l10n.verificationStatusUnverified,
      color: context.colors.onSurfaceVariant,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_validChannels);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _status(l10n);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: KolabingSpacing.md,
          right: KolabingSpacing.md,
          top: KolabingSpacing.md,
          bottom: KolabingSpacing.md + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                l10n.contactAndLinksTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                l10n.verificationStepSubtitle,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Status line
              Row(
                children: [
                  if (widget.isVerified) ...[
                    const VerifiedTick(isVerified: true),
                    const SizedBox(width: KolabingSpacing.sm),
                  ],
                  Text(
                    status.label,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (widget.verificationStatus?.toLowerCase() == 'rejected' &&
                  (widget.rejectionReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  widget.rejectionReason!,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
              const SizedBox(height: KolabingSpacing.lg),

              // Contact group (email / phone)
              Text(
                l10n.contactAndLinksContactGroup,
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: context.colors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              VerificationChannelRepeater(
                channels: _contact,
                showLabel: false,
                showPublicToggle: true,
                allowedTypes: const [
                  VerificationChannelType.email,
                  VerificationChannelType.phone,
                ],
                onChanged: (next) => setState(() => _contact = next),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Channels group (the rest)
              Text(
                l10n.contactAndLinksChannelsGroup,
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: context.colors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              VerificationChannelRepeater(
                channels: _channels,
                showLabel: false,
                showPublicToggle: true,
                minChannels: 1,
                allowedTypes: const [
                  VerificationChannelType.instagram,
                  VerificationChannelType.strava,
                  VerificationChannelType.whatsapp,
                  VerificationChannelType.telegram,
                  VerificationChannelType.flaire,
                  VerificationChannelType.skool,
                  VerificationChannelType.tiktok,
                  VerificationChannelType.website,
                ],
                onChanged: (next) => setState(() => _channels = next),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(elevation: 0),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
