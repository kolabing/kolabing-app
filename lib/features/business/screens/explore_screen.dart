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
import '../../notification/widgets/notification_bell.dart';
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
    this.lockedCreatorType,
  });

  /// Route prefix for opportunity detail navigation
  /// Business users: '/business/explore/offer'
  /// Community users: '/community/explore/offer'
  final String detailRoutePrefix;

  /// When set, filters are locked to this creator type (e.g. 'business').
  /// Community users should only see business offers.
  final String? lockedCreatorType;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? KolabingColors.darkBackground : KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isDark),

            // Search bar
            _buildSearchBar(isDark),

            // Results count and list
            Expanded(
              child: listState.isLoading
                  ? _buildLoadingState(isDark)
                  : listState.error != null
                      ? _buildErrorState(listState.error!, isDark)
                      : listState.isEmpty
                          ? _buildEmptyState(filters.searchQuery.isNotEmpty, isDark)
                          : _buildOpportunityList(listState, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.xs,
          KolabingSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPLORE',
                    style: GoogleFonts.rubik(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    'Find your next collab!',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const NotificationBell(),
          ],
        ),
      );

  Widget _buildSearchBar(bool isDark) => Padding(
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
            prefixIcon: Icon(
              LucideIcons.search,
              size: 18,
              color: isDark
                  ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                  : KolabingColors.textTertiary,
            ),
            suffixIcon: _hasSearchText
                ? IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: isDark
                          ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                          : null,
                    ),
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
            fillColor:
                isDark ? KolabingColors.darkSurface : KolabingColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide(
                color:
                    isDark ? KolabingColors.darkBorder : KolabingColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide(
                color:
                    isDark ? KolabingColors.darkBorder : KolabingColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide:
                  const BorderSide(color: KolabingColors.primary, width: 1.5),
            ),
          ),
          style: GoogleFonts.openSans(
            fontSize: 14,
            color:
                isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary,
          ),
        ),
      );

  Widget _buildFilterChips(OpportunityFilters filters, bool isDark) => SizedBox(
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
              isDark: isDark,
              onTap: () {
                ref.read(opportunityFiltersProvider.notifier).clearAll();
                _searchController.clear();
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
                    isDark: isDark,
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
                    isDark: isDark,
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

  Widget _buildOpportunityList(OpportunityListState listState, bool isDark) =>
      Column(
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
                color: isDark
                    ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                    : KolabingColors.textTertiary,
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
                    onApply:
                        isOwn ? null : () => _onApplyOpportunity(opportunity),
                  );
                },
              ),
            ),
          ),
        ],
      );

  Widget _buildLoadingState(bool isDark) => SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: _ShimmerCard(isDark: isDark),
            ),
          ),
        ),
      );

  Widget _buildEmptyState(bool hasFilters, bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? KolabingColors.darkSurface
                      : KolabingColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(
                    hasFilters ? LucideIcons.searchX : LucideIcons.search,
                    size: 36,
                    color: isDark
                        ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                        : KolabingColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                hasFilters ? 'No results found' : 'No opportunities yet',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
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

  Widget _buildErrorState(String error, bool isDark) => Center(
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
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
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
    this.isDark = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isDark;

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
                  : isDark
                      ? KolabingColors.darkSurface
                      : KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusRound,
              border: Border.all(
                color: isSelected
                    ? KolabingColors.primary
                    : isDark
                        ? KolabingColors.darkBorder
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
                        : isDark
                            ? KolabingColors.textOnDark
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
  const _ShimmerCard({this.isDark = false});

  final bool isDark;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor:
            isDark ? KolabingColors.darkSurface : KolabingColors.surfaceVariant,
        highlightColor:
            isDark ? KolabingColors.darkBorder : KolabingColors.surface,
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
