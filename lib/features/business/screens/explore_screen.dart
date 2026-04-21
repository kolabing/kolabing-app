import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../widgets/explore_detail_sheet.dart';
import '../../../widgets/explore_filter_sheet.dart';
import '../../../widgets/explore_swipe_card.dart';
import '../../application/widgets/apply_modal.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/widgets/notification_bell.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/models/opportunity_filter.dart';
import '../../opportunity/providers/opportunity_provider.dart';

/// Explore Screen - Full-screen swipeable card experience
///
/// Allows users to browse collaboration opportunities with vertical swipe cards.
/// Features a filter pill at the top and full-screen Tinder-style card navigation.
/// Used by both business and community users.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.detailRoutePrefix = '/business/explore/offer',
    this.lockedCreatorType,
  });

  /// Route prefix for opportunity detail navigation
  final String detailRoutePrefix;

  /// When set, filters are locked to this creator type
  final String? lockedCreatorType;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final PageController _pageController;
  ProviderSubscription<OpportunityFilters>? _filtersSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _filtersSubscription = ref.listenManual<OpportunityFilters>(
      opportunityFiltersProvider,
      (previous, next) {
        if (previous != next) {
          ref.read(opportunityListProvider.notifier).refresh();
        }
      },
    );
    // Apply locked creator type filter after first frame
    if (widget.lockedCreatorType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(opportunityFiltersProvider.notifier)
            .setCreatorTypeLocked(widget.lockedCreatorType!);
      });
    }
  }

  @override
  void dispose() {
    _filtersSubscription?.close();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Preload more when reaching the last 2 cards
    final listState = ref.read(opportunityListProvider);
    if (index >= listState.opportunities.length - 2) {
      ref.read(opportunityListProvider.notifier).loadMore();
    }
  }

  void _onCardTap(Opportunity opportunity) {
    final currentUser = ref.read(authProvider).user;
    final isOwn =
        currentUser?.id != null &&
        opportunity.creatorProfile?.id == currentUser?.id;
    final canApply = !isOwn && (currentUser?.isBusiness != true);

    ExploreDetailSheet.show(
      context,
      opportunity: opportunity,
      canApply: canApply,
      onApply: canApply
          ? () {
              Navigator.of(context).pop(); // Close detail sheet
              ApplyModal.show(context, opportunity);
            }
          : null,
      onView: () {
        Navigator.of(context).pop(); // Close detail sheet
        context.push(
          '${widget.detailRoutePrefix}/${opportunity.id}',
          extra: opportunity,
        );
      },
    );
  }

  void _openFilterSheet() {
    final listState = ref.read(opportunityListProvider);
    ExploreFilterSheet.show(context, totalResults: listState.total);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(opportunityListProvider);
    final filters = ref.watch(opportunityFiltersProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: filter pill + notification bell
            _buildTopBar(filters, listState),

            // Main content
            Expanded(
              child: listState.isLoading
                  ? _buildLoadingState()
                  : listState.error != null
                  ? _buildErrorState(listState.error!)
                  : listState.isEmpty
                  ? _buildEmptyState(filters.hasActiveFilters)
                  : _buildCardPageView(listState),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  /// Whether user has explicitly set filters (excluding locked creatorType).
  bool _hasUserFilters(OpportunityFilters filters) =>
      filters.searchQuery.isNotEmpty ||
      filters.selectedCategories.isNotEmpty ||
      filters.selectedCity != null ||
      filters.venueMode != null ||
      filters.availabilityMode != null;

  Widget _buildTopBar(
    OpportunityFilters filters,
    OpportunityListState listState,
  ) {
    final filterLabel = _buildFilterLabel(filters, listState.total);
    final hasFilters = _hasUserFilters(filters);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.xs,
        KolabingSpacing.xs,
        KolabingSpacing.xs,
      ),
      child: Row(
        children: [
          // Filter pill
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
                        : KolabingColors.border,
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
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: hasFilters
                              ? KolabingColors.textPrimary
                              : KolabingColors.textTertiary,
                        ),
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

          // Notification bell
          const NotificationBell(),
        ],
      ),
    );
  }

  String _buildFilterLabel(OpportunityFilters filters, int total) {
    // Check for user-visible filters (exclude lockedCreatorType which is implicit)
    final hasUserFilters =
        filters.searchQuery.isNotEmpty ||
        filters.selectedCategories.isNotEmpty ||
        filters.selectedCity != null ||
        filters.venueMode != null ||
        filters.availabilityMode != null;

    if (!hasUserFilters) {
      return 'Find your next collab!';
    }

    final parts = <String>[];
    if (filters.searchQuery.isNotEmpty) {
      parts.add('"${filters.searchQuery}"');
    }
    if (filters.venueMode != null) {
      final mode = VenueMode.fromString(filters.venueMode!);
      parts.add(mode.displayName);
    }
    if (filters.availabilityMode != null) {
      final mode = AvailabilityMode.fromString(filters.availabilityMode!);
      parts.add(mode.displayName);
    }
    if (filters.selectedCity != null) {
      parts.add(filters.selectedCity!);
    }

    return parts.join(' · ');
  }

  // ---------------------------------------------------------------------------
  // Card PageView
  // ---------------------------------------------------------------------------

  Widget _buildCardPageView(OpportunityListState listState) {
    // Client-side filter: hide expired kolabs (availabilityEnd in the past)
    final today = DateTime.now();
    final activeOpportunities = listState.opportunities
        .where(
          (o) => !o.availabilityEnd.isBefore(
            DateTime(today.year, today.month, today.day),
          ),
        )
        .toList();

    final itemCount =
        activeOpportunities.length + (listState.isLoadingMore ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Loading more indicator at end
        if (index >= activeOpportunities.length) {
          return const Center(
            child: CircularProgressIndicator(
              color: KolabingColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        final opportunity = activeOpportunities[index];
        return ExploreSwipeCard(
          opportunity: opportunity,
          onTap: () => _onCardTap(opportunity),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

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
              // Fake gradient overlay
              Positioned(
                left: KolabingSpacing.md,
                right: KolabingSpacing.md,
                bottom: KolabingSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: KolabingColors.border,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xs),
                    Container(
                      width: 200,
                      height: 22,
                      decoration: BoxDecoration(
                        color: KolabingColors.border,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(
                            right: KolabingSpacing.xxs,
                          ),
                          child: Container(
                            width: 60,
                            height: 22,
                            decoration: BoxDecoration(
                              color: KolabingColors.border,
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
                        color: KolabingColors.border,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xxs),
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: KolabingColors.border,
                        borderRadius: KolabingRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Row(
                      children: List.generate(
                        7,
                        (i) => Padding(
                          padding: EdgeInsets.only(right: i < 6 ? 6.0 : 0),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: KolabingColors.border,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
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

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(bool hasFilters) => Center(
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
                hasFilters ? LucideIcons.searchX : LucideIcons.search,
                size: 36,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            hasFilters ? 'No results found' : 'No opportunities yet',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            hasFilters
                ? 'Try adjusting your filters or search terms'
                : 'Check back later for new opportunities',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: KolabingSpacing.lg),
            TextButton.icon(
              onPressed: () {
                ref.read(opportunityFiltersProvider.notifier).clearAll();
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: const Text('Clear all filters'),
              style: TextButton.styleFrom(
                foregroundColor: KolabingColors.primary,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

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
            'Something went wrong',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(opportunityListProvider.notifier).refresh();
            },
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
