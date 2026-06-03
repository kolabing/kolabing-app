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
import '../../discovery/providers/discovery_provider.dart';
import '../../discovery/widgets/discovery_quick_filters.dart';
import '../../notification/widgets/notification_bell.dart';
import '../../opportunity/models/opportunity.dart';
import '../../subscription/widgets/subscription_paywall.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  void _onPageChanged(int index) {
    final listState = ref.read(discoveryListProvider);
    if (index >= listState.items.length - 2) {
      ref.read(discoveryListProvider.notifier).loadMore();
    }
  }

  void _onCardTap(DiscoveryItem item, {required bool hasSubscription}) {
    final opportunity = item.toOpportunity();
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
      onApply: hasSubscription
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
      canApply: _isCommunityViewer || hasSubscription,
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
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(filters, listState),
            const SizedBox(height: KolabingSpacing.xs),
            _FeedToggle(
              feed: filters.feed,
              onChanged: (DiscoveryFeed value) =>
                  ref.read(discoveryFiltersProvider.notifier).setFeed(value),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            DiscoveryQuickFilters(
              filters: filters,
              isCommunityViewer: _isCommunityViewer,
              onOpenFilters: _openFilterSheet,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Expanded(
              child: listState.isLoading
                  ? _buildLoadingState()
                  : listState.error != null
                  ? _buildErrorState(listState.error!)
                  : listState.isEmpty
                  ? _buildEmptyState(filters)
                  : _buildCardPageView(
                      listState,
                      hasBusinessSubscription: hasBusinessSubscription,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DiscoveryFilters filters, DiscoveryListState listState) {
    final filterLabel = _buildFilterLabel(context, filters, listState.total);
    final hasFilters = filters.hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.xs,
        KolabingSpacing.xs,
        KolabingSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openFilterSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: KolabingColors.surface,
                  borderRadius: BorderRadius.circular(KolabingRadius.round),
                  border: Border.all(
                    color: hasFilters
                        ? KolabingColors.primary
                        : KolabingColors.darkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasFilters ? LucideIcons.filterX : LucideIcons.search,
                      size: 16,
                      color: hasFilters
                          ? KolabingColors.primary
                          : KolabingColors.textTertiary,
                    ),
                    const SizedBox(width: KolabingSpacing.xs),
                    Expanded(
                      child: Text(
                        filterLabel,
                        style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w500, color: hasFilters
                              ? KolabingColors.onSurface
                              : KolabingColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.xs),
          const NotificationBell(),
        ],
      ),
    );
  }

  String _buildFilterLabel(
    BuildContext context,
    DiscoveryFilters filters,
    int total,
  ) {
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

  Widget _buildCardPageView(
    DiscoveryListState listState, {
    required bool hasBusinessSubscription,
  }) {
    final today = DateTime.now();
    final activeItems = listState.items.where((DiscoveryItem item) {
      final end = item.availability.end;
      return !end.isBefore(DateTime(today.year, today.month, today.day));
    }).toList();

    final itemCount = activeItems.length + (listState.isLoadingMore ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        if (index >= activeItems.length) {
          return const Center(
            child: CircularProgressIndicator(
              color: KolabingColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        final item = activeItems[index];
        // Blur the community identity only for a FREE business; subscribing
        // reveals it (§2.6).
        final hideCreatorIdentity =
            !_isCommunityViewer &&
            item.isCommunityRequest &&
            !hasBusinessSubscription;
        return ExploreSwipeCard(
          item: item,
          showKolabFirst: !_isCommunityViewer && item.isCommunityRequest,
          hideCreatorIdentity: hideCreatorIdentity,
          onTap: () =>
              _onCardTap(item, hasSubscription: hasBusinessSubscription),
        );
      },
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
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KolabingColors.surfaceVariant,
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
                        color: KolabingColors.darkBorder,
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
                        color: KolabingColors.darkBorder,
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
                              color: KolabingColors.darkBorder,
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
                        color: KolabingColors.darkBorder,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xxs),
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: KolabingColors.darkBorder,
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
              decoration: const BoxDecoration(
                color: KolabingColors.surfaceVariant,
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
                  color: KolabingColors.textTertiary,
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
              style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
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
              style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
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
                style: TextButton.styleFrom(
                  foregroundColor: KolabingColors.primary,
                ),
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
          const DecoratedBox(
            decoration: BoxDecoration(
              color: KolabingColors.errorBg,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Icon(
                LucideIcons.alertCircle,
                size: 36,
                color: KolabingColors.error,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).exploreSomethingWrong,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
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
  const _FeedToggle({required this.feed, required this.onChanged});

  final DiscoveryFeed feed;
  final ValueChanged<DiscoveryFeed> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        border: Border.all(color: KolabingColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FeedSegment(
              label: AppLocalizations.of(context).exploreFeedRecommended,
              isSelected: feed == DiscoveryFeed.recommended,
              onTap: () => onChanged(DiscoveryFeed.recommended),
            ),
          ),
          Expanded(
            child: _FeedSegment(
              label: AppLocalizations.of(context).exploreFeedAll,
              isSelected: feed == DiscoveryFeed.all,
              onTap: () => onChanged(DiscoveryFeed.all),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? KolabingColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: KolabingTextStyles.button.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected
              ? KolabingColors.onPrimary
              : KolabingColors.onSurfaceVariant),
      ),
    ),
  );
}
