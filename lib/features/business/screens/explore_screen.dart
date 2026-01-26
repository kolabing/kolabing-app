import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/collab_request.dart';
import '../providers/explore_provider.dart';
import '../widgets/collab_request_card.dart';

/// Business Explore Screen
///
/// Allows business users to browse collaboration opportunities
/// from communities. Features filtering and list of opportunity cards.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {

  void _onViewRequest(CollabRequest request) {
    // TODO(developer): Navigate to detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing: ${request.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onApplyRequest(CollabRequest request) {
    // TODO(developer): Navigate to application flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applying to: ${request.title}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: KolabingColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(collabRequestsProvider);
    final filters = ref.watch(exploreFiltersProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Filter chips
            _buildFilterChips(filters),

            // Results count and list
            Expanded(
              child: requestsAsync.when(
                loading: _buildLoadingState,
                error: (error, _) => _buildErrorState(error.toString()),
                data: (requests) => requests.isEmpty
                    ? _buildEmptyState(filters.hasActiveFilters)
                    : _buildRequestsList(requests),
              ),
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
              'Find collaboration opportunities from communities',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChips(ExploreFilters filters) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
          ),
          children: [
            // All filter chip
            _FilterChip(
              label: 'All',
              isSelected: !filters.hasActiveFilters,
              onTap: () {
                ref.read(exploreFiltersProvider.notifier).clearAllFilters();
              },
            ),
            const SizedBox(width: KolabingSpacing.xs),

            // Type filter chips
            ...CollabType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: KolabingSpacing.xs),
                  child: _FilterChip(
                    label: type.displayName,
                    isSelected: filters.selectedType == type,
                    onTap: () {
                      ref.read(exploreFiltersProvider.notifier).setCollabType(type);
                    },
                  ),
                )),

            // Location filter chips
            const SizedBox(width: KolabingSpacing.xs),
            ..._buildLocationChips(filters),
          ],
        ),
      );

  List<Widget> _buildLocationChips(ExploreFilters filters) {
    final locationsAsync = ref.watch(availableLocationsProvider);

    return locationsAsync.when(
      loading: () => const <Widget>[],
      error: (_, _) => const <Widget>[],
      data: (locations) => locations
          .map((location) => Padding(
                padding: const EdgeInsets.only(right: KolabingSpacing.xs),
                child: _FilterChip(
                  label: location,
                  icon: LucideIcons.mapPin,
                  isSelected: filters.selectedLocation == location,
                  onTap: () {
                    ref
                        .read(exploreFiltersProvider.notifier)
                        .setLocation(location);
                  },
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRequestsList(List<CollabRequest> requests) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            child: Text(
              '${requests.length} ${requests.length == 1 ? 'result' : 'results'} found',
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
                await ref.read(collabRequestsProvider.notifier).refresh();
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  0,
                  KolabingSpacing.md,
                  KolabingSpacing.xxl,
                ),
                itemCount: requests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: KolabingSpacing.sm),
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return CollabRequestCard(
                    request: request,
                    onView: () => _onViewRequest(request),
                    onApply: () => _onApplyRequest(request),
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
                hasFilters
                    ? 'No results found'
                    : 'No collaboration requests yet',
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
                    ref.read(exploreFiltersProvider.notifier).clearAllFilters();
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
                  ref.read(collabRequestsProvider.notifier).refresh();
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
