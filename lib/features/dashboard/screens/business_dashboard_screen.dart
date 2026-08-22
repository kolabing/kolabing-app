import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/ui_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/navigation/profile_avatar_button.dart';
import '../../notification/widgets/notification_bell.dart';
import '../../rewards/providers/wallet_provider.dart';
import '../../rewards/widgets/referral_banner_card.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/monthly_goal_card.dart';
import '../widgets/next_action_card.dart';
import '../widgets/partner_status_badge.dart';
import '../widgets/upcoming_collaboration_card.dart';

// Design tokens for the "Business Activity" hero card — matches the
// Community Dashboard's yellow card language, minus the game-like elements
// (no progress bar, no level badge).
const _cardBg = Color(0xFFFFE28C);
const _inkDark = Color(0xFF19150F);
const _mutedLabel = Color(0xFF9A7C28);

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
      // Also load wallet data so the referral code is available for the
      // compact referral card (same provider the Community Dashboard uses).
      final walletState = ref.read(walletProvider);
      if (walletState.wallet == null && !walletState.isLoading) {
        ref.read(walletProvider.notifier).load();
      }
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardProvider.notifier).refresh();
  }

  Future<void> _onCreateKolab() async {
    final allowed = await SubscriptionPaywall.checkAndShow(context, ref);
    if (!allowed || !mounted) return;
    await context.push(KolabingRoutes.kolabNew);
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) ref.invalidate(dashboardProvider);
    }
  }

  /// Maps a next-action `key` to an in-app destination. Keys without a known
  /// destination render as informational-only (no CTA) rather than a guessed
  /// route.
  VoidCallback? _onNextActionTap(NextAction action) {
    switch (action.key) {
      case 'create_first_offer':
      case 'create_second_offer':
        return _onCreateKolab;
      case 'complete_profile':
        // Profile is tab 4 of BusinessMainScreen (no GoRoute binds it), so
        // switch tabs in the shell rather than navigate.
        return widget.onSwitchTab == null ? null : () => widget.onSwitchTab!(4);
      case 'review_pending_applications':
        return () => context.go(KolabingRoutes.businessApplications);
      case 'leave_review':
        return () => context.go(KolabingRoutes.businessFinished);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final userName =
        authState.user?.displayName ??
        AppLocalizations.of(context).dashboardDefaultBusinessName;
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
        // Header
        _buildHeader(userName, isDark),
        if (data.partnerStatus != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
          PartnerStatusBadge(partnerStatus: data.partnerStatus),
        ],
        const SizedBox(height: KolabingSpacing.sm),

        // Positioning message
        _buildPositioningMessage(),
        const SizedBox(height: KolabingSpacing.lg),

        // Next best action — the single most useful thing to do right now
        if (data.nextAction != null) ...[
          NextActionCard(
            nextAction: data.nextAction,
            onTap: _onNextActionTap(data.nextAction!),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],

        // Monthly collaboration goal — progress only, never a broken streak
        if (data.monthlyGoal != null) ...[
          MonthlyGoalCard(monthlyGoal: data.monthlyGoal),
          const SizedBox(height: KolabingSpacing.lg),
        ],

        // Main yellow "Business Activity" card
        _buildActivityHeroCard(data),
        const SizedBox(height: KolabingSpacing.lg),

        // Grow Your Business — action cards
        _buildGrowSection(data),
        const SizedBox(height: KolabingSpacing.lg),

        // Referral — compact secondary card
        const ReferralBannerCard(compact: true),
        const SizedBox(height: KolabingSpacing.lg),

        // Upcoming collaborations
        _buildUpcomingSection(data, isDark),
        const SizedBox(height: KolabingSpacing.xl),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String userName, bool isDark) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitle(AppLocalizations.of(context).dashboardBusinessTitle),
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

  // ---------------------------------------------------------------------------
  // Positioning message (static display copy)
  // ---------------------------------------------------------------------------

  Widget _buildPositioningMessage() => Padding(
    padding: const EdgeInsets.only(right: KolabingSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).dashboardPositioningTitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context).dashboardPositioningSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: context.colors.textTertiary,
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Main yellow "Business Activity" hero card
  // ---------------------------------------------------------------------------

  Widget _buildActivityHeroCard(BusinessDashboard data) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top-left black pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: const BoxDecoration(
            color: _inkDark,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          child: Text(
            AppLocalizations.of(context).dashboardActivityPillLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _cardBg,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        // Main number: live/published offers
        Text(
          '${data.opportunities.published}',
          style: KolabingTextStyles.statNumber.copyWith(
            fontSize: 40,
            color: _inkDark,
            height: 0.9,
          ),
        ),
        Text(
          AppLocalizations.of(context).dashboardLiveOffersLabel,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _mutedLabel,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: KolabingSpacing.sm),

        // Supporting stats
        Row(
          children: [
            _HeroMiniStat(
              count: data.applicationsReceived.pending,
              label: AppLocalizations.of(context).dashboardNewAppsLabel,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            _HeroMiniStat(
              count: data.collaborations.active,
              label: AppLocalizations.of(context).dashboardActiveStatLabel,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            _HeroMiniStat(
              count: data.collaborations.completed,
              label: AppLocalizations.of(context).dashboardCompletedStatLabel,
            ),
          ],
        ),

        const SizedBox(height: KolabingSpacing.sm),

        KolabingButton(
          label: AppLocalizations.of(context).dashboardHeroCreateKolabButton,
          onPressed: _onCreateKolab,
          variant: KolabingButtonVariant.dark,
          height: 42,
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Grow Your Business — action cards
  // ---------------------------------------------------------------------------

  Widget _buildGrowSection(BusinessDashboard data) {
    final pending = data.applicationsReceived.pending;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardGrowSectionTitle,
          style: KolabingTextStyles.labelLarge.copyWith(
            color: context.colors.onSurface,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        _GrowActionCard(
          icon: LucideIcons.plus,
          title: l10n.dashboardGrowCreateTitle,
          subtitle: l10n.dashboardGrowCreateSubtitle,
          onTap: _onCreateKolab,
        ),
        const SizedBox(height: KolabingSpacing.xs),
        _GrowActionCard(
          icon: LucideIcons.inbox,
          title: l10n.dashboardGrowReviewTitle,
          subtitle: pending > 0
              ? l10n.dashboardGrowReviewSubtitlePending(pending)
              : l10n.dashboardGrowReviewSubtitleEmpty,
          onTap: () => widget.onSwitchTab?.call(2),
          highlighted: pending > 0,
          badgeCount: pending > 0 ? pending : null,
        ),
        const SizedBox(height: KolabingSpacing.xs),
        _GrowActionCard(
          icon: LucideIcons.search,
          title: l10n.dashboardFindAKolab,
          subtitle: l10n.dashboardGrowFindSubtitle,
          onTap: () => widget.onSwitchTab?.call(1),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        _GrowActionCard(
          icon: LucideIcons.users,
          title: l10n.dashboardGrowViewKolabsTitle,
          subtitle: l10n.dashboardGrowViewKolabsSubtitle(
            data.collaborations.active,
            data.collaborations.completed,
          ),
          onTap: () => widget.onSwitchTab?.call(2),
        ),
      ],
    );
  }

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
    padding: const EdgeInsets.all(KolabingSpacing.lg),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      border: Border.all(color: context.colors.hairline),
    ),
    child: Column(
      children: [
        UiIcon(
          icon: UiIconSlug.calendar,
          size: 32,
          color: isDark
              ? context.colors.textOnDark.withValues(alpha: 0.5)
              : context.colors.textTertiary,
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Text(
          AppLocalizations.of(context).dashboardNoUpcomingKolabs,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context).dashboardEmptyUpcomingSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: context.colors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: KolabingSpacing.md),
        KolabingButton(
          label: AppLocalizations.of(context).dashboardCreateKolabRequest,
          onPressed: _onCreateKolab,
          variant: KolabingButtonVariant.secondary,
          size: KolabingButtonSize.compact,
          icon: const Icon(LucideIcons.plus),
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

// ---------------------------------------------------------------------------
// Local widgets — used exclusively by the Business Dashboard
// ---------------------------------------------------------------------------

/// Small supporting stat inside the yellow hero card.
class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: _inkDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: KolabingTextStyles.statNumber.copyWith(
              fontSize: 17,
              color: _inkDark,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _mutedLabel,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ),
  );
}

/// White rounded action card used in the "Grow Your Business" section.
class _GrowActionCard extends StatelessWidget {
  const _GrowActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: highlighted ? c.softYellow : c.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(
              color: highlighted ? c.softYellowBorder : c.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 17, color: c.onSurface),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: c.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badgeCount != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: _inkDark,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _cardBg,
                    ),
                  ),
                ),
                const SizedBox(width: KolabingSpacing.xs),
              ],
              Icon(LucideIcons.chevronRight, size: 18, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
