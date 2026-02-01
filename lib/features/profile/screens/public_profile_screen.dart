import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/gallery/public_gallery_section.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/public_profile.dart';
import '../providers/public_profile_provider.dart';
import '../widgets/past_collaboration_card.dart';

/// Public profile preview screen.
///
/// Displays another user's profile including:
/// - Header with avatar, name, type, city
/// - About section
/// - Gallery photos
/// - Past collaborations
/// - Social links
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    required this.profileId,
    this.creatorProfile,
    super.key,
  });

  /// The profile ID to load
  final String profileId;

  /// Optional pre-loaded creator profile for optimistic display
  final CreatorProfile? creatorProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(profileId));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: profileAsync.when(
        loading: () => _buildWithOptimisticHeader(
          context,
          body: _buildLoadingBody(),
        ),
        error: (error, _) => _buildWithOptimisticHeader(
          context,
          body: _buildErrorBody(context, ref, error.toString()),
        ),
        data: (profile) => _buildProfileContent(context, profile),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Full profile content
  // ---------------------------------------------------------------------------

  Widget _buildProfileContent(BuildContext context, PublicProfile profile) {
    return CustomScrollView(
      slivers: [
        // Hero header
        _ProfileSliverHeader(profile: profile),

        // Body sections
        SliverPadding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // About
              if (profile.hasAbout) ...[
                _SectionCard(
                  icon: LucideIcons.fileText,
                  title: 'About',
                  child: Text(
                    profile.about!,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: KolabingColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],

              // Gallery
              if (profile.hasGallery) ...[
                PublicGallerySection(photos: profile.gallery),
                const SizedBox(height: KolabingSpacing.md),
              ],

              // Past collaborations
              _buildCollaborationsSection(profile),
              const SizedBox(height: KolabingSpacing.md),

              // Social links
              if (profile.hasSocialLinks) ...[
                _buildSocialLinksSection(context, profile),
                const SizedBox(height: KolabingSpacing.md),
              ],

              // Bottom spacing
              const SizedBox(height: KolabingSpacing.xl),
            ]),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Optimistic header (shows creator info while loading full profile)
  // ---------------------------------------------------------------------------

  Widget _buildWithOptimisticHeader(
    BuildContext context, {
    required Widget body,
  }) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: KolabingColors.primary,
          leading: _BackButton(),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    KolabingColors.primary,
                    KolabingColors.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KolabingSpacing.md,
                    56,
                    KolabingSpacing.md,
                    KolabingSpacing.md,
                  ),
                  child: creatorProfile != null
                      ? _buildOptimisticHeaderContent()
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          sliver: SliverToBoxAdapter(child: body),
        ),
      ],
    );
  }

  Widget _buildOptimisticHeaderContent() {
    final cp = creatorProfile!;
    return Row(
      children: [
        _AvatarWidget(
          avatarUrl: cp.avatarUrl,
          initial: cp.initial,
          size: 56,
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cp.displayName,
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                cp.userType.toUpperCase(),
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Loading & Error
  // ---------------------------------------------------------------------------

  Widget _buildLoadingBody() => Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: Column(
          children: [
            _buildShimmerBlock(80),
            const SizedBox(height: KolabingSpacing.md),
            _buildShimmerBlock(120),
            const SizedBox(height: KolabingSpacing.md),
            _buildShimmerBlock(100),
          ],
        ),
      );

  Widget _buildShimmerBlock(double height) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KolabingRadius.borderRadiusLg,
        ),
      );

  Widget _buildErrorBody(BuildContext context, WidgetRef ref, String error) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              'Failed to load profile',
              style: KolabingTextStyles.titleMedium.copyWith(
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(publicProfileProvider(profileId)),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Collaborations Section
  // ---------------------------------------------------------------------------

  Widget _buildCollaborationsSection(PublicProfile profile) {
    return _SectionCard(
      icon: LucideIcons.trophy,
      title: 'Past Collaborations',
      count: profile.pastCollaborations.length,
      child: profile.hasCollaborations
          ? SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profile.pastCollaborations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: KolabingSpacing.sm),
                itemBuilder: (context, index) => PastCollaborationCard(
                  collaboration: profile.pastCollaborations[index],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 32,
                      color: KolabingColors.textTertiary,
                    ),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      'No past collaborations yet',
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Social Links Section
  // ---------------------------------------------------------------------------

  Widget _buildSocialLinksSection(
    BuildContext context,
    PublicProfile profile,
  ) {
    return _SectionCard(
      icon: LucideIcons.link,
      title: 'Social Links',
      child: Wrap(
        spacing: KolabingSpacing.sm,
        runSpacing: KolabingSpacing.sm,
        children: [
          if (profile.instagram != null && profile.instagram!.isNotEmpty)
            _SocialLinkChip(
              icon: LucideIcons.instagram,
              label: '@${profile.instagram}',
              onTap: () => _launchUrl(
                'https://instagram.com/${profile.instagram}',
              ),
            ),
          if (profile.tiktok != null && profile.tiktok!.isNotEmpty)
            _SocialLinkChip(
              icon: LucideIcons.music,
              label: '@${profile.tiktok}',
              onTap: () => _launchUrl(
                'https://tiktok.com/@${profile.tiktok}',
              ),
            ),
          if (profile.website != null && profile.website!.isNotEmpty)
            _SocialLinkChip(
              icon: LucideIcons.globe,
              label: profile.website!,
              onTap: () => _launchUrl(profile.website!),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// =============================================================================
// Profile Sliver Header
// =============================================================================

class _ProfileSliverHeader extends StatelessWidget {
  const _ProfileSliverHeader({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) => SliverAppBar(
        expandedHeight: 180,
        pinned: true,
        backgroundColor: KolabingColors.primary,
        leading: const _BackButton(),
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  KolabingColors.primary,
                  KolabingColors.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  56,
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                ),
                child: Row(
                  children: [
                    _AvatarWidget(
                      avatarUrl: profile.avatarUrl,
                      initial: profile.initial,
                      size: 64,
                    ),
                    const SizedBox(width: KolabingSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: GoogleFonts.rubik(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (profile.type != null && profile.type!.isNotEmpty)
                            Text(
                              profile.type!,
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: KolabingColors.textSecondary,
                              ),
                            ),
                          if (profile.cityName != null &&
                              profile.cityName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 12,
                                  color: KolabingColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.cityName!,
                                  style: GoogleFonts.openSans(
                                    fontSize: 13,
                                    color: KolabingColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// =============================================================================
// Back Button
// =============================================================================

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
      );
}

// =============================================================================
// Avatar Widget
// =============================================================================

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.initial,
    required this.size,
    this.avatarUrl,
  });

  final String? avatarUrl;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _buildInitialCircle(),
        ),
      );
    }
    return _buildInitialCircle();
  }

  Widget _buildInitialCircle() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.rubik(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
      );
}

// =============================================================================
// Section Card
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.count,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) => Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: KolabingColors.primary),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  title,
                  style: KolabingTextStyles.titleMedium.copyWith(
                    color: KolabingColors.textPrimary,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: KolabingSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: KolabingColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: KolabingSpacing.md),
            child,
          ],
        ),
      );
}

// =============================================================================
// Social Link Chip
// =============================================================================

class _SocialLinkChip extends StatelessWidget {
  const _SocialLinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: KolabingColors.surfaceVariant,
            borderRadius: KolabingRadius.borderRadiusRound,
            border: Border.all(
              color: KolabingColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: KolabingColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
}
