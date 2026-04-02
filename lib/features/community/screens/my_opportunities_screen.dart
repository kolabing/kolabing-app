import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../widgets/my_opportunity_card.dart';

/// My Opportunities screen for community users
///
/// Shows the user's own opportunities with status tabs,
/// management actions, pull-to-refresh, and pagination.
class MyOpportunitiesScreen extends ConsumerStatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  ConsumerState<MyOpportunitiesScreen> createState() =>
      _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState
    extends ConsumerState<MyOpportunitiesScreen> {
  final _scrollController = ScrollController();

  static const _statusTabs = [
    (label: 'All', value: null),
    (label: 'Draft', value: 'draft'),
    (label: 'Published', value: 'published'),
    (label: 'Closed', value: 'closed'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(myOpportunitiesProvider.notifier).loadMore();
    }
  }

  void _onCreateNew() {
    context.push(KolabingRoutes.kolabNew);
  }

  void _onEdit(Opportunity opportunity) {
    context.push(
      '/community/opportunities/${opportunity.id}/edit',
      extra: opportunity,
    );
  }

  Future<void> _onPublish(String id) async {
    final success =
        await ref.read(myOpportunitiesProvider.notifier).publish(id);
    if (mounted) {
      final state = ref.read(myOpportunitiesProvider);
      final errorMessage = state.error ?? 'Failed to publish';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kolab published!' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? KolabingColors.success : KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onClose(String id) async {
    final success =
        await ref.read(myOpportunitiesProvider.notifier).close(id);
    if (mounted) {
      final state = ref.read(myOpportunitiesProvider);
      final errorMessage = state.error ?? 'Failed to close';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kolab closed' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? KolabingColors.success : KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Kolab'),
        content: const Text(
            'Are you sure you want to delete this kolab? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(myOpportunitiesProvider.notifier).delete(id);
      if (mounted) {
        final state = ref.read(myOpportunitiesProvider);
        final errorMessage = state.error ?? 'Failed to delete';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Kolab deleted' : errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                success ? KolabingColors.success : KolabingColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(myOpportunitiesProvider);
    final currentStatus = ref.watch(myOpportunitiesStatusProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Status tabs
            _buildStatusTabs(currentStatus),

            // List
            Expanded(
              child: listState.isLoading
                  ? _buildLoadingState()
                  : listState.error != null
                      ? _buildErrorState(listState.error!)
                      : listState.isEmpty
                          ? _buildEmptyState()
                          : _buildList(listState),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateNew,
        backgroundColor: KolabingColors.primary,
        foregroundColor: KolabingColors.onPrimary,
        child: const Icon(LucideIcons.plus),
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
              'MY KOLABS',
              style: GoogleFonts.rubik(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              'Create and manage your kolabs',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatusTabs(String? currentStatus) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
          ),
          children: _statusTabs.map((tab) {
            final isSelected = currentStatus == tab.value;
            return Padding(
              padding: const EdgeInsets.only(right: KolabingSpacing.xs),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(myOpportunitiesStatusProvider.notifier)
                        .setStatus(tab.value);
                  },
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
                    child: Text(
                      tab.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? KolabingColors.onPrimary
                            : KolabingColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildList(OpportunityListState listState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            child: Text(
              '${listState.total} ${listState.total == 1 ? 'kolab' : 'kolabs'}',
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: KolabingColors.primary,
              onRefresh: () async {
                await ref.read(myOpportunitiesProvider.notifier).refresh();
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
                  return MyOpportunityCard(
                    opportunity: opportunity,
                    onEdit: () => _onEdit(opportunity),
                    onPublish: opportunity.id != null
                        ? () => _onPublish(opportunity.id!)
                        : null,
                    onClose: opportunity.id != null
                        ? () => _onClose(opportunity.id!)
                        : null,
                    onDelete: opportunity.id != null
                        ? () => _onDelete(opportunity.id!)
                        : null,
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
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: Shimmer.fromColors(
                baseColor: KolabingColors.surfaceVariant,
                highlightColor: KolabingColors.surface,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: KolabingColors.surface,
                    borderRadius: KolabingRadius.borderRadiusLg,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: KolabingColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(
                    LucideIcons.star,
                    size: 36,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'No kolabs yet',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'Create your first kolab and start connecting.',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              ElevatedButton.icon(
                onPressed: _onCreateNew,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Create Kolab'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  ref.read(myOpportunitiesProvider.notifier).refresh();
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
