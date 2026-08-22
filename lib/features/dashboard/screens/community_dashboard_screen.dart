import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/ui_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/navigation/profile_avatar_button.dart';
import '../../notification/widgets/notification_bell.dart';
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
    final authState = ref.watch(authProvider);
    final userName =
        authState.user?.displayName ??
        AppLocalizations.of(context).dashboardDefaultCommunityName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.colors.primary,
        child: _buildBody(dashboardState, userName, isDark),
      ),
    );
  }

  Widget _buildBody(
    DashboardState dashboardState,
    String userName,
    bool isDark,
  ) {
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
      // Extra bottom inset so the create-opportunity FAB (56dp + margin)
      // never covers the last card / quick-action buttons when scrolled to
      // the end.
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md + 88,
      ),
      children: [
        _buildHeader(userName, isDark),
        const SizedBox(height: KolabingSpacing.lg),
        ..._buildDashboardContent(data, isDark),
        const SizedBox(height: KolabingSpacing.xl),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String userName, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageTitle(AppLocalizations.of(context).dashboardCommunityTitle),
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                AppLocalizations.of(context).dashboardWelcomeBack(userName),
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const NotificationBell(),
        const SizedBox(width: KolabingSpacing.xs),
        const ProfileAvatarButton(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard content
  // ---------------------------------------------------------------------------

  List<Widget> _buildDashboardContent(CommunityDashboard data, bool isDark) {
    return [
      // Marketplace first: Find a Kolab / My applications stay above the
      // fold; all gamification content (XP, missions, badges, referral)
      // renders below the marketplace sections.

      // 1. Quick actions
      _buildQuickActions(isDark),
      const SizedBox(height: KolabingSpacing.lg),

      // 2. Upcoming kolabs
      _buildUpcomingSection(data, isDark),
      const SizedBox(height: KolabingSpacing.lg),

      // 3. Compact stats strip
      CommunityStatsStrip(
        pending: data.applicationsSent.pending,
        accepted: data.applicationsSent.accepted,
        active: data.collaborations.active,
        completed: data.collaborations.completed,
      ),
      const SizedBox(height: KolabingSpacing.lg),

      // 4. XP summary card (sage green, non-tappable)
      const CommunityXpSummaryCard(),
      const SizedBox(height: KolabingSpacing.lg),

      // 5. Today's XP missions
      const XpMissionsSection(),
      const SizedBox(height: KolabingSpacing.lg),

      // 6. Badges row (earned badges only)
      const DashboardBadgesRow(),
      const SizedBox(height: KolabingSpacing.lg),

      // 7. Referral card — compact nudge; the full €75 hero card lives in
      // the wallet/referral surfaces, not the dashboard.
      const ReferralBannerCard(compact: true),
    ];
  }

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(bool isDark) => Row(
    children: [
      Expanded(
        child: KolabingButton(
          label: AppLocalizations.of(context).dashboardFindAKolab,
          onPressed: () => widget.onSwitchTab?.call(1),
          variant: KolabingButtonVariant.primary,
          size: KolabingButtonSize.compact,
          icon: const Icon(LucideIcons.search),
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: KolabingButton(
          label: AppLocalizations.of(context).dashboardMyApplications,
          onPressed: () => widget.onSwitchTab?.call(3),
          variant: KolabingButtonVariant.secondary,
          size: KolabingButtonSize.compact,
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
            KolabingButton(
              label: AppLocalizations.of(context).commonRetry,
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              variant: KolabingButtonVariant.primary,
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
        ),
      ),
    );
  }
}
