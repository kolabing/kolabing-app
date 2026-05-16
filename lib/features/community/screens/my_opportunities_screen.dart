import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../opportunity/utils/opportunity_share.dart';
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

class _MyOpportunitiesScreenState extends ConsumerState<MyOpportunitiesScreen> {
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
    context.push(KolabingRoutes.communityOpportunitiesNew);
  }

  void _onEdit(Opportunity opportunity) {
    context.push(KolabingRoutes.communityOpportunitiesEdit, extra: opportunity);
  }

  void _onView(Opportunity opportunity) {
    final id = opportunity.id;
    if (id == null || id.isEmpty) {
      return;
    }
    context.push('/opportunity/$id');
  }

  Future<void> _onPublish(String id) async {
    final success = await ref
        .read(myOpportunitiesProvider.notifier)
        .publish(id);
    if (!mounted) {
      return;
    }

    final state = ref.read(myOpportunitiesProvider);
    final errorMessage = state.error ?? 'Failed to publish opportunity';
    _showSnackbar(
      message: success ? 'Opportunity published!' : errorMessage,
      isSuccess: success,
    );
  }

  Future<void> _shareOpportunity(Opportunity opportunity) async {
    final opportunityId = opportunity.id;
    if (opportunityId == null || opportunityId.isEmpty) {
      return;
    }

    await Share.share(
      buildOpportunityShareMessage(
        title: opportunity.title,
        opportunityId: opportunityId,
      ),
    );
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myOpportunitiesProvider.notifier).close(id);
    if (!mounted) {
      return;
    }

    final state = ref.read(myOpportunitiesProvider);
    final errorMessage = state.error ?? 'Failed to close opportunity';
    _showSnackbar(
      message: success ? 'Opportunity closed' : errorMessage,
      isSuccess: success,
    );
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Opportunity'),
        content: const Text(
          'Are you sure you want to delete this opportunity? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false)) {
      return;
    }

    final success = await ref.read(myOpportunitiesProvider.notifier).delete(id);
    if (!mounted) {
      return;
    }

    final state = ref.read(myOpportunitiesProvider);
    final errorMessage = state.error ?? 'Failed to delete opportunity';
    _showSnackbar(
      message: success ? 'Opportunity deleted' : errorMessage,
      isSuccess: success,
    );
  }

  void _showSnackbar({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess
            ? KolabingColors.success
            : KolabingColors.error,
      ),
    );
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
            _buildHeader(),
            _buildStatusTabs(currentStatus),
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
      floatingActionButton: KolabingFAB(
        onPressed: _onCreateNew,
        tooltip: 'Create New Opportunity',
        heroTag: 'community_my_opportunities_fab',
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
          'MY OPPORTUNITIES',
          style: KolabingTextStyles.pageTitle.copyWith(
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Create and manage your opportunities',
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
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
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
          '${listState.total} ${listState.total == 1 ? 'opportunity' : 'opportunities'}',
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
            itemCount:
                listState.opportunities.length +
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
                onView: opportunity.status == OpportunityStatus.published
                    ? () => _onView(opportunity)
                    : null,
                onEdit: () => _onEdit(opportunity),
                onPublish: opportunity.id != null
                    ? () => _onPublish(opportunity.id!)
                    : null,
                onShare: opportunity.id != null
                    ? () => _shareOpportunity(opportunity)
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
            'No opportunities yet',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'Create your first opportunity and start connecting.',
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
            label: const Text('Create Opportunity'),
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
          ElevatedButton(
            onPressed: () {
              ref.read(myOpportunitiesProvider.notifier).refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}
