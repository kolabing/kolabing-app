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
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../community/widgets/my_opportunity_card.dart';
import '../../kolab/models/kolab.dart';
import '../../kolab/providers/my_kolabs_provider.dart';
import '../../kolab/widgets/my_kolab_card.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';

/// "Listed Offers" tab of the Applications screen.
///
/// Shows the signed-in user's OWN posts (the content that used to live in the
/// "My Kolabs" screens). Role-aware: a business reuses [myKolabsProvider] +
/// [MyKolabCard]; a community reuses [myOpportunitiesProvider] +
/// [MyOpportunityCard]. Both share the same status filter chips
/// (Published / Draft / Cancelled) and a "Create Kolab" CTA.
///
/// "Cancelled" is a UI label only: it filters/uses the existing `'closed'`
/// status value. No backend or enum change.
class ListedOffersTab extends ConsumerWidget {
  const ListedOffersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusiness = ref.watch(authProvider).user?.isBusiness ?? false;
    return isBusiness
        ? const _BusinessListedOffers()
        : const _CommunityListedOffers();
  }
}

// =============================================================================
// Status filter chips (shared) — Published / Draft / Cancelled
// =============================================================================

/// Status chips. The value is the backend status string; "Cancelled" maps to
/// the existing `'closed'` value (UI relabel only).
const _statusChips = <({String label, String? value})>[
  (label: 'Published', value: 'published'),
  (label: 'Draft', value: 'draft'),
  (label: 'Cancelled', value: 'closed'),
];

Widget _buildStatusChips({
  required String? currentStatus,
  required bool isDark,
  required ValueChanged<String?> onSelect,
}) => SizedBox(
  height: 44,
  child: ListView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
    children: _statusChips.map((chip) {
      final isSelected = currentStatus == chip.value;
      return Padding(
        padding: const EdgeInsets.only(right: KolabingSpacing.xs),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(chip.value),
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
              child: Text(
                chip.label,
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
            ),
          ),
        ),
      );
    }).toList(),
  ),
);

/// "Create Kolab" CTA shown at the top of the Listed Offers tab, in addition to
/// the screen's global FAB.
Widget _buildCreateCta({
  required bool isDark,
  required VoidCallback onPressed,
}) => Padding(
  padding: const EdgeInsets.fromLTRB(
    KolabingSpacing.md,
    KolabingSpacing.xs,
    KolabingSpacing.md,
    0,
  ),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.plus, size: 18),
      label: const Text('Create Kolab'),
      style: ElevatedButton.styleFrom(
        backgroundColor: KolabingColors.primary,
        foregroundColor: KolabingColors.onPrimary,
      ),
    ),
  ),
);

// =============================================================================
// Business listed offers — reuses myKolabsProvider + MyKolabCard
// =============================================================================

class _BusinessListedOffers extends ConsumerStatefulWidget {
  const _BusinessListedOffers();

  @override
  ConsumerState<_BusinessListedOffers> createState() =>
      _BusinessListedOffersState();
}

class _BusinessListedOffersState extends ConsumerState<_BusinessListedOffers> {
  final _scrollController = ScrollController();

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
      ref.read(myKolabsProvider.notifier).loadMore();
    }
  }

  Future<void> _onCreateNew() async {
    await context.push(KolabingRoutes.kolabNew);
  }

  void _onEdit(Kolab kolab) {
    final id = kolab.id;
    if (id == null || id.isEmpty) {
      return;
    }
    context.push(KolabingRoutes.kolabFlow, extra: kolab);
  }

  Future<void> _onPublish(String id) async {
    final success = await ref.read(myKolabsProvider.notifier).publish(id);
    if (mounted) {
      final state = ref.read(myKolabsProvider);
      _showSnackbar(
        success ? 'Kolab published!' : state.error ?? 'Failed to publish',
        success,
      );
    }
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myKolabsProvider.notifier).close(id);
    if (mounted) {
      final state = ref.read(myKolabsProvider);
      _showSnackbar(
        success ? 'Kolab cancelled' : state.error ?? 'Failed to cancel',
        success,
      );
    }
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Kolab'),
        content: const Text(
          'Are you sure you want to delete this kolab? This action cannot be undone.',
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

    if (confirmed ?? false) {
      final success = await ref.read(myKolabsProvider.notifier).delete(id);
      if (mounted) {
        final state = ref.read(myKolabsProvider);
        _showSnackbar(
          success ? 'Kolab deleted' : state.error ?? 'Failed to delete',
          success,
        );
      }
    }
  }

  void _showSnackbar(String message, bool isSuccess) {
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
    final listState = ref.watch(myKolabsProvider);
    final currentStatus = ref.watch(myKolabsStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<MyKolabsState>(myKolabsProvider, (previous, next) async {
      if (next.requiresSubscription &&
          !(previous?.requiresSubscription ?? false)) {
        ref.read(myKolabsProvider.notifier).clearSubscriptionRequirement();
        final allowed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SubscriptionPaywall(),
        );
        if ((allowed ?? false) && mounted) {
          await ref.read(profileProvider.notifier).refreshSubscription();
          await ref.read(myKolabsProvider.notifier).refresh();
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: KolabingSpacing.xs),
        _buildCreateCta(isDark: isDark, onPressed: _onCreateNew),
        const SizedBox(height: KolabingSpacing.xs),
        _buildStatusChips(
          currentStatus: currentStatus,
          isDark: isDark,
          onSelect: (value) =>
              ref.read(myKolabsStatusProvider.notifier).setStatus(value),
        ),
        Expanded(
          child: listState.isLoading
              ? _buildLoadingState(isDark)
              : listState.error != null
              ? _buildErrorState(
                  listState.error!,
                  isDark,
                  () => ref.read(myKolabsProvider.notifier).refresh(),
                )
              : listState.isEmpty
              ? _buildEmptyState(isDark, _onCreateNew)
              : _buildList(listState, isDark),
        ),
      ],
    );
  }

  Widget _buildList(MyKolabsState listState, bool isDark) => RefreshIndicator(
    color: KolabingColors.primary,
    onRefresh: () => ref.read(myKolabsProvider.notifier).refresh(),
    child: ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.sm,
        KolabingSpacing.md,
        KolabingSpacing.xxl,
      ),
      itemCount: listState.kolabs.length + (listState.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= listState.kolabs.length) {
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
        final kolab = listState.kolabs[index];
        return MyKolabCard(
          kolab: kolab,
          onEdit: () => _onEdit(kolab),
          onPublish: kolab.id != null ? () => _onPublish(kolab.id!) : null,
          onClose: kolab.id != null ? () => _onClose(kolab.id!) : null,
          onDelete: kolab.id != null ? () => _onDelete(kolab.id!) : null,
        );
      },
    ),
  );
}

