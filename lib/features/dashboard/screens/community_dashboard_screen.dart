import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/widgets/notification_bell.dart';
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
    final userName = authState.user?.displayName ?? 'Community';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: KolabingColors.primary,
        child: _buildBody(dashboardState, userName, isDark),
      ),
    );
  }

  Widget _buildBody(DashboardState dashboardState, String userName, bool isDark) {
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
      return _buildErrorState('Unable to load dashboard data', isDark);
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
                'COMMUNITY DASHBOARD',
                style: GoogleFonts.rubik(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                'Welcome back, $userName',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: KolabingColors.textSecondary,
                ),
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
                title: 'Pending Applications',
                count: data.applicationsSent.pending,
                icon: LucideIcons.clock,
                accentColor: const Color(0xFFFF9800),
                subtitle: '${data.applicationsSent.total} total sent',
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                title: 'Accepted',
                count: data.applicationsSent.accepted,
                icon: LucideIcons.checkCircle,
                accentColor: const Color(0xFF4CAF50),
                subtitle: '${data.applicationsSent.declined} declined',
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                title: 'Active Collabs',
                count: data.collaborations.active,
                icon: LucideIcons.users,
                accentColor: KolabingColors.info,
                subtitle: '${data.collaborations.upcoming} upcoming',
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                title: 'Completed',
                count: data.collaborations.completed,
                icon: LucideIcons.trophy,
                accentColor: const Color(0xFF9C27B0),
                subtitle: '${data.collaborations.total} total',
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
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'FIND A COLLAB',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
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
                    ? KolabingColors.textOnDark
                    : KolabingColors.textPrimary,
                side: BorderSide(
                  color:
                      isDark ? KolabingColors.darkBorder : KolabingColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'MY APPLICATIONS',
                  maxLines: 1,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
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
          'UPCOMING COLLABORATIONS',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary,
            letterSpacing: 0.8,
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
      child: Column(
        children: [
          Icon(
            LucideIcons.calendar,
            size: 40,
            color: isDark
                ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                : KolabingColors.textTertiary,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'No upcoming collaborations yet',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                  : KolabingColors.textTertiary,
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
              color: KolabingColors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              message,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textSecondary,
              ),
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
                  'RETRY',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
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
