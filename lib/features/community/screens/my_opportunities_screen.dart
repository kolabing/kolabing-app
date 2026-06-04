import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../widgets/navigation/navigation.dart';
import '../../business/providers/profile_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../opportunity/utils/opportunity_share.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../widgets/my_opportunity_card.dart';

typedef OpportunityShareInvoker =
    Future<ShareResult> Function(String text, {Rect? sharePositionOrigin});
typedef OpportunityShareCopyText = Future<void> Function(String text);
typedef ShowSubscriptionPaywall = Future<bool?> Function(BuildContext context);

/// My Opportunities screen for community users
///
/// Shows the user's own opportunities with status tabs,
/// management actions, pull-to-refresh, and pagination.
class MyOpportunitiesScreen extends ConsumerStatefulWidget {
  const MyOpportunitiesScreen({
    super.key,
    this.share = Share.share,
    this.copyText = _copyText,
    this.showSubscriptionPaywall = _showSubscriptionPaywall,
    this.embedded = false,
  });

  final OpportunityShareInvoker share;
  final OpportunityShareCopyText copyText;
  final ShowSubscriptionPaywall showSubscriptionPaywall;

  /// When true, renders only the status tabs + list (no Scaffold, page header
  /// or FAB) so it can be the "Offers" tab inside [MyKolabsHubScreen].
  final bool embedded;

  static Future<void> _copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  static Future<bool?> _showSubscriptionPaywall(BuildContext context) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SubscriptionPaywall(),
      );

  @override
  ConsumerState<MyOpportunitiesScreen> createState() =>
      _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState extends ConsumerState<MyOpportunitiesScreen> {
  final _scrollController = ScrollController();

  static const _statusTabs = [
    (value: 'published'),
    (value: 'draft'),
  ];

  String _statusTabLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'draft':
        return l10n.myOpportunitiesTabDraft;
      case 'published':
      default:
        return l10n.myOpportunitiesTabPublished;
    }
  }

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
    // B1 (2026-05-22): all NEW creation goes through the unified /kolab/flow
    // via /kolab/new (IntentSelectionScreen). Role gating lives there:
    // communities get the FREE communitySeeking option and are NEVER
    // paywalled (ROLES-AND-PERMISSIONS golden rule 1); a non-subscribed
    // business sees the upgrade prompt inside the intent screen. We therefore
    // do NOT show a paywall here.
    await context.push(KolabingRoutes.kolabNew);
    if (!mounted) {
      return;
    }
    // Refresh the dashboard counts and the opportunities list so a freshly
    // created kolab shows up immediately on return.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ref
        ..invalidate(dashboardProvider)
        ..invalidate(myOpportunitiesProvider);
    }
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

    final l10n = AppLocalizations.of(context);
    final state = ref.read(myOpportunitiesProvider);
    final errorMessage = state.error ?? l10n.myOpportunitiesPublishError;
    _showSnackbar(
      message: success ? l10n.myOpportunitiesPublishSuccess : errorMessage,
      isSuccess: success,
    );
  }

  Future<void> _shareOpportunity(Opportunity opportunity) async {
    final opportunityId = opportunity.id;
    if (opportunityId == null || opportunityId.isEmpty) {
      return;
    }

    final shareMessage = buildOpportunityShareMessage(
      title: opportunity.title,
      opportunityId: opportunityId,
    );
    final opportunityUrl = buildOpportunityShareUri(opportunityId).toString();
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      final result = await widget.share(
        shareMessage,
        sharePositionOrigin: shareOrigin,
      );
      if (result.status == ShareResultStatus.unavailable) {
        await widget.copyText(opportunityUrl);
        if (!mounted) {
          return;
        }
        _showSnackbar(
          message: AppLocalizations.of(context).myOpportunitiesShareUnavailable,
          isSuccess: true,
        );
      }
    } on Exception {
      if (!mounted) {
        return;
      }
      _showSnackbar(
        message: AppLocalizations.of(context).myOpportunitiesShareFailed,
        isSuccess: false,
      );
    }
  }

  Future<void> _onClose(String id) async {
    final success = await ref.read(myOpportunitiesProvider.notifier).close(id);
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final state = ref.read(myOpportunitiesProvider);
    final errorMessage = state.error ?? l10n.myOpportunitiesCloseError;
    _showSnackbar(
      message: success ? l10n.myOpportunitiesCloseSuccess : errorMessage,
      isSuccess: success,
    );
  }

  Future<void> _onDelete(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dialogL10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(dialogL10n.myOpportunitiesDeleteTitle),
          content: Text(dialogL10n.myOpportunitiesDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dialogL10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style:
                  TextButton.styleFrom(foregroundColor: KolabingColors.error),
              child: Text(dialogL10n.myOpportunitiesDeleteConfirm),
            ),
          ],
        );
      },
    );

    if (!(confirmed ?? false)) {
      return;
    }

    final success = await ref.read(myOpportunitiesProvider.notifier).delete(id);
    if (!mounted) {
      return;
    }

    final state = ref.read(myOpportunitiesProvider);
    final errorMessage = state.error ?? l10n.myOpportunitiesDeleteError;
    _showSnackbar(
      message: success ? l10n.myOpportunitiesDeleteSuccess : errorMessage,
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

    ref.listen<OpportunityListState>(myOpportunitiesProvider, (
      previous,
      next,
    ) async {
      if (next.requiresSubscription &&
          !(previous?.requiresSubscription ?? false)) {
        ref
            .read(myOpportunitiesProvider.notifier)
            .clearSubscriptionRequirement();
        final allowed = await widget.showSubscriptionPaywall(context);
        if ((allowed ?? false) && mounted) {
          await ref.read(profileProvider.notifier).refreshSubscription();
          await ref.read(myOpportunitiesProvider.notifier).refresh();
        }
      }
    });

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) _buildHeader(),
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
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(child: body),
      floatingActionButton: KolabingFAB(
        onPressed: _onCreateNew,
        tooltip: AppLocalizations.of(context).myOpportunitiesCreateNewTooltip,
        heroTag: 'community_my_opportunities_fab',
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
          l10n.myOpportunitiesHeaderTitle,
          style: KolabingTextStyles.pageTitle.copyWith(
            color: KolabingColors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.myOpportunitiesHeaderSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
        ),
      ],
    ),
  );
  }

  Widget _buildStatusTabs(String? currentStatus) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
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
                ref.read(myOpportunitiesStatusProvider.notifier).status =
                    tab.value;
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
                        : KolabingColors.darkBorder,
                  ),
                ),
                child: Text(
                  _statusTabLabel(l10n, tab.value),
                  style: KolabingTextStyles.button.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected
                        ? KolabingColors.onPrimary
                        : KolabingColors.onSurface),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
  }

  Widget _buildList(OpportunityListState listState) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.sm,
        ),
        child: Text(
          AppLocalizations.of(context).myOpportunitiesCount(listState.total),
          style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w500, color: KolabingColors.textTertiary),
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

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
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
            l10n.myOpportunitiesEmptyTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.myOpportunitiesEmptyBody,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: _onCreateNew,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.myOpportunitiesEmptyCreateButton),
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

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context);
    return Center(
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
            l10n.myOpportunitiesErrorTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
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
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    ),
  );
  }
}
