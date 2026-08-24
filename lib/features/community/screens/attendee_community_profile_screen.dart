import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../event/providers/event_provider.dart';
import '../models/community.dart';
import '../models/community_membership.dart';
import '../providers/community_follow_provider.dart';
import '../providers/community_providers.dart';
import '../widgets/community_application_sheet.dart';
import '../widgets/community_page_sections.dart';
import 'community_detail_screen.dart';

/// Attendee-facing community profile, keyed by **community id**.
///
/// Opened when an attendee taps the host-community row on an event detail. Unlike
/// the business-shaped [PublicProfileScreen] (which is profile-id-keyed and shows
/// Past Kolabs / Send-Kolab), this fetches the REAL community via
/// `GET /communities/{id}` + its upcoming events via `GET /events?community_id=`
/// and offers a state-aware join CTA. "See all →" routes to the events sub-tab
/// in [CommunityDetailScreen] via [_eventsTabIndex].
class AttendeeCommunityProfileScreen extends ConsumerWidget {
  const AttendeeCommunityProfileScreen({super.key, required this.communityId});

  final String communityId;

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
          await ref
              .read(communityUpcomingEventsProvider(community.id).notifier)
              .reload();
        },
        child: CustomScrollView(
          slivers: [
            // Cover band + logo tile.
            SliverToBoxAdapter(
              child: CommunityCoverHero(
                name: community.name,
                avatarUrl: community.avatarUrl,
              ),
            ),

            // Name, about, type · members.
            SliverToBoxAdapter(child: _Identity(community: community)),

            // Where the viewer stands, when they stand anywhere: a member can
            // step into the community, a pending request says so. Everyone else
            // is asked by the bottom CTA instead, so no row.
            SliverToBoxAdapter(child: _MembershipRow(community: community)),

            // Everything coming up, grouped by day.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  0,
                ),
                child: _UpcomingEventsSection(community: community),
              ),
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
  /// (member view) for "Open community".
  static void openCommunityDetail(BuildContext context, Community community) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityDetailScreen(
          membership: CommunityMembership(community: community),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Identity — name · about · type and member count
// -----------------------------------------------------------------------------

class _Identity extends ConsumerWidget {
  const _Identity({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Dynamic 17-slug label (never the placeholder enum). Falls back to a
    // generic label while the taxonomy loads or for an unknown slug.
    final typeLabel =
        ref.watch(communityTypeLabelProvider(community.typeSlug)) ??
        l10n.attendeeCommunityProfileTypeFallback;

    return CommunityIdentityBlock(
      name: community.name,
      description: community.description,
      metaText: l10n.communityDetailTypeAndMembers(
        typeLabel,
        community.memberCount ?? 0,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Membership row
// -----------------------------------------------------------------------------

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (community.isMember ?? false) {
      return CommunityNavRow(
        icon: LucideIcons.badgeCheck,
        title: community.name,
        subtitle: l10n.attendeeCommunityProfileOpenCommunity,
        iconColor: context.colors.success,
        onTap: () => AttendeeCommunityProfileScreen.openCommunityDetail(
          context,
          community,
        ),
      );
    }
    if (community.hasPendingJoinRequest) {
      return CommunityNavRow(
        icon: LucideIcons.clock,
        title: community.name,
        subtitle: l10n.attendeeCommunityProfileRequested,
        iconColor: context.colors.warning,
      );
    }
    // No relationship yet — the bottom CTA does the asking.
    return const SizedBox.shrink();
  }
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
// Upcoming events — cards (tap → event detail) + "See all →"
// -----------------------------------------------------------------------------

class _UpcomingEventsSection extends ConsumerWidget {
  const _UpcomingEventsSection({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityUpcomingEventsProvider(community.id));
    final typeLabel = ref.watch(communityTypeLabelProvider(community.typeSlug));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunitySectionLabel(l10n.attendeeCommunityProfileUpcomingEventsTitle),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(KolabingSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(color: KolabingColors.primary),
            ),
          ),
          // A backend without the events filter (or none) → friendly empty,
          // never a scary error.
          error: (_, _) => _empty(l10n),
          data: (events) {
            if (events.isEmpty) return _empty(l10n);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (typeLabel != null)
                  CommunityTagChip(label: typeLabel, count: events.length),
                CommunityEventTimeline(
                  events: events,
                  onOpen: (event) => context.push('/event/${event.id}'),
                  // Members-only and tier events are visible but shut until the
                  // viewer joins — say so instead of opening a 403.
                  onLocked: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.communityDetailEventLockedSnack),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
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
    // The leader-owned Community model does not expose social handles today, so
    // this section self-gates to nothing. Kept as a seam: when the backend adds
    // website/instagram/tiktok to `GET /communities/{id}`, wire them here.
    return const SizedBox.shrink();
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

  /// Follow / unfollow — one tap, no approval. This is the low-commitment
  /// relationship: it puts the community's events in your feed and nothing
  /// more. Membership is the separate, deliberate step below (#138).
  Future<void> _toggleFollow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final follows = ref.read(communityFollowsProvider.notifier);
    final wasFollowing = follows.isFollowing(_c.id);

    final ok = wasFollowing
        ? await follows.unfollow(_c.id)
        : await follows.follow(_c.id);

    if (!mounted) return;
    setState(() => _busy = false);
    _snack(
      !ok
          ? l10n.communityFollowFailed
          : wasFollowing
          ? l10n.communityUnfollowedSnack
          : l10n.communityFollowedSnack,
    );
  }

  /// Become a member. Asks the community's questions if it has any, and joins
  /// straight away if it does not — the leader's choice, not ours.
  Future<void> _becomeMember() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);

    final outcome = await CommunityApplicationSheet.run(
      context,
      ref,
      community: _c,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case MembershipOutcome.joined:
        ref
            .read(communityByIdProvider(_c.id).notifier)
            .setCommunity(_c.copyWith(isMember: true));
        await ref.read(communityByIdProvider(_c.id).notifier).reload();
        // Joining now follows too (#146); reload so nothing offers a Follow
        // button for a community they already belong to.
        await ref.read(communityFollowsProvider.notifier).reload();
        if (mounted) _snack(l10n.communityApplicationJoinedSnack);
      case MembershipOutcome.pending:
        ref
            .read(communityByIdProvider(_c.id).notifier)
            .setCommunity(_c.copyWith(myJoinRequestStatus: 'pending'));
        await ref.read(communityByIdProvider(_c.id).notifier).reload();
        if (mounted) _snack(l10n.communityApplicationSentSnack);
      case MembershipOutcome.failed:
        _snack(l10n.communityApplicationFailed);
      case MembershipOutcome.dismissed:
        break;
    }
  }

  void _openCommunity() =>
      AttendeeCommunityProfileScreen.openCommunityDetail(context, _c);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Member and pending states are terminal — one button each. Everyone else
    // gets BOTH relationships offered: Follow (one tap) and Become a member
    // (the deliberate step). They are different commitments, so they are
    // different buttons rather than one CTA that guesses (#138).
    final isMember = _c.isMember ?? false;
    final pending = _c.hasPendingJoinRequest;
    final isFollowing = ref.watch(communityFollowsProvider).contains(_c.id);

    final Widget content;

    if (isMember) {
      content = _cta(
        label: l10n.attendeeCommunityProfileOpenCommunity,
        icon: LucideIcons.arrowRight,
        onTap: _openCommunity,
        filled: false,
      );
    } else if (pending) {
      content = _cta(
        label: l10n.attendeeCommunityProfileRequested,
        icon: LucideIcons.clock,
        onTap: null, // disabled while the leader decides
        filled: true,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cta(
            label: isFollowing ? l10n.communityFollowing : l10n.communityFollow,
            icon: isFollowing ? LucideIcons.check : LucideIcons.plus,
            onTap: _toggleFollow,
            // Following is the state, not the invitation — so once following,
            // the button stops shouting.
            filled: !isFollowing,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _cta(
            label: l10n.communityBecomeMember,
            icon: LucideIcons.userPlus,
            onTap: _becomeMember,
            filled: isFollowing,
          ),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: content,
      ),
    );
  }

  Widget _cta({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool filled,
  }) {
    final labelWidget = Text(
      label,
      style: KolabingTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    return filled
        ? FilledButton.icon(
            onPressed: _busy ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              minimumSize: const Size(double.infinity, 52),
            ),
            icon: _busyOrIcon(icon),
            label: labelWidget,
          )
        : OutlinedButton.icon(
            onPressed: _busy ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.onSurface,
              side: const BorderSide(color: KolabingColors.primary),
              minimumSize: const Size(double.infinity, 52),
            ),
            icon: _busyOrIcon(icon),
            label: labelWidget,
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
