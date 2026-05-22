import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../collaboration/providers/collaborations_list_provider.dart';
import '../../collaboration/widgets/collaboration_list_card.dart';

/// My Kolabs screen for community users.
///
/// Repurposed (2026-05-22): instead of the community's own POSTS, this screen
/// now shows the community's COLLABORATIONS (the accepted matches) with two
/// sub-tabs — Active (scheduled / in-progress) and Finished (completed only).
/// Tapping a collaboration opens `/collaboration/:id`, where the finish /
/// mark-complete flow lives. Own-posts creation moved to the Applications tab.
/// Communities are never gated (ROLES-AND-PERMISSIONS §1).
class MyOpportunitiesScreen extends ConsumerStatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  ConsumerState<MyOpportunitiesScreen> createState() =>
      _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState extends ConsumerState<MyOpportunitiesScreen> {
  CollaborationsFilter _filter = CollaborationsFilter.active;

  void _openDetail(String id) {
    context.push('/collaboration/$id');
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(collaborationsListProvider(_filter));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSubTabs(),
            Expanded(
              child: asyncItems.when(
                data: (items) =>
                    items.isEmpty ? _buildEmptyState() : _buildList(items),
                loading: _buildLoadingState,
                error: (error, _) => _buildErrorState('$error'),
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
          'MY KOLABS',
          style: KolabingTextStyles.pageTitle.copyWith(
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Your active and finished collaborations',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: KolabingColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _buildSubTabs() => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.xs,
      KolabingSpacing.md,
      KolabingSpacing.xs,
    ),
    child: Row(
      children: [
        _SubTab(
          label: 'Active',
          isSelected: _filter == CollaborationsFilter.active,
          onTap: () => setState(() => _filter = CollaborationsFilter.active),
        ),
        const SizedBox(width: KolabingSpacing.xs),
        _SubTab(
          label: 'Finished',
          isSelected: _filter == CollaborationsFilter.finished,
          onTap: () => setState(() => _filter = CollaborationsFilter.finished),
        ),
      ],
    ),
  );

  Widget _buildList(List<CollaborationListItem> items) => RefreshIndicator(
    color: KolabingColors.primary,
    onRefresh: () async {
      ref.invalidate(collaborationsListProvider(_filter));
      await ref.read(collaborationsListProvider(_filter).future);
    },
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.sm,
        KolabingSpacing.md,
        KolabingSpacing.xxl,
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return CollaborationListCard(
          item: item,
          onTap: () => _openDetail(item.id),
        );
      },
    ),
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
              height: 88,
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
                LucideIcons.heartHandshake,
                size: 36,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            _filter == CollaborationsFilter.active
                ? 'No active collaborations'
                : 'No finished collaborations',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            _filter == CollaborationsFilter.active
                ? 'When an application is accepted, the collaboration shows up here.'
                : 'Completed collaborations will appear here.',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
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
              ref.invalidate(collaborationsListProvider(_filter));
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

class _SubTab extends StatelessWidget {
  const _SubTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
            color: isSelected ? KolabingColors.primary : KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusRound,
            border: Border.all(
              color: isSelected
                  ? KolabingColors.primary
                  : KolabingColors.border,
            ),
          ),
          child: Text(
            label,
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
    );
  }
}
