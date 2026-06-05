import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../widgets/ui_icon.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/widgets/notification_bell.dart';
import '../../rewards/widgets/xp_progress_card.dart';
import '../../rewards/widgets/referral_banner_card.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/upcoming_collaboration_card.dart';

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
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.displayName ?? AppLocalizations.of(context).dashboardDefaultCommunityName;
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
      return _buildErrorState(AppLocalizations.of(context).dashboardErrorLoad, isDark);
    }

    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        // Header
        _buildHeader(userName, isDark),
        const SizedBox(height: KolabingSpacing.lg),

        // Stats grid 2x2
        _buildStatsGrid(data),
        const SizedBox(height: KolabingSpacing.lg),

        // Referral banner first — community-growth action
        const ReferralBannerCard(),
        const SizedBox(height: KolabingSpacing.md),

        // XP progress card
        XpProgressCard(
          onTap: () => context.push(KolabingRoutes.communityWallet),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Quick actions
        _buildQuickActions(isDark),
        const SizedBox(height: KolabingSpacing.lg),

        // Upcoming collaborations
        _buildUpcomingSection(data, isDark),
        const SizedBox(height: KolabingSpacing.lg),
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
              Text(
                AppLocalizations.of(context).dashboardCommunityTitle,
                style: KolabingTextStyles.headlineLarge.copyWith(
                  color: isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                AppLocalizations.of(context).dashboardWelcomeBack(userName),
                style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const NotificationBell(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Grid
  // ---------------------------------------------------------------------------

  Widget _buildStatsGrid(CommunityDashboard data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: AppLocalizations.of(context).dashboardStatPending,
                count: data.applicationsSent.pending,
                icon: LucideIcons.clock,
                iconSlug: UiIconSlug.clock,
                iconVariant: UiIconVariant.expressive,
                accentColor: const Color(0xFFFF9800),
                index: 0,
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                title: AppLocalizations.of(context).dashboardStatAccepted,
                count: data.applicationsSent.accepted,
                icon: LucideIcons.checkCircle,
                iconSlug: UiIconSlug.checkCircle,
                iconVariant: UiIconVariant.expressive,
                accentColor: const Color(0xFF4CAF50),
                index: 1,
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
                iconSlug: UiIconSlug.target,
                iconVariant: UiIconVariant.expressive,
                accentColor: context.colors.info,
                index: 2,
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                title: AppLocalizations.of(context).dashboardStatCompleted,
                count: data.collaborations.completed,
                icon: LucideIcons.trophy,
                iconSlug: UiIconSlug.trophy,
                iconVariant: UiIconVariant.expressive,
                accentColor: const Color(0xFF9C27B0),
                index: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(bool isDark) {
    return Row(
      children: [
        // Primary button: FIND A COLLAB
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Switch to Explore tab (index 1)
                widget.onSwitchTab?.call(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).dashboardFindAKolab,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.0),
              ),
            ),
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),

        // Outlined button: MY APPLICATIONS
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                // Switch to Applications tab (index 3)
                widget.onSwitchTab?.call(3);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface,
                side: BorderSide(
                  color: isDark
                      ? context.colors.darkBorder
                      : context.colors.darkBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context).dashboardMyApplications,
                  maxLines: 1,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Upcoming Collaborations
  // ---------------------------------------------------------------------------

  Widget _buildUpcomingSection(CommunityDashboard data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).dashboardUpcomingKolabs,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF0D0D0D), letterSpacing: 0.8),
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
      child: Column(
        children: [
          UiIcon(
            icon: UiIconSlug.calendar,
            size: 40,
            color: isDark
                ? context.colors.textOnDark.withValues(alpha: 0.5)
                : context.colors.textTertiary,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            AppLocalizations.of(context).dashboardNoUpcomingKolabs,
            style: KolabingTextStyles.bodySmall.copyWith(color: isDark
                  ? context.colors.textOnDark.withValues(alpha: 0.5)
                  : context.colors.textTertiary),
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
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(dashboardProvider.notifier).refresh();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(
                  AppLocalizations.of(context).commonRetry,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
