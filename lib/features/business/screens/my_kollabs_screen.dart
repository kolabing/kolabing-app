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
import '../../kolab/models/kolab.dart';
import '../../kolab/providers/my_kolabs_provider.dart';
import '../../kolab/widgets/my_kolab_card.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../providers/profile_provider.dart';

/// My Kollabs screen for business users
///
/// Shows the business user's own kollabs (opportunities) with status tabs,
/// management actions, pull-to-refresh, and pagination.
/// Reuses the same providers as Community's MyOpportunitiesScreen since
/// the API returns results based on user type.
class MyKollabsScreen extends ConsumerStatefulWidget {
  const MyKollabsScreen({super.key});

  @override
  ConsumerState<MyKollabsScreen> createState() => _MyKollabsScreenState();
}

class _MyKollabsScreenState extends ConsumerState<MyKollabsScreen> {
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
      ref.read(myKolabsProvider.notifier).loadMore();
    }
  }

  void _onCreateNew() {
    final profileState = ref.read(profileProvider);
    final listState = ref.read(myKolabsProvider);

    // Free tier: 1 kollab allowed without subscription.
    // If no active subscription and already has 1+ kollab, show paywall.
    final hasSubscription = profileState.isSubscribed;
    if (!hasSubscription && !listState.isLoading && listState.total >= 1) {
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SubscriptionPaywall(),
      );
      return;
    }

    context.push(KolabingRoutes.kolabNew);
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
      final errorMessage = state.error ?? 'Failed to publish';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kollab published!' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? KolabingColors.success
              : KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myKolabsProvider.notifier).close(id);
    if (mounted) {
      final state = ref.read(myKolabsProvider);
      final errorMessage = state.error ?? 'Failed to close';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Kollab closed' : errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? KolabingColors.success
              : KolabingColors.error,
        ),
      );
    }
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Kollab'),
        content: const Text(
          'Are you sure you want to delete this kollab? This action cannot be undone.',
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
        final errorMessage = state.error ?? 'Failed to delete';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Kollab deleted' : errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: success
                ? KolabingColors.success
                : KolabingColors.error,
          ),
        );
      }
    }
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

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.darkBackground
          : KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isDark),

            // Status tabs
            _buildStatusTabs(currentStatus, isDark),

            // List
            Expanded(
              child: listState.isLoading
                  ? _buildLoadingState(isDark)
                  : listState.error != null
                  ? _buildErrorState(listState.error!, isDark)
                  : listState.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildList(listState, isDark),
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
      KolabingSpacing.md,
      KolabingSpacing.xs,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MY KOLLABS',
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
          'Manage your kollabs',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: KolabingColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusTabs(String? currentStatus, bool isDark) => SizedBox(
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
                ref.read(myKolabsStatusProvider.notifier).setStatus(tab.value);
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
                  tab.label,
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

  Widget _buildList(MyKolabsState listState, bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.sm,
        ),
        child: Text(
          '${listState.total} ${listState.total == 1 ? 'kollab' : 'kollabs'}',
          style: GoogleFonts.openSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark
                ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                : KolabingColors.textTertiary,
          ),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          color: KolabingColors.primary,
          onRefresh: () async {
            await ref.read(myKolabsProvider.notifier).refresh();
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
                listState.kolabs.length + (listState.isLoadingMore ? 1 : 0),
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
                onPublish: kolab.id != null
                    ? () => _onPublish(kolab.id!)
                    : null,
                onClose: kolab.id != null ? () => _onClose(kolab.id!) : null,
                onDelete: kolab.id != null ? () => _onDelete(kolab.id!) : null,
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

  Widget _buildEmptyState(bool isDark) => Center(
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
            'No kollabs yet',
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
            'Create your first kollab to start connecting with communities',
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
            label: const Text('Create Kollab'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorState(String error, bool isDark) => Center(
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
            onPressed: () {
              ref.read(myKolabsProvider.notifier).refresh();
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
