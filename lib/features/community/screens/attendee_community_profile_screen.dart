import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../event/widgets/event_card.dart';
import '../../../widgets/verified_tick.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../providers/community_providers.dart';
import '../widgets/public_channels_row.dart';
import '../services/community_service.dart';
import 'community_detail_screen.dart';

/// Attendee-facing community profile, keyed by **community id**.
///
/// Opened when an attendee taps the host-community row on an event detail. Unlike
/// the business-shaped [PublicProfileScreen] (which is profile-id-keyed and shows
/// Past Kolabs / Send-Kolab), this fetches the REAL community via
/// `GET /communities/{id}` + its upcoming events via `GET /events?community_id=`
/// and offers a state-aware join CTA. Index of the events sub-tab in
/// [CommunityDetailScreen] is 2 — "See all →" routes there.
class AttendeeCommunityProfileScreen extends ConsumerWidget {
  const AttendeeCommunityProfileScreen({super.key, required this.communityId});

  final String communityId;

  /// Events sub-tab index inside [CommunityDetailScreen] (Rewards·Members·Events).
  static const int _eventsTabIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityByIdProvider(communityId));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: async.when(
        loading: _buildLoading,
        error: (error, _) => _buildError(context, ref, error.toString()),
        data: (community) => _buildContent(context, ref, l10n, community),
      ),
    );
  }

  Widget _buildLoading() => const Center(
    child: CircularProgressIndicator(color: KolabingColors.primary),
  );

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _BackButton()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    size: 40,
                    color: KolabingColors.error,
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Text(
                    l10n.attendeeCommunityProfileErrorTitle,
                    style: KolabingTextStyles.titleMedium.copyWith(
                      color: KolabingColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(communityByIdProvider(communityId).notifier)
                        .reload(),
                    icon: const Icon(LucideIcons.rotateCcw, size: 18),
                    label: Text(l10n.commonRetry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KolabingColors.primary,
                      foregroundColor: KolabingColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Community community,
  ) {
    return Scaffold(
      backgroundColor: KolabingColors.background,
      // State-aware sticky bottom CTA.
      bottomNavigationBar: _JoinCtaBar(community: community),
      body: RefreshIndicator(
        color: KolabingColors.primary,
        onRefresh: () async {
          await ref.read(communityByIdProvider(community.id).notifier).reload();
          ref
              .read(communityUpcomingEventsProvider(community.id).notifier)
              .reload();
        },
        child: CustomScrollView(
          slivers: [
            // Header band + avatar.
            SliverToBoxAdapter(child: _Header(community: community)),

            // About.
            if (community.description != null &&
                community.description!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KolabingSpacing.md,
                    KolabingSpacing.lg,
                    KolabingSpacing.md,
                    0,
                  ),
                  child: _AboutSection(about: community.description!),
                ),
              ),

            // Upcoming events.
            SliverToBoxAdapter(
              child: _UpcomingEventsSection(community: community),
            ),

            // Social links.
            SliverToBoxAdapter(child: _SocialLinks(community: community)),

            const SliverToBoxAdapter(
              child: SizedBox(height: KolabingSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the membership wrapper so we can reuse [CommunityDetailScreen]
  /// (member view) for "See all →" and "Open community".
  static void openCommunityDetail(
    BuildContext context,
    Community community, {
    int initialTabIndex = 0,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityDetailScreen(
          membership: CommunityMembership(community: community),
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header — cover/brand band + avatar + name · type · city · member count
// -----------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Dynamic 17-slug label (never the placeholder enum). Falls back to a
    // generic label while the taxonomy loads or for an unknown slug.
    final typeLabel =
        ref.watch(communityTypeLabelProvider(community.typeSlug)) ??
        l10n.attendeeCommunityProfileTypeFallback;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Brand band.
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KolabingColors.primary, KolabingColors.softYellow],
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          child: SafeArea(child: _BackButton()),
        ),
        // Avatar + identity.
        Padding(
          padding: const EdgeInsets.only(top: 102),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: KolabingColors.surface, width: 4),
                  color: KolabingColors.surface,
                ),
                child: ClipOval(
                  child: community.avatarUrl != null
                      ? Image.network(
                          community.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarPlaceholder(community.name),
                        )
                      : _avatarPlaceholder(community.name),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        community.name,
                        textAlign: TextAlign.center,
                        style: KolabingTextStyles.headlineMedium.copyWith(
                          color: KolabingColors.onSurface,
                        ),
                      ),
                    ),
                    if (community.isVerified) ...[
                      const SizedBox(width: KolabingSpacing.xs),
                      const VerifiedTick(isVerified: true, size: 20),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              // Type · city.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: KolabingColors.info.withValues(alpha: 0.1),
                  borderRadius: KolabingRadius.borderRadiusRound,
                  border: Border.all(
                    color: KolabingColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  typeLabel,
                  style: KolabingTextStyles.labelSmall.copyWith(
                    color: KolabingColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              // Member count.
              Text(
                l10n.attendeeCommunityProfileMemberCount(
                  community.memberCount ?? 0,
                ),
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(String name) => Container(
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
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KolabingSpacing.sm),
    child: IconButton(
      onPressed: () => context.pop(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// About
// -----------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.about});

  final String about;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
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
        children: [
          Text(
            l10n.attendeeCommunityProfileAboutTitle,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            about,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Upcoming events — cards (tap → event detail) + "See all →"
// -----------------------------------------------------------------------------

class _UpcomingEventsSection extends ConsumerWidget {
  const _UpcomingEventsSection({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityUpcomingEventsProvider(community.id));

    return Padding(
      padding: const EdgeInsets.only(top: KolabingSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.attendeeCommunityProfileUpcomingEventsTitle,
                  style: KolabingTextStyles.titleMedium.copyWith(
                    color: KolabingColors.onSurface,
                  ),
                ),
                // "See all →" routes to the community detail Events sub-tab.
                async.maybeWhen(
                  data: (events) => events.isEmpty
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () =>
                              AttendeeCommunityProfileScreen.openCommunityDetail(
                                context,
                                community,
                                initialTabIndex: AttendeeCommunityProfileScreen
                                    ._eventsTabIndex,
                              ),
                          child: Text(l10n.attendeeCommunityProfileSeeAll),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(KolabingSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(color: KolabingColors.primary),
              ),
            ),
            // A backend without the events filter (or none) → friendly empty,
            // never a scary error (same pattern as community detail Events).
            error: (_, __) => _empty(l10n),
            data: (events) {
              if (events.isEmpty) return _empty(l10n);
              // Show the next few; full list lives behind "See all".
              final shown = events.take(5).toList();
              return SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                  ),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: KolabingSpacing.sm),
                  itemBuilder: (_, i) => EventCard(
                    event: shown[i],
                    onTap: () => _openEvent(context, shown[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openEvent(BuildContext context, Event event) =>
      context.push('/event/${event.id}');

  Widget _empty(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.md,
      vertical: KolabingSpacing.lg,
    ),
    child: Row(
      children: [
        const Icon(
          LucideIcons.calendar,
          size: 20,
          color: KolabingColors.onSurfaceVariant,
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            l10n.attendeeCommunityProfileNoUpcomingEvents,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

// -----------------------------------------------------------------------------
// Social links (only what the community payload carries today: website/socials
// are not on the Community model, so we render nothing unless present).
// -----------------------------------------------------------------------------

class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    // Public contact/links the community chose to expose (`public_channels`).
    // Same row a business sees and the owner sees — tap → open the link.
    final channels = community.publicChannels;
    if (channels.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.lg,
        KolabingSpacing.md,
        0,
      ),
      child: Container(
        width: double.infinity,
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
          children: [
            Text(
              l10n.contactAndLinksTitle,
              style: KolabingTextStyles.titleMedium.copyWith(
                color: KolabingColors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            PublicChannelsRow(channels: channels, verified: community.isVerified),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// State-aware sticky bottom CTA
// -----------------------------------------------------------------------------

class _JoinCtaBar extends ConsumerStatefulWidget {
  const _JoinCtaBar({required this.community});

  final Community community;

  @override
  ConsumerState<_JoinCtaBar> createState() => _JoinCtaBarState();
}

class _JoinCtaBarState extends ConsumerState<_JoinCtaBar> {
  bool _busy = false;

  Community get _c => widget.community;

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _join() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(communityServiceProvider).joinCommunity(_c.id);
      // Flip CTA → member, optimistically and via a refetch.
      ref
          .read(communityByIdProvider(_c.id).notifier)
          .setCommunity(_c.copyWith(isMember: true));
      await ref.read(communityByIdProvider(_c.id).notifier).reload();
      if (mounted) _snack(l10n.attendeeCommunityProfileJoinedSnack);
    } on CommunityException catch (e) {
      // Invite-only → fall back to request flow.
      if (e.isInviteOnly) {
        await _requestToJoin();
        return;
      }
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestToJoin() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(communityServiceProvider).requestToJoin(_c.id);
      ref
          .read(communityByIdProvider(_c.id).notifier)
          .setCommunity(_c.copyWith(myJoinRequestStatus: 'pending'));
      await ref.read(communityByIdProvider(_c.id).notifier).reload();
      if (mounted) _snack(l10n.attendeeCommunityProfileRequestedSnack);
    } on CommunityException catch (e) {
      // Self-gated: endpoint not deployed yet → soft notice, no crash.
      if (e.code == 'request_unavailable') {
        if (mounted) _snack(l10n.attendeeCommunityProfileRequestUnavailable);
      } else {
        if (mounted) _snack(e.message);
      }
    } catch (e) {
      if (mounted) _snack(l10n.attendeeCommunityProfileRequestUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openCommunity() =>
      AttendeeCommunityProfileScreen.openCommunityDetail(context, _c);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Resolve the CTA state from join policy + membership + request status.
    final isMember = _c.isMember ?? false;
    final pending = _c.hasPendingJoinRequest;
    final inviteOnly = _c.joinPolicy == CommunityJoinPolicy.inviteOnly;

    final (
      String label,
      IconData icon,
      VoidCallback? onTap,
      bool filled,
    ) = switch (true) {
      _ when isMember => (
        l10n.attendeeCommunityProfileOpenCommunity,
        LucideIcons.arrowRight,
        _openCommunity,
        false,
      ),
      _ when pending => (
        l10n.attendeeCommunityProfileRequested,
        LucideIcons.clock,
        null, // disabled while pending
        true,
      ),
      _ when inviteOnly => (
        l10n.attendeeCommunityProfileRequestToJoin,
        LucideIcons.userPlus,
        _requestToJoin,
        true,
      ),
      _ => (
        l10n.attendeeCommunityProfileJoin,
        LucideIcons.userPlus,
        _join,
        true,
      ),
    };

    final button = filled
        ? FilledButton.icon(
            onPressed: _busy ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _busyOrIcon(icon),
            label: Text(
              label,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: _busy ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.onSurface,
              side: const BorderSide(color: KolabingColors.primary),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _busyOrIcon(icon),
            label: Text(
              label,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: button,
      ),
    );
  }

  Widget _busyOrIcon(IconData icon) => _busy
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(icon, size: 18);
}
