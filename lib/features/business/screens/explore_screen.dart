import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/explore_detail_sheet.dart';
import '../../../widgets/explore_filter_sheet.dart';
import '../../../widgets/explore_swipe_card.dart';
import '../../application/widgets/apply_modal.dart';
import '../../application/widgets/apply_success_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../discovery/models/discovery_filters.dart';
import '../../discovery/models/discovery_item.dart';
import '../../discovery/models/explore_feed_item.dart';
import '../../discovery/providers/discovery_provider.dart';
import '../../discovery/widgets/discovery_quick_filters.dart';
import '../../moderation/providers/blocked_profiles_provider.dart';
import '../../notification/widgets/notification_bell.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/saved_kolabs_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../widgets/opportunity_card.dart';

/// Vertical space reserved at the bottom of Explore's scrollables so the
/// create-Kolab FAB (56dp + margin) never covers card actions.
const double _fabClearance = 88;

/// The Explore deck's item filter, extracted so it can be unit-tested.
///
/// Applies to EVERY feed item type. Drops, in order: the viewer's own posts
/// (can't collaborate with yourself), posts by a blocked creator
/// ([blockedProfileIds] — App Review 1.2 instant client-side hide), and then
/// a per-type availability rule:
///
///  * ordinary Kolab offer — must still be open for applications by date;
///  * Multi-Kolab role — must be open, have a remaining position, and match
///    the viewer's feed (a Community role only reaches Community Explore, a
///    Business role only Business Explore, an `either` role both). This is
///    the single place that eligibility routing happens.
List<ExploreFeedItem> filterExploreDeckItems(
  List<ExploreFeedItem> items, {
  required Set<String> blockedProfileIds,
  required String? myProfileId,
  required DateTime today,
  required bool isCommunityViewer,
}) {
  return items.where((ExploreFeedItem item) {
    final creatorId = item.creatorProfileId;
    if (myProfileId != null &&
        myProfileId.isNotEmpty &&
        creatorId.isNotEmpty &&
        creatorId == myProfileId) {
      return false;
    }
    if (creatorId.isNotEmpty && blockedProfileIds.contains(creatorId)) {
      return false;
    }

    return switch (item) {
      ExploreOfferItem(:final offer) => opportunityApplicationsOpen(
        offer.toOpportunity(),
        today: today,
      ),
      ExploreMultiKolabRoleItem(:final role) => role.isVisibleInExplore(
        isCommunityViewer: isCommunityViewer,
        viewerProfileId: myProfileId,
      ),
    };
  }).toList();
}

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.detailRoutePrefix = '/business/explore/offer',
    this.lockedCreatorType,
  });

  final String detailRoutePrefix;
  final String? lockedCreatorType;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final PageController _pageController;

  /// Local-only third tab. Kept out of [DiscoveryFeed] because the discovery
  /// endpoint has no `saved` feed — the Saved tab is backed by a separate
  /// provider (`GET /kolabs?saved=1`).
  bool _savedSelected = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Kick off the saved-kolabs fetch so the deck bookmarks reflect prior saves
    // even before the user opens the Saved tab (the discovery feed has no
    // `is_saved` flag; the saved list seeds `savedKolabIdsProvider`).
    Future.microtask(() {
      if (mounted) ref.read(savedKolabsProvider);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isCommunityViewer {
    final user = ref.read(authProvider).user;
    if (user != null) return user.isCommunity;
    return widget.lockedCreatorType == 'business';
  }

  /// Whether [item] was authored by the current viewer. The discovery feed
  /// doesn't emit `is_own` (and `toOpportunity()` hardcodes it false), so we
  /// compare the creator profile id to the viewer's own profile id — the same
  /// ownership signal the detail screen's preview-mode already trusts. Used to
  /// keep your own kolab out of Explore and block self-application.
  bool _isOwnItem(DiscoveryItem item) {
    final myProfileId = _viewerProfileId;
    if (myProfileId == null || myProfileId.isEmpty) return false;
    final creatorId = item.creatorProfile.id;
    return creatorId.isNotEmpty && creatorId == myProfileId;
  }

  String? get _viewerProfileId {
    final user = ref.read(authProvider).user;
    return user?.communityProfile?.id ?? user?.businessProfile?.id;
  }

  void _onPageChanged(int index) {
    final listState = ref.read(discoveryListProvider);
    if (index >= listState.items.length - 2) {
      ref.read(discoveryListProvider.notifier).loadMore();
    }
  }

  /// Routes a tap to the right destination for the item's type. A
  /// Multi-Kolab role opens the shared event-detail screen focused on that
  /// role (parent-event context and the event's other roles stay visible
  /// below it); an ordinary offer opens the existing detail sheet.
  void _onFeedItemTap(ExploreFeedItem item, {required bool hasSubscription}) {
    switch (item) {
      case ExploreOfferItem(:final offer):
        _onCardTap(offer, hasSubscription: hasSubscription);
      case ExploreMultiKolabRoleItem(:final role):
        context.push(
          multiKolabRoleDetailLocation(
            eventId: role.eventId,
            roleId: role.roleId,
          ),
        );
    }
  }

  void _onCardTap(DiscoveryItem item, {required bool hasSubscription}) {
    final opportunity = item.toOpportunity();
    // Defense-in-depth: own posts are already filtered out of the feed, but if
    // one is ever opened, never allow applying to it.
    final isOwn = _isOwnItem(item);
    // Free business viewing a community Kolab: blur the community identity only.
    // Per ROLES-AND-PERMISSIONS.md golden rules 4 & 5, the business STILL opens
    // the detail and sees every Kolab detail; only name/logo are blurred and
    // the apply BUTTON is gated. We never hard-block the screen. Subscribing
    // REVEALS the identity (§2.6), so a subscribed business is never blurred.
    final hideCreatorIdentity =
        !_isCommunityViewer && item.isCommunityRequest && !hasSubscription;

    ExploreDetailSheet.show(
      context,
      opportunity: opportunity,
      discoveryItem: item,
      hideCreatorIdentity: hideCreatorIdentity,
      // Apply is BUTTON-gated, not screen-gated: a free business can always open
      // the sheet and read everything. Tapping Apply either runs the apply flow
      // (subscribed / community) or surfaces the paywall (free business).
      onApply: hasSubscription && !isOwn
          ? () {
              Navigator.of(context).pop();
              _openApplyFlow(opportunity);
            }
          : null,
      // C9: business viewer tapping a community card needs a path to the
      // community's public profile (Send Kolab CTA lives there). Hidden when
      // the creator profile id isn't usable.
      onViewCreatorProfile:
          hideCreatorIdentity ||
              !hasSubscription ||
              item.creatorProfile.id.isEmpty
          ? null
          : () {
              Navigator.of(context).pop();
              context.push('/profile/${item.creatorProfile.id}');
            },
      // When the business is free, the Apply button becomes an "unlock" CTA that
      // opens the paywall sheet. This is the gate — there is NO discovery-level
      // block; the user remains on Explore the whole time.
      onSubscribe: !_isCommunityViewer && !hasSubscription
          ? () async {
              Navigator.of(context).pop();
              final allowed = await SubscriptionPaywall.checkAndShow(
                context,
                ref,
              );
              if (allowed) {
                await ref.read(profileProvider.notifier).refreshSubscription();
              }
            }
          : null,
      canApply: (_isCommunityViewer || hasSubscription) && !isOwn,
    );
  }

  Future<void> _openApplyFlow(Opportunity opportunity) async {
    final submitted = await ApplyModal.show(context, opportunity);
    if (!mounted || submitted != true) return;

    await ApplySuccessSheet.show(
      context,
      opportunity: opportunity,
      onViewApplications: _goToApplications,
    );
  }

  void _goToApplications() {
    final route = widget.detailRoutePrefix.startsWith('/community')
        ? KolabingRoutes.communityApplications
        : KolabingRoutes.businessApplications;
    context.go(route);
  }

  void _openFilterSheet() {
    final listState = ref.read(discoveryListProvider);
    ExploreFilterSheet.show(context, totalResults: listState.total);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(discoveryListProvider);
    final filters = ref.watch(discoveryFiltersProvider);
    final profileState = ref.watch(profileProvider);
    final authUser = ref.watch(authProvider).user;
    final hasBusinessSubscription =
        _isCommunityViewer ||
        profileState.isSubscribed ||
        (authUser?.hasActiveSubscription ?? false) ||
        (authUser?.subscription?.isActive ?? false);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 6),
            // The search/filter bar + quick filters drive the discovery feed only.
            if (!_savedSelected) ...[
              _buildTopBar(filters, listState),
              const SizedBox(height: 6),
            ],
            _FeedToggle(
              feed: filters.feed,
              savedSelected: _savedSelected,
              onRecommended: () {
                setState(() => _savedSelected = false);
                ref
                    .read(discoveryFiltersProvider.notifier)
                    .setFeed(DiscoveryFeed.recommended);
              },
              onAll: () {
                setState(() => _savedSelected = false);
                ref
                    .read(discoveryFiltersProvider.notifier)
                    .setFeed(DiscoveryFeed.all);
              },
              onSaved: () => setState(() => _savedSelected = true),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            if (!_savedSelected) ...[
              DiscoveryQuickFilters(
                filters: filters,
                isCommunityViewer: _isCommunityViewer,
                onOpenFilters: _openFilterSheet,
              ),
              const SizedBox(height: KolabingSpacing.xs),
            ],
            Expanded(
              child: _savedSelected
                  ? _buildSavedTab()
                  : listState.isLoading
                  ? _buildLoadingState()
                  : listState.error != null
                  ? _buildErrorState(listState.error!)
                  : listState.isEmpty
                  ? _buildEmptyState(filters)
                  : _buildCardPageView(
                      listState,
                      hasBusinessSubscription: hasBusinessSubscription,
                      savedIds: ref.watch(savedKolabIdsProvider),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final photoUrl = ref.watch(authProvider).user?.profilePhotoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.xs,
        KolabingSpacing.md,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'EXPLORE',
              style: KolabingTextStyles.headlineLarge.copyWith(
                color: context.colors.onSurface,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: KolabingSpacing.xs),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.darkBorder, width: 1.5),
              color: context.colors.surfaceContainerLow,
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : Icon(
                      LucideIcons.user,
                      size: 20,
                      color: context.colors.onSurfaceVariant,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(DiscoveryFilters filters, DiscoveryListState listState) {
    final filterLabel = _buildFilterLabel(filters, listState.total);
    final hasFilters = filters.hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
      child: GestureDetector(
        onTap: _openFilterSheet,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(KolabingRadius.round),
            border: Border.all(
              color: hasFilters
                  ? context.colors.primary
                  : context.colors.hairline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasFilters ? LucideIcons.filterX : LucideIcons.search,
                size: 16,
                color: hasFilters
                    ? context.colors.primary
                    : context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  filterLabel,
                  style: KolabingTextStyles.captionSecondary.copyWith(
                    fontWeight: FontWeight.w500,
                    color: hasFilters
                        ? context.colors.onSurface
                        : context.colors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFilterLabel(DiscoveryFilters filters, int total) {
    final l10n = AppLocalizations.of(context);
    if (!filters.hasActiveFilters) {
      return filters.feed == DiscoveryFeed.recommended
          ? l10n.exploreRecommendedMatches
          : l10n.exploreBrowseAll;
    }

    final parts = <String>[];
    if (filters.searchQuery.isNotEmpty) {
      parts.add('"${filters.searchQuery}"');
    }
    if (filters.city != null) {
      parts.add(filters.city!);
    }
    if (filters.availabilityMode != null) {
      parts.add(
        AvailabilityMode.fromString(filters.availabilityMode!).displayName,
      );
    }
    if (!_isCommunityViewer && filters.needTypes.isNotEmpty) {
      parts.add(l10n.exploreFilterNeeds(filters.needTypes.length));
    }
    if (!_isCommunityViewer && filters.communityTypes.isNotEmpty) {
      parts.add(l10n.exploreFilterTypes(filters.communityTypes.length));
    }
    if (_isCommunityViewer && filters.offerTypes.isNotEmpty) {
      parts.add(l10n.exploreFilterOffers(filters.offerTypes.length));
    }
    if (_isCommunityViewer && filters.intentTypes.isNotEmpty) {
      parts.add(l10n.exploreFilterKolab(filters.intentTypes.length));
    }

    if (parts.isEmpty) {
      return l10n.exploreResultCount(total);
    }

    return parts.join(' · ');
  }

  Future<void> _toggleSaved(String id) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final wasSaved = ref.read(savedKolabIdsProvider).contains(id);
    try {
      await toggleKolabSaved(ref, id);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? l10n.savedKolabsUnsaveError : l10n.savedKolabsSaveError,
          ),
        ),
      );
    }
  }

  bool get _hasBusinessSubscription {
    final profileState = ref.read(profileProvider);
    final authUser = ref.read(authProvider).user;
    return _isCommunityViewer ||
        profileState.isSubscribed ||
        (authUser?.hasActiveSubscription ?? false) ||
        (authUser?.subscription?.isActive ?? false);
  }

  /// Open the detail sheet for a saved kolab, with the same apply/paywall wiring
  /// as the discovery deck (a free business gets the paywall, never a hard block).
  void _openSavedOpportunity(Opportunity opportunity) {
    final hasSub = _hasBusinessSubscription;
    final isOwn = opportunity.isOwn ?? false;
    ExploreDetailSheet.show(
      context,
      opportunity: opportunity,
      onApply: hasSub && !isOwn
          ? () {
              Navigator.of(context).pop();
              _openApplyFlow(opportunity);
            }
          : null,
      onSubscribe: !_isCommunityViewer && !hasSub
          ? () async {
              Navigator.of(context).pop();
              final allowed = await SubscriptionPaywall.checkAndShow(
                context,
                ref,
              );
              if (allowed) {
                await ref.read(profileProvider.notifier).refreshSubscription();
              }
            }
          : null,
      canApply: (_isCommunityViewer || hasSub) && !isOwn,
    );
  }

  /// Apply directly from a saved card's Apply button. Free business → paywall.
  Future<void> _applyFromSaved(Opportunity opportunity) async {
    if (opportunity.isOwn ?? false) return;
    if (!_isCommunityViewer && !_hasBusinessSubscription) {
      final allowed = await SubscriptionPaywall.checkAndShow(context, ref);
      if (!allowed || !mounted) return;
      await ref.read(profileProvider.notifier).refreshSubscription();
      if (!mounted) return;
    }
    await _openApplyFlow(opportunity);
  }

  Widget _buildSavedTab() {
    final l10n = AppLocalizations.of(context);
    final asyncSaved = ref.watch(savedKolabsProvider);

    return asyncSaved.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: context.colors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (_, _) => _SavedKolabsMessage(
        icon: LucideIcons.alertCircle,
        title: l10n.savedKolabsErrorTitle,
        body: l10n.savedKolabsErrorBody,
        actionLabel: l10n.commonRetry,
        onAction: () => ref.invalidate(savedKolabsProvider),
      ),
      data: (saved) {
        if (saved.isEmpty) {
          return _SavedKolabsMessage(
            icon: LucideIcons.bookmark,
            title: l10n.savedKolabsEmptyTitle,
            body: l10n.savedKolabsEmptyBody,
          );
        }
        return RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async {
            ref.invalidate(savedKolabsProvider);
            await ref.read(savedKolabsProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.md,
              KolabingSpacing.xs,
              KolabingSpacing.md,
              _fabClearance,
            ),
            itemCount: saved.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: KolabingSpacing.sm),
            itemBuilder: (context, index) {
              final opportunity = saved[index];
              final id = opportunity.id;
              final isOwn = opportunity.isOwn ?? false;
              return OpportunityCard(
                opportunity: opportunity,
                isSaved: true,
                onToggleSave: id != null ? () => _toggleSaved(id) : null,
                onView: () => _openSavedOpportunity(opportunity),
                onApply: (id != null && !isOwn)
                    ? () => _applyFromSaved(opportunity)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardPageView(
    DiscoveryListState listState, {
    required bool hasBusinessSubscription,
    required Set<String> savedIds,
  }) {
    final today = DateTime.now();
    // UGC moderation (App Review 1.2): hide Kolabs whose creator the viewer has
    // blocked so blocked content disappears from the deck instantly.
    final blocked = ref.watch(blockedProfilesProvider);
    final user = ref.read(authProvider).user;
    final myProfileId = user?.communityProfile?.id ?? user?.businessProfile?.id;
    final activeItems = filterExploreDeckItems(
      listState.items,
      blockedProfileIds: blocked,
      myProfileId: myProfileId,
      today: today,
      isCommunityViewer: _isCommunityViewer,
    );

    final itemCount = activeItems.length + (listState.isLoadingMore ? 1 : 0);

    // Reserve the FAB's zone under each card so it never covers the card's
    // bottom-right action area (View Details / bookmark).
    return Padding(
      padding: const EdgeInsets.only(bottom: _fabClearance),
      child: PageView.builder(
        key: const Key('explore-deck'),
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (index >= activeItems.length) {
            return Center(
              child: CircularProgressIndicator(
                color: context.colors.primary,
                strokeWidth: 2,
              ),
            );
          }

          final item = activeItems[index];
          // Blur the community identity only for a FREE business; subscribing
          // reveals it (§2.6). Only ordinary community offers carry a
          // creator identity to hide.
          final isCommunityRequest =
              item is ExploreOfferItem && item.offer.isCommunityRequest;
          final hideCreatorIdentity =
              !_isCommunityViewer &&
              isCommunityRequest &&
              !hasBusinessSubscription;

          // Saving is backed by `GET/POST /kolabs?saved=1`, which is keyed by
          // a concrete Kolab id. A Multi-Kolab ROLE has no Kolab id, and
          // reusing the role id here would silently save the wrong record —
          // so the bookmark control is offered only where it has a real
          // target. See the Task 9 follow-up note about a typed save target.
          final saveableKolabId = switch (item) {
            ExploreOfferItem(:final offer) =>
              offer.id.isNotEmpty ? offer.id : null,
            ExploreMultiKolabRoleItem() => null,
          };

          return Stack(
            key: Key('explore-feed-item-${item.feedKey}'),
            children: [
              ExploreSwipeCard(
                item: item,
                showKolabFirst: !_isCommunityViewer && isCommunityRequest,
                hideCreatorIdentity: hideCreatorIdentity,
                onTap: () => _onFeedItemTap(
                  item,
                  hasSubscription: hasBusinessSubscription,
                ),
              ),
              if (saveableKolabId != null)
                Positioned(
                  top: KolabingSpacing.md,
                  right: KolabingSpacing.md,
                  child: _SaveBookmarkButton(
                    isSaved: savedIds.contains(saveableKolabId),
                    onTap: () => _toggleSaved(saveableKolabId),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.md,
      vertical: KolabingSpacing.xs,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(KolabingRadius.xl),
      child: Shimmer.fromColors(
        baseColor: context.colors.surfaceVariant,
        highlightColor: context.colors.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(KolabingRadius.xl),
          ),
          child: Stack(
            children: [
              Positioned(
                left: KolabingSpacing.md,
                right: KolabingSpacing.md,
                bottom: KolabingSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: context.colors.darkBorder,
                        borderRadius: BorderRadius.circular(
                          KolabingRadius.round,
                        ),
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Container(
                      width: 220,
                      height: 22,
                      decoration: BoxDecoration(
                        color: context.colors.darkBorder,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Row(
                      children: List.generate(
                        3,
                        (int index) => Padding(
                          padding: const EdgeInsets.only(
                            right: KolabingSpacing.xxs,
                          ),
                          child: Container(
                            width: 72,
                            height: 22,
                            decoration: BoxDecoration(
                              color: context.colors.darkBorder,
                              borderRadius: BorderRadius.circular(
                                KolabingRadius.round,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: context.colors.darkBorder,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xxs),
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: context.colors.darkBorder,
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
    ),
  );

  Widget _buildEmptyState(DiscoveryFilters filters) {
    final isRecommended = filters.feed == DiscoveryFeed.recommended;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Icon(
                  filters.hasActiveFilters
                      ? LucideIcons.searchX
                      : LucideIcons.sparkles,
                  size: 36,
                  color: context.colors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              filters.hasActiveFilters
                  ? AppLocalizations.of(context).exploreEmptyNoResults
                  : isRecommended
                  ? AppLocalizations.of(context).exploreEmptyNoRecommended
                  : AppLocalizations.of(context).exploreEmptyNoOpportunities,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              filters.hasActiveFilters
                  ? AppLocalizations.of(context).exploreEmptyNoResultsHint
                  : isRecommended
                  ? AppLocalizations.of(context).exploreEmptyNoRecommendedHint
                  : AppLocalizations.of(
                      context,
                    ).exploreEmptyNoOpportunitiesHint,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (filters.hasActiveFilters) ...[
              const SizedBox(height: KolabingSpacing.lg),
              TextButton.icon(
                onPressed: () {
                  ref.read(discoveryFiltersProvider.notifier).clearAll();
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: Text(AppLocalizations.of(context).exploreClearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.errorBg,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Icon(
                LucideIcons.alertCircle,
                size: 36,
                color: context.colors.error,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).exploreSomethingWrong,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(discoveryListProvider.notifier).refresh();
            },
            icon: const Icon(LucideIcons.refreshCcw, size: 16),
            label: Text(AppLocalizations.of(context).exploreTryAgain),
          ),
        ],
      ),
    ),
  );
}

class _FeedToggle extends StatelessWidget {
  const _FeedToggle({
    required this.feed,
    required this.savedSelected,
    required this.onRecommended,
    required this.onAll,
    required this.onSaved,
  });

  final DiscoveryFeed feed;
  final bool savedSelected;
  final VoidCallback onRecommended;
  final VoidCallback onAll;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KolabingRadius.round),
          border: Border.all(color: context.colors.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: _FeedSegment(
                label: l10n.exploreFeedRecommended,
                isSelected: !savedSelected && feed == DiscoveryFeed.recommended,
                onTap: onRecommended,
              ),
            ),
            Expanded(
              child: _FeedSegment(
                label: l10n.exploreFeedAll,
                isSelected: !savedSelected && feed == DiscoveryFeed.all,
                onTap: onAll,
              ),
            ),
            Expanded(
              child: _FeedSegment(
                label: l10n.exploreFeedSaved,
                isSelected: savedSelected,
                onTap: onSaved,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered icon + title + body (+ optional action) used for the Saved tab's
/// empty and error states.
class _SavedKolabsMessage extends StatelessWidget {
  const _SavedKolabsMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: context.colors.textTertiary),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.headlineSmall.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KolabingSpacing.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

/// Circular bookmark toggle button overlaid on a kolab card.
class _SaveBookmarkButton extends StatelessWidget {
  const _SaveBookmarkButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: const CircleBorder(),
    elevation: 2,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: 20,
          color: isSaved
              ? context.colors.primary
              : context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _FeedSegment extends StatelessWidget {
  const _FeedSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.softYellow : Colors.transparent,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        border: isSelected ? Border.all(color: context.colors.primary) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: KolabingTextStyles.button.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected
              ? KolabingColors.onSurface
              : context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
