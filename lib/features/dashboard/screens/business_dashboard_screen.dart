import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/glass_button.dart';
import '../../../widgets/ui_icon.dart';
import '../../../widgets/navigation/kolabing_main_app_bar.dart';
import '../../rewards/widgets/referral_banner_card.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/upcoming_collaboration_card.dart';

/// Business Dashboard Screen
///
/// Shows key metrics, quick actions, and upcoming collaborations
/// for business users.
class BusinessDashboardScreen extends ConsumerStatefulWidget {
  const BusinessDashboardScreen({super.key, this.onSwitchTab});

  /// Callback to switch tabs in the parent [BusinessMainScreen].
  final ValueChanged<int>? onSwitchTab;

  @override
  ConsumerState<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState
    extends ConsumerState<BusinessDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load if not already loaded
    Future.microtask(() {
      final state = ref.read(dashboardProvider);
      if (!state.isInitialized && !state.isLoading) {
        ref.read(dashboardProvider.notifier).load();
      }
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          KolabingMainAppBar(
            title: AppLocalizations.of(context).communityMainNavHome,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: context.colors.primary,
              child: _buildBody(dashboardState, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DashboardState dashboardState, bool isDark) {
    // Loading state
    if (dashboardState.isLoading && !dashboardState.isInitialized) {
      return const DashboardShimmer();
    }

    // Error state
    if (dashboardState.error != null && !dashboardState.hasData) {
      return _buildErrorState(dashboardState.error!, isDark);
    }

    final data = dashboardState.businessData;

    // No data fallback
    if (data == null) {
      return _buildErrorState(
        AppLocalizations.of(context).dashboardErrorLoad,
        isDark,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        // Stats grid 2x2
        _buildStatsGrid(data),
        const SizedBox(height: KolabingSpacing.xl),

        // Referral banner (rewards)
        const ReferralBannerCard(),
        const SizedBox(height: KolabingSpacing.xl),

        // Quick actions
        _buildQuickActions(),
        const SizedBox(height: KolabingSpacing.xl),

        // Upcoming collaborations
        _buildUpcomingSection(data, isDark),
        const SizedBox(height: KolabingSpacing.xl),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Grid
  // ---------------------------------------------------------------------------

  Widget _buildStatsGrid(BusinessDashboard data) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: DashboardStatCard(
              title: AppLocalizations.of(context).dashboardStatPublished,
              count: data.opportunities.published,
              icon: LucideIcons.megaphone,
              accent: StatCardAccent.active,
              subtitle: '${data.opportunities.total} total requests',
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: DashboardStatCard(
              title: AppLocalizations.of(
                context,
              ).dashboardStatPendingApplications,
              count: data.applicationsReceived.pending,
              icon: LucideIcons.clock,
              iconSlug: UiIconSlug.clock,
              accent: StatCardAccent.pending,
              subtitle: '${data.applicationsReceived.total} total',
            ),
          ),
        ],
      ),
      const SizedBox(height: KolabingSpacing.sm),
      Row(
        children: [
          Expanded(
            child: DashboardStatCard(
              title: AppLocalizations.of(context).dashboardStatActiveKolabs,
              count: data.collaborations.active,
              icon: LucideIcons.users,
              accent: StatCardAccent.accepted,
              subtitle: '${data.collaborations.upcoming} upcoming',
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: DashboardStatCard(
              title: AppLocalizations.of(context).dashboardStatCompleted,
              count: data.collaborations.completed,
              icon: LucideIcons.checkCircle,
              iconSlug: UiIconSlug.checkCircle,
              accent: StatCardAccent.completed,
              subtitle: '${data.collaborations.total} total',
            ),
          ),
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions() => Row(
    children: [
      Expanded(
        child: GlassButton(
          label: AppLocalizations.of(context).dashboardCreateKolabRequest,
          onPressed: () async {
            final allowed = await SubscriptionPaywall.checkAndShow(
              context,
              ref,
            );
            if (!allowed || !mounted) return;
            await context.push(KolabingRoutes.kolabNew);
            if (mounted) {
              await Future<void>.delayed(const Duration(milliseconds: 300));
              if (mounted) ref.invalidate(dashboardProvider);
            }
          },
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.plus,
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: GlassButton(
          label: AppLocalizations.of(context).dashboardFindAKolab,
          onPressed: () => widget.onSwitchTab?.call(1),
          intent: GlassButtonIntent.neutral,
          icon: LucideIcons.search,
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Upcoming Collaborations
  // ---------------------------------------------------------------------------

  Widget _buildUpcomingSection(BusinessDashboard data, bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).dashboardUpcomingKolabs,
        style: KolabingTextStyles.labelLarge.copyWith(
          color: context.colors.onSurface,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(height: KolabingSpacing.sm),

      if (data.upcomingCollaborations.isEmpty)
        _buildEmptyUpcoming(isDark)
      else
        ...data.upcomingCollaborations.map<Widget>(
          (collab) => Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: UpcomingCollaborationCard(
              collaboration: collab,
              onTap: () {
                context.push('/collaboration/${collab.id}');
              },
            ),
          ),
        ),
    ],
  );

  Widget _buildEmptyUpcoming(bool isDark) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
    child: Column(
      children: [
        // Brand empty-state treatment: yellow glyph in a soft-yellow circle.
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: UiIcon(
              icon: UiIconSlug.calendar,
              size: 30,
              color: context.colors.primary,
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Text(
          AppLocalizations.of(context).dashboardNoUpcomingKolabs,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: isDark
                ? context.colors.textOnDark.withValues(alpha: 0.5)
                : context.colors.textTertiary,
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String message, bool isDark) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: context.colors.error),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            message,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          GlassButton(
            label: AppLocalizations.of(context).commonRetry,
            onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
            intent: GlassButtonIntent.primary,
            icon: LucideIcons.refreshCw,
          ),
        ],
      ),
    ),
  );
}
