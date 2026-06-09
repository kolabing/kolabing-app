import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/gallery/public_gallery_section.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event/widgets/past_events_section.dart';
import '../../opportunity/models/opportunity.dart';
import '../../subscription/widgets/subscription_paywall.dart';
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
    final viewer = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: profileAsync.when(
        loading: () =>
            _buildWithOptimisticHeader(context, body: _buildLoadingBody(context)),
        error: (error, _) => _buildWithOptimisticHeader(
          context,
          body: _buildErrorBody(context, ref, error.toString()),
        ),
        data: (profile) => _buildProfileContent(context, profile),
      ),
      // C9: business viewing a community → primary CTA to send a Kolab proposal.
      // Until then the user could only "Not right now" out of this screen.
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (profile) {
          final shouldShowCta =
              viewer != null && viewer.isBusiness && profile.isCommunity;
          if (!shouldShowCta) return const SizedBox.shrink();
          return _SendKolabBottomBar(community: profile);
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Full profile content
  // ---------------------------------------------------------------------------

  Widget _buildProfileContent(BuildContext context, PublicProfile profile) =>
      CustomScrollView(
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
                    title: AppLocalizations.of(context).publicProfileAbout,
                    child: Text(
                      profile.about!,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: context.colors.onSurfaceVariant,
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

                // Past Events
                PastEventsSection(profileId: profileId),
                const SizedBox(height: KolabingSpacing.md),

                // Past collaborations
                _buildCollaborationsSection(context, profile),
                const SizedBox(height: KolabingSpacing.md),

                // Recent reviews
                if (profile.recentReviews.isNotEmpty) ...[
                  _RecentReviewsSection(profile: profile),
                  const SizedBox(height: KolabingSpacing.md),
                ],

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

  // ---------------------------------------------------------------------------
  // Optimistic header (shows creator info while loading full profile)
  // ---------------------------------------------------------------------------

  Widget _buildWithOptimisticHeader(
    BuildContext context, {
    required Widget body,
  }) => CustomScrollView(
    slivers: [
      SliverAppBar(
        expandedHeight: 160,
        pinned: true,
        backgroundColor: context.colors.primary,
        leading: const _BackButton(),
        flexibleSpace: FlexibleSpaceBar(
          background: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colors.primary,
                  context.colors.primary.withValues(alpha: 0.7),
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
                    ? _buildOptimisticHeaderContent(context)
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

  Widget _buildOptimisticHeaderContent(BuildContext context) {
    final cp = creatorProfile;
    if (cp == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        _AvatarWidget(avatarUrl: cp.avatarUrl, initial: cp.initial, size: 56),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cp.displayName,
                style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                cp.userType.toUpperCase(),
                style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: context.colors.onSurfaceVariant),
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

  Widget _buildLoadingBody(BuildContext context) => Shimmer.fromColors(
    baseColor: context.colors.surfaceVariant,
    highlightColor: context.colors.surface,
    child: Column(
      children: [
        _buildShimmerBlock(context, 80),
        const SizedBox(height: KolabingSpacing.md),
        _buildShimmerBlock(context, 120),
        const SizedBox(height: KolabingSpacing.md),
        _buildShimmerBlock(context, 100),
      ],
    ),
  );

  Widget _buildShimmerBlock(BuildContext context, double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: context.colors.surfaceContainer,
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
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              AppLocalizations.of(context).publicProfileLoadError,
              style: KolabingTextStyles.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(publicProfileProvider(profileId)),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(AppLocalizations.of(context).commonRetry),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Collaborations Section
  // ---------------------------------------------------------------------------

  Widget _buildCollaborationsSection(
    BuildContext context,
    PublicProfile profile,
  ) => _SectionCard(
    icon: LucideIcons.trophy,
    title: AppLocalizations.of(context).publicProfilePastKolabs,
    count: profile.kolabsCount,
    child: profile.hasCollaborations
        ? SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.pastCollaborations.length,
              separatorBuilder: (context, index) =>
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
                    color: context.colors.textTertiary,
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  Text(
                    AppLocalizations.of(context).publicProfileNoPastKolabs,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
  );

  // ---------------------------------------------------------------------------
  // Social Links Section
  // ---------------------------------------------------------------------------

  Widget _buildSocialLinksSection(
    BuildContext context,
    PublicProfile profile,
  ) => _SectionCard(
    icon: LucideIcons.link,
    title: AppLocalizations.of(context).publicProfileSocialLinks,
    child: Wrap(
      spacing: KolabingSpacing.sm,
      runSpacing: KolabingSpacing.sm,
      children: [
        if (profile.instagram != null && profile.instagram!.isNotEmpty)
          _SocialLinkChip(
            icon: LucideIcons.instagram,
            label: '@${profile.instagram}',
            onTap: () =>
                _launchUrl('https://instagram.com/${profile.instagram}'),
          ),
        if (profile.tiktok != null && profile.tiktok!.isNotEmpty)
          _SocialLinkChip(
            icon: LucideIcons.music,
            label: '@${profile.tiktok}',
            onTap: () => _launchUrl('https://tiktok.com/@${profile.tiktok}'),
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
    backgroundColor: context.colors.primary,
    leading: const _BackButton(),
    flexibleSpace: FlexibleSpaceBar(
      background: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.primary,
              context.colors.primary.withValues(alpha: 0.7),
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
                        style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: context.colors.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (profile.typeLabel != null)
                        Text(
                          profile.typeLabel!,
                          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: context.colors.onSurfaceVariant),
                        ),
                      if (profile.cityName != null &&
                          profile.cityName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: context.colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.cityName!,
                              style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant),
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
      child: SizedBox(
        width: 36,
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            size: 20,
            color: context.colors.onSurface,
          ),
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
    // `avatarUrl` is the ABSOLUTE logo URL returned by `PublicProfileResource`
    // (`avatar_url` / `logo_url` / `profile_photo`). On load failure or when
    // the profile has no logo, we fall back to the initial-letter circle.
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, error, stackTrace) =>
              _buildInitialCircle(context),
        ),
      );
    }
    return _buildInitialCircle(context);
  }

  Widget _buildInitialCircle(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.3),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        initial,
        style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
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
            Icon(icon, size: 20, color: context.colors.primary),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              title,
              style: KolabingTextStyles.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: KolabingSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: KolabingTextStyles.labelSmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                ),
              ),
            ],
            if (trailing != null) ...[const Spacer(), trailing!],
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
        color: context.colors.surfaceVariant,
        borderRadius: KolabingRadius.borderRadiusRound,
        border: Border.all(color: context.colors.darkBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w500, color: context.colors.onSurface),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// C9: Send Kolab proposal CTA — business viewing a community
// =============================================================================

class _SendKolabBottomBar extends ConsumerWidget {
  const _SendKolabBottomBar({required this.community});

  final PublicProfile community;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.sm,
        KolabingSpacing.md,
        KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.darkBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                AppLocalizations.of(context).publicProfileSaveForLater,
                style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final allowed = await SubscriptionPaywall.checkAndShow(
                    context,
                    ref,
                  );
                  if (!allowed || !context.mounted) {
                    return;
                  }

                  // Route to the Kolab create flow with the community
                  // pre-selected as the recipient. The flow reads the
                  // `recipient_community_id` query param.
                  await context.push(
                    '${KolabingRoutes.kolabNew}'
                    '?recipient_community_id=${Uri.encodeComponent(community.id)}',
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.send, size: 18),
                label: Text(
                  AppLocalizations.of(context).publicProfileSendKolabProposal,
                  style: KolabingTextStyles.button.copyWith(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// Review Reputation Card
// =============================================================================

class _RecentReviewsSection extends StatelessWidget {
  const _RecentReviewsSection({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.star_rounded,
      title: AppLocalizations.of(context).publicProfileRecentReviews,
      trailing: TextButton(
        onPressed: () => context.push(
          '/profile/${profile.id}/reviews',
          extra: profile.displayName,
        ),
        child: Text(AppLocalizations.of(context).publicProfileViewMore),
      ),
      child: Column(
        children: [
          for (var i = 0; i < profile.recentReviews.length; i++) ...[
            _PublicProfileReviewCard(review: profile.recentReviews[i]),
            if (i != profile.recentReviews.length - 1)
              const SizedBox(height: KolabingSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PublicProfileReviewCard extends StatelessWidget {
  const _PublicProfileReviewCard({required this.review});

  final PublicProfileReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarWidget(
                avatarUrl: review.reviewer.avatarUrl,
                initial: review.reviewer.initial,
                size: 36,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer.displayName,
                      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                    ),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (review.hasBody) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              review.body!,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatReviewDate(DateTime? date) {
  if (date == null) {
    return '';
  }

  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
}
