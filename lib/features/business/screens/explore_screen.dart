import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../application/widgets/apply_modal.dart';
import '../../auth/providers/auth_provider.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/models/opportunity_filter.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../widgets/opportunity_card.dart';

/// Explore Screen
///
/// Allows users to browse collaboration opportunities.
/// Features search bar, filter chips, paginated list with infinite scroll.
/// Used by both business and community users.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.detailRoutePrefix = '/business/explore/offer',
  });

  /// Route prefix for opportunity detail navigation
  /// Business users: '/business/explore/offer'
  /// Community users: '/community/explore/offer'
  final String detailRoutePrefix;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  /// Track if search has text for UI updates
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Update UI when search text changes (for clear button visibility)
  void _onSearchTextChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  /// Debounced search - waits 400ms after typing stops before API call
  void _onSearchSubmit(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(opportunityFiltersProvider.notifier).setSearch(value.trim());
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(opportunityListProvider.notifier).loadMore();
    }
  }

  void _onViewOpportunity(Opportunity opportunity) {
    context.push(
      '${widget.detailRoutePrefix}/${opportunity.id}',
      extra: opportunity,
    );
  }

  void _onApplyOpportunity(Opportunity opportunity) {
    ApplyModal.show(context, opportunity);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(opportunityListProvider);
    final filters = ref.watch(opportunityFiltersProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Filter chips
            _buildFilterChips(filters),

            // Results count and list
            Expanded(
              child: listState.isLoading
                  ? _buildLoadingState()
                  : listState.error != null
                      ? _buildErrorState(listState.error!)
                      : listState.isEmpty
                          ? _buildEmptyState(filters.hasActiveFilters)
                          : _buildOpportunityList(listState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXPLORE',
              style: GoogleFonts.rubik(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              'Find collaboration opportunities',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.xs,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchSubmit,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            // Immediate search on submit (Enter key)
            _debounceTimer?.cancel();
            ref.read(opportunityFiltersProvider.notifier).setSearch(value.trim());
          },
          decoration: InputDecoration(
            hintText: 'Search by title, description, or creator...',
            hintStyle: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textTertiary,
            ),
            prefixIcon: const Icon(
              LucideIcons.search,
              size: 18,
              color: KolabingColors.textTertiary,
            ),
            suffixIcon: _hasSearchText
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      _debounceTimer?.cancel();
                      ref
                          .read(opportunityFiltersProvider.notifier)
                          .setSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: KolabingColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide:
                  const BorderSide(color: KolabingColors.primary, width: 1.5),
            ),
          ),
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textPrimary,
          ),
        ),
      );

  Widget _buildFilterChips(OpportunityFilters filters) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
          ),
          children: [
            // All chip
            _FilterChip(
              label: 'All',
              isSelected: !filters.hasActiveFilters,
              onTap: () {
                ref.read(opportunityFiltersProvider.notifier).clearAll();
                _searchController.clear();
              },
            ),
            const SizedBox(width: KolabingSpacing.xs),

            // Creator type chips
            _FilterChip(
              label: 'Business',
              isSelected: filters.creatorType == 'business',
              onTap: () {
                ref
                    .read(opportunityFiltersProvider.notifier)
                    .setCreatorType('business');
              },
            ),
            const SizedBox(width: KolabingSpacing.xs),
            _FilterChip(
              label: 'Community',
              isSelected: filters.creatorType == 'community',
              onTap: () {
                ref
                    .read(opportunityFiltersProvider.notifier)
                    .setCreatorType('community');
              },
            ),
            const SizedBox(width: KolabingSpacing.xs),

            // Venue mode chips
            ...VenueMode.values.map((mode) => Padding(
                  padding: const EdgeInsets.only(right: KolabingSpacing.xs),
                  child: _FilterChip(
                    label: mode.displayName,
                    icon: LucideIcons.building2,
                    isSelected: filters.venueMode == mode.toApiValue(),
                    onTap: () {
                      ref
                          .read(opportunityFiltersProvider.notifier)
                          .setVenueMode(mode.toApiValue());
                    },
                  ),
                )),

            // Availability mode chips
            ...AvailabilityMode.values.map((mode) => Padding(
                  padding: const EdgeInsets.only(right: KolabingSpacing.xs),
                  child: _FilterChip(
                    label: mode.displayName,
                    icon: LucideIcons.clock,
                    isSelected:
                        filters.availabilityMode == mode.toApiValue(),
                    onTap: () {
                      ref
                          .read(opportunityFiltersProvider.notifier)
                          .setAvailabilityMode(mode.toApiValue());
                    },
                  ),
                )),
          ],
        ),
      );

  Widget _buildOpportunityList(OpportunityListState listState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            child: Text(
              '${listState.total} ${listState.total == 1 ? 'result' : 'results'} found',
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              color: KolabingColors.primary,
              onRefresh: () async {
                await ref.read(opportunityListProvider.notifier).refresh();
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  0,
                  KolabingSpacing.md,
                  KolabingSpacing.xxl,
                ),
                itemCount: listState.opportunities.length +
                    (listState.isLoadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: KolabingSpacing.sm),
                itemBuilder: (context, index) {
                  if (index >= listState.opportunities.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(KolabingSpacing.md),
                        child: CircularProgressIndicator(
                          color: KolabingColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final opportunity = listState.opportunities[index];
                  final currentUserId = ref.read(authProvider).user?.id;
                  final isOwn = currentUserId != null &&
                      opportunity.creatorProfile?.id == currentUserId;
                  return OpportunityCard(
                    opportunity: opportunity,
                    onView: () => _onViewOpportunity(opportunity),
                    onApply: isOwn ? null : () => _onApplyOpportunity(opportunity),
                  );
                },
              ),
            ),
          ),
        ],
      );

  Widget _buildLoadingState() => SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          children: List.generate(
            3,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: _ShimmerCard(),
            ),
          ),
        ),
      );

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
                    _searchController.clear();
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

/// Filter chip widget for horizontal scroll
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KolabingRadius.borderRadiusRound,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? KolabingColors.primary
                  : KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusRound,
              border: Border.all(
                color: isSelected
                    ? KolabingColors.primary
                    : KolabingColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? KolabingColors.onPrimary
                        : KolabingColors.textSecondary,
                  ),
                  const SizedBox(width: KolabingSpacing.xxs),
                ],
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? KolabingColors.onPrimary
                        : KolabingColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Shimmer loading card placeholder
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header placeholder
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: KolabingRadius.borderRadiusSm,
                          ),
                        ),
                        const SizedBox(height: KolabingSpacing.xxs),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: KolabingRadius.borderRadiusSm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Title placeholder
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description placeholder
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xxs),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Tags placeholder
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Container(
                    width: 80,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Container(
                    width: 90,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Buttons placeholder
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KolabingRadius.borderRadiusMd,
                      ),
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KolabingRadius.borderRadiusMd,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