// =============================================================================
// Community listed offers — reuses myOpportunitiesProvider + MyOpportunityCard
// =============================================================================

class _CommunityListedOffers extends ConsumerStatefulWidget {
  const _CommunityListedOffers();

  @override
  ConsumerState<_CommunityListedOffers> createState() =>
      _CommunityListedOffersState();
}

class _CommunityListedOffersState
    extends ConsumerState<_CommunityListedOffers> {
  final _scrollController = ScrollController();

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

  Future<void> _onCreateNew() async {
    await context.push(KolabingRoutes.kolabNew);
    if (!mounted) {
      return;
    }
    ref.invalidate(myOpportunitiesProvider);
  }

  void _onEdit(Opportunity opportunity) {
    final opportunityId = opportunity.id;
    if (opportunityId == null || opportunityId.isEmpty) {
      return;
    }
    context.push(
      KolabingRoutes.buildCommunityOpportunityEditPath(opportunityId),
      extra: opportunity,
    );
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
    _showSnackbar(
      success ? 'Kolab published!' : state.error ?? 'Failed to publish Kolab',
      success,
    );
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myOpportunitiesProvider.notifier).close(id);
    if (!mounted) {
      return;
    }
    final state = ref.read(myOpportunitiesProvider);
    _showSnackbar(
      success ? 'Kolab cancelled' : state.error ?? 'Failed to cancel Kolab',
      success,
    );
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Kolab'),
        content: const Text(
          'Are you sure you want to delete this Kolab? This action cannot be undone.',
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
    _showSnackbar(
      success ? 'Kolab deleted' : state.error ?? 'Failed to delete Kolab',
      success,
    );
  }

  void _showSnackbar(String message, bool isSuccess) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: KolabingSpacing.xs),
        _buildCreateCta(isDark: isDark, onPressed: _onCreateNew),
        const SizedBox(height: KolabingSpacing.xs),
        _buildStatusChips(
          currentStatus: currentStatus,
          isDark: isDark,
          onSelect: (value) =>
              ref.read(myOpportunitiesStatusProvider.notifier).status = value,
        ),
        Expanded(
          child: listState.isLoading
              ? _buildLoadingState(isDark)
              : listState.error != null
              ? _buildErrorState(
                  listState.error!,
                  isDark,
                  () => ref.read(myOpportunitiesProvider.notifier).refresh(),
                )
              : listState.isEmpty
              ? _buildEmptyState(isDark, _onCreateNew)
              : _buildList(listState, isDark),
        ),
      ],
    );
  }

  Widget _buildList(OpportunityListState listState, bool isDark) =>
      RefreshIndicator(
        color: KolabingColors.primary,
        onRefresh: () => ref.read(myOpportunitiesProvider.notifier).refresh(),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            KolabingSpacing.sm,
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
              onClose: opportunity.id != null
                  ? () => _onClose(opportunity.id!)
                  : null,
              onDelete: opportunity.id != null
                  ? () => _onDelete(opportunity.id!)
                  : null,
            );
          },
        ),
      );
}

// =============================================================================
// Shared state widgets
// =============================================================================

Widget _buildLoadingState(bool isDark) => SingleChildScrollView(
  padding: const EdgeInsets.all(KolabingSpacing.md),
  child: Column(
    children: List.generate(
      3,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
        child: Shimmer.fromColors(
          baseColor: isDark
              ? KolabingColors.darkSurface
              : KolabingColors.surfaceVariant,
          highlightColor: isDark
              ? KolabingColors.darkBorder
              : KolabingColors.surface,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? KolabingColors.darkSurface
                  : KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusLg,
            ),
          ),
        ),
      ),
    ),
  ),
);

Widget _buildEmptyState(bool isDark, VoidCallback onCreate) => Center(
  child: Padding(
    padding: const EdgeInsets.all(KolabingSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
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
              LucideIcons.briefcase,
              size: 36,
              color: isDark
                  ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                  : KolabingColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          'No kolabs yet',
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
          'Create your first kolab to start connecting.',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        ElevatedButton.icon(
          onPressed: onCreate,
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

Widget _buildErrorState(String error, bool isDark, VoidCallback onRetry) =>
    Center(
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
              onPressed: onRetry,
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
