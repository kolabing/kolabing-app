import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../auth/providers/auth_provider.dart';
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
  const CommunityDashboardScreen({super.key});

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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: KolabingColors.primary,
        child: _buildBody(dashboardState, userName),
      ),
    );
  }

  Widget _buildBody(DashboardState dashboardState, String userName) {
    // Loading state
    if (dashboardState.isLoading && !dashboardState.isInitialized) {
      return const DashboardShimmer();
    }

    // Error state
    if (dashboardState.error != null && !dashboardState.hasData) {
      return _buildErrorState(dashboardState.error!);
    }

    final data = dashboardState.communityData;

    // No data fallback
    if (data == null) {
      return _buildErrorState('Unable to load dashboard data');
    }

    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        // Header
        _buildHeader(userName),
        const SizedBox(height: KolabingSpacing.lg),

        // Stats grid 2x2
        _buildStatsGrid(data),
        const SizedBox(height: KolabingSpacing.lg),

        // Quick actions
        _buildQuickActions(),
        const SizedBox(height: KolabingSpacing.lg),

        // Upcoming collaborations
        _buildUpcomingSection(data),
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMUNITY DASHBOARD',
          style: GoogleFonts.rubik(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        // Primary button: BROWSE OPPORTUNITIES
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to explore tab - this would be handled by
                // the parent tab controller in the main screen.
                // For standalone navigation, we could go to explore route.
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
                'BROWSE OPPS',
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
                // Navigate to applications tab in the parent main screen
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'APPLICATIONS',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
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

  Widget _buildUpcomingSection(CommunityDashboard data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING COLLABORATIONS',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        if (data.upcomingCollaborations.isEmpty)
          _buildEmptyUpcoming()
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

  Widget _buildEmptyUpcoming() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
      child: Column(
        children: [
          Icon(
            LucideIcons.calendar,
            size: 40,
            color: KolabingColors.textTertiary,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'No upcoming collaborations yet',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: KolabingColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String message) {
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
