import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/glass_button.dart';
import '../../../widgets/ui_icon.dart';
import '../../../widgets/navigation/kolabing_main_app_bar.dart';
import '../../rewards/widgets/referral_banner_card.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/community_xp_summary_card.dart';
import '../widgets/community_stats_strip.dart';
import '../widgets/dashboard_badges_row.dart';
import '../widgets/xp_missions_section.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/upcoming_collaboration_card.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Local-only preview switch — change this constant to compare layouts.
/// Does not affect production builds.
enum DashboardPreviewVariant { optionA, optionB, optionC }

const _kDashboardVariant = DashboardPreviewVariant.optionB;

/// Community Dashboard Screen
///
/// Shows key metrics, quick actions, and upcoming collaborations
/// for community users.
class CommunityDashboardScreen extends ConsumerStatefulWidget {
  const CommunityDashboardScreen({super.key, this.onSwitchTab});

  /// Callback to switch tabs in the parent [CommunityMainScreen].
  final ValueChanged<int>? onSwitchTab;

  @override
  ConsumerState<CommunityDashboardScreen> createState() =>
      _CommunityDashboardScreenState();
}

class _CommunityDashboardScreenState
    extends ConsumerState<CommunityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load if not already loaded
    Future.microtask(() {
      final state = ref.read(dashboardProvider);
      if (!state.isInitialized && !state.isLoading) {
        ref.read(dashboardProvider.notifier).load();
      }
      // Also load wallet data so badges and XP are available on the dashboard.
      final walletState = ref.read(walletProvider);
      if (walletState.wallet == null && !walletState.isLoading) {
        ref.read(walletProvider.notifier).load();
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

    final data = dashboardState.communityData;

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
        ..._buildVariantContent(data, isDark),
        const SizedBox(height: KolabingSpacing.xl),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Variant dispatcher
  // ---------------------------------------------------------------------------

  List<Widget> _buildVariantContent(CommunityDashboard data, bool isDark) {
    switch (_kDashboardVariant) {
      case DashboardPreviewVariant.optionA:
        return _buildVariantA(data, isDark);
      case DashboardPreviewVariant.optionB:
        return _buildVariantB(data, isDark);
      case DashboardPreviewVariant.optionC:
        return _buildVariantC(data, isDark);
    }
  }

  List<Widget> _buildVariantB(CommunityDashboard data, bool isDark) {
    return [
      // 1. XP summary card (sage green, non-tappable)
      const CommunityXpSummaryCard(),
      const SizedBox(height: KolabingSpacing.lg),

      // 2. Today's XP missions
      const XpMissionsSection(),
      const SizedBox(height: KolabingSpacing.lg),

      // 3. Compact stats strip
      CommunityStatsStrip(
        pending: data.applicationsSent.pending,
        accepted: data.applicationsSent.accepted,
        active: data.collaborations.active,
        completed: data.collaborations.completed,
      ),
      const SizedBox(height: KolabingSpacing.lg),

      // 4. Badges row
      const DashboardBadgesRow(),
      const SizedBox(height: KolabingSpacing.lg),

      // 5. Referral card — pastel yellow style
      const ReferralBannerCard(usePastelStyle: true),
      const SizedBox(height: KolabingSpacing.lg),

      // 6. Quick actions
      _buildQuickActions(isDark),
      const SizedBox(height: KolabingSpacing.lg),

      // 7. Upcoming kolabs
      _buildUpcomingSection(data, isDark),
    ];
  }

  List<Widget> _buildVariantA(CommunityDashboard data, bool isDark) {
    return [
      const CommunityXpSummaryCard(),
      const SizedBox(height: KolabingSpacing.lg),
      const XpMissionsSection(),
      const SizedBox(height: KolabingSpacing.lg),
      CommunityStatsStrip(
        pending: data.applicationsSent.pending,
        accepted: data.applicationsSent.accepted,
        active: data.collaborations.active,
        completed: data.collaborations.completed,
      ),
      const SizedBox(height: KolabingSpacing.lg),
      const ReferralBannerCard(usePastelStyle: true),
      const SizedBox(height: KolabingSpacing.lg),
      _buildQuickActions(isDark),
      const SizedBox(height: KolabingSpacing.lg),
      _buildUpcomingSection(data, isDark),
    ];
  }

  List<Widget> _buildVariantC(CommunityDashboard data, bool isDark) {
    return [
      const CommunityXpSummaryCard(),
      const SizedBox(height: KolabingSpacing.lg),
      const XpMissionsSection(),
      const SizedBox(height: KolabingSpacing.lg),
      CommunityStatsStrip(
        pending: data.applicationsSent.pending,
        accepted: data.applicationsSent.accepted,
        active: data.collaborations.active,
        completed: data.collaborations.completed,
      ),
      const SizedBox(height: KolabingSpacing.lg),
      const DashboardBadgesRow(),
      const SizedBox(height: KolabingSpacing.lg),
      const ReferralBannerCard(usePastelStyle: true),
      const SizedBox(height: KolabingSpacing.lg),
      _buildQuickActions(isDark),
      const SizedBox(height: KolabingSpacing.lg),
      _buildUpcomingSection(data, isDark),
    ];
  }

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(bool isDark) => Row(
    children: [
      Expanded(
        child: GlassButton(
          label: AppLocalizations.of(context).dashboardFindAKolab,
          onPressed: () => widget.onSwitchTab?.call(1),
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.search,
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: GlassButton(
          label: AppLocalizations.of(context).dashboardMyApplications,
          onPressed: () => widget.onSwitchTab?.call(3),
          intent: GlassButtonIntent.neutral,
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Upcoming Collaborations
  // ---------------------------------------------------------------------------

  Widget _buildUpcomingSection(CommunityDashboard data, bool isDark) {
    return Column(
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
  }

  Widget _buildEmptyUpcoming(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: context.colors.hairline,
          width: 1.5,
          // Dashed border via CustomPainter would be ideal, but a solid hairline
          // border keeps the diff minimal while conveying the empty-state container.
        ),
      ),
      child: Column(
        children: [
          UiIcon(
            icon: UiIconSlug.calendar,
            size: 36,
            color: isDark
                ? context.colors.textOnDark.withValues(alpha: 0.5)
                : context.colors.textTertiary,
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
  }

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: context.colors.error,
            ),
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
}
