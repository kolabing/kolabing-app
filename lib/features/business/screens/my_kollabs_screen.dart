import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../kolab/models/kolab.dart';
import '../../kolab/providers/my_kolabs_provider.dart';
import '../../kolab/widgets/my_kolab_card.dart';
import '../../kolab/widgets/my_kolabs_sub_tabs.dart';
import '../../opportunity/utils/opportunity_share.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../providers/profile_provider.dart';

/// My Kollabs screen for business users
///
/// Shows the business user's own kollabs (opportunities) with status tabs,
/// management actions, pull-to-refresh, and pagination.
/// Reuses the same providers as Community's MyOpportunitiesScreen since
/// the API returns results based on user type.
class MyKollabsScreen extends ConsumerStatefulWidget {
  const MyKollabsScreen({super.key, this.embedded = false});

  /// When true, renders only the status tabs + list (no Scaffold or page
  /// header) so it can be the "Offers" tab inside [MyKolabsHubScreen].
  final bool embedded;

  @override
  ConsumerState<MyKollabsScreen> createState() => _MyKollabsScreenState();
}

class _MyKollabsScreenState extends ConsumerState<MyKollabsScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final TabController _statusTabController;

  static const _statusTabs = [
    (label: 'Published', value: 'published'),
    (label: 'Draft', value: 'draft'),
  ];

  String _statusTabLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context);
    return switch (value) {
      'draft' => l10n.myKolabsTabDraft,
      _ => l10n.myKolabsTabPublished,
    };
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _statusTabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    )..addListener(_onStatusTabChange);
  }

  @override
  void dispose() {
    _statusTabController
      ..removeListener(_onStatusTabChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(myKolabsProvider.notifier).loadMore();
    }
  }

  void _onStatusTabChange() {
    if (!_statusTabController.indexIsChanging) {
      ref
          .read(myKolabsStatusProvider.notifier)
          .setStatus(_statusTabs[_statusTabController.index].value);
    }
  }

  Future<void> _onCreateNew() async {
    // B1 (2026-05-22): route all NEW creation through the unified /kolab/flow
    // via /kolab/new (IntentSelectionScreen). The subscription gate for a
    // non-subscribed business is enforced inside IntentSelectionScreen
    // (_LockedBusinessCreateState), so we no longer pre-gate here.
    await context.push(KolabingRoutes.kolabNew);
  }

  void _onEdit(Kolab kolab) {
    final id = kolab.id;
    if (id == null || id.isEmpty) {
      return;
    }

    context.push(KolabingRoutes.kolabFlow, extra: kolab);
  }

  /// Preview the kolab's public detail (same route the legacy Offers card used;
  /// the id resolves through the opportunity bridge).
  void _onView(Kolab kolab) {
    final id = kolab.id;
    if (id == null || id.isEmpty) {
      return;
    }
    context.push('/opportunity/$id');
  }

  Future<void> _onShare(Kolab kolab) async {
    final id = kolab.id;
    if (id == null || id.isEmpty) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.share(
      buildOpportunityShareMessage(
        title: kolab.title.isNotEmpty
            ? kolab.title
            : AppLocalizations.of(context).myKolabCardUntitled,
        opportunityId: id,
      ),
      sharePositionOrigin: origin,
    );
  }

  Future<void> _onPublish(String id) async {
    final success = await ref.read(myKolabsProvider.notifier).publish(id);
    if (mounted) {
      final state = ref.read(myKolabsProvider);
      final errorMessage =
          state.error ?? AppLocalizations.of(context).myKolabsPublishFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppLocalizations.of(context).myKolabsPublished
                : errorMessage,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? context.colors.success
              : context.colors.error,
        ),
      );
    }
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myKolabsProvider.notifier).close(id);
    if (mounted) {
      final state = ref.read(myKolabsProvider);
      final errorMessage =
          state.error ?? AppLocalizations.of(context).myKolabsCloseFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppLocalizations.of(context).myKolabsClosed
                : errorMessage,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success
              ? context.colors.success
              : context.colors.error,
        ),
      );
    }
  }

  Future<void> _onDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).myKolabsDeleteTitle),
        content: Text(AppLocalizations.of(context).myKolabsDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(AppLocalizations.of(context).myKolabsDelete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final success = await ref.read(myKolabsProvider.notifier).delete(id);
      if (mounted) {
        final state = ref.read(myKolabsProvider);
        final errorMessage =
            state.error ?? AppLocalizations.of(context).myKolabsDeleteFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context).myKolabsDeleted
                  : errorMessage,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: success
                ? context.colors.success
                : context.colors.error,
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

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (standalone only; the hub provides its own title)
        if (!widget.embedded) _buildHeader(isDark),

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
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.surface
          : context.colors.background,
      body: SafeArea(child: body),
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
          AppLocalizations.of(context).myKolabsTitle,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark
                ? context.colors.textOnDark
                : context.colors.onSurface,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          AppLocalizations.of(context).myKolabsSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusTabs(String? currentStatus, bool isDark) {
    final selectedIndex = _statusTabs.indexWhere(
      (t) => t.value == currentStatus,
    );
    if (selectedIndex >= 0 &&
        _statusTabController.index != selectedIndex &&
        !_statusTabController.indexIsChanging) {
      _statusTabController.index = selectedIndex;
    }

    return MyKolabsSubTabs(
      controller: _statusTabController,
      labels: _statusTabs
          .map((t) => _statusTabLabel(context, t.value).toUpperCase())
          .toList(),
    );
  }

  Widget _buildList(MyKolabsState listState, bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          10,
          KolabingSpacing.md,
          16,
        ),
        child: Text(
          AppLocalizations.of(context).myKolabsCount(listState.total),
          style: KolabingTextStyles.captionSecondary.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark
                ? context.colors.textOnDark.withValues(alpha: 0.5)
                : context.colors.textTertiary,
          ),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          color: context.colors.primary,
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
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(KolabingSpacing.md),
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final kolab = listState.kolabs[index];
              return MyKolabCard(
                kolab: kolab,
                onView: kolab.id != null ? () => _onView(kolab) : null,
                onEdit: () => _onEdit(kolab),
                onShare: kolab.id != null ? () => _onShare(kolab) : null,
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
                ? context.colors.darkSurface
                : context.colors.surfaceVariant,
            highlightColor: isDark
                ? context.colors.darkBorder
                : context.colors.surface,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? context.colors.darkSurface
                    : context.colors.surface,
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
                  ? context.colors.darkSurface
                  : context.colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Icon(
                LucideIcons.briefcase,
                size: 36,
                color: isDark
                    ? context.colors.textOnDark.withValues(alpha: 0.5)
                    : context.colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).myKolabsEmptyTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? context.colors.textOnDark
                  : context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            AppLocalizations.of(context).myKolabsEmptyMessage,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.errorBg,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Icon(
                LucideIcons.alertCircle,
                size: 36,
                color: context.colors.error,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).myKolabsSomethingWrong,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? context.colors.textOnDark
                  : context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(myKolabsProvider.notifier).refresh();
            },
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text(AppLocalizations.of(context).myKolabsTryAgain),
          ),
        ],
      ),
    ),
  );
}
