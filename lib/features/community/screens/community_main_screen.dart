import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../application/providers/application_provider.dart';
import '../../application/screens/applications_screen.dart';
import '../../business/screens/explore_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/community_dashboard_screen.dart';
import 'community_profile_screen.dart';
import 'my_opportunities_screen.dart';

/// Community user main screen with bottom navigation
///
/// This is the main container for community users after login.
/// Contains 5 tabs: Home, Explore, My Kolabs, Applications, Profile
class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({
    super.key,
    this.initialTab = 1,
  });

  final int initialTab;

  @override
  ConsumerState<CommunityMainScreen> createState() =>
      _CommunityMainScreenState();
}

class _CommunityMainScreenState extends ConsumerState<CommunityMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _onFabPressed() async {
    await context.push(KolabingRoutes.kolabNew);
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ref.invalidate(dashboardProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Badge counts from providers
    final dashboardState = ref.watch(dashboardProvider);
    final pendingSentCount =
        dashboardState.communityData?.applicationsSent.pending ?? 0;
    final pendingReceivedCount =
        dashboardState.communityData?.applicationsReceived.pending ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final badgeCount = pendingSentCount + pendingReceivedCount + totalUnread;
    const bool hasIncompleteProfile = false;

    final navItems = [
      const NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: 'Home',
      ),
      const NavItem(
        icon: LucideIcons.compass,
        activeIcon: LucideIcons.compass,
        label: 'Explore',
      ),
      const NavItem(
        icon: LucideIcons.star,
        activeIcon: LucideIcons.star,
        label: 'My Kolabs',
      ),
      NavItem(
        icon: LucideIcons.send,
        activeIcon: LucideIcons.send,
        label: 'Applications',
        badgeCount: badgeCount > 0 ? badgeCount : null,
      ),
      NavItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: 'Profile',
        showDot: hasIncompleteProfile,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? KolabingColors.darkBackground : KolabingColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _CommunityHomeTab(onSwitchTab: _onTabChanged),
          const _CommunityExploreTab(),
          const _CommunityMyOppsTab(),
          const _CommunityApplicationsTab(),
          const _CommunityProfileTab(),
        ],
      ),
      floatingActionButton: _currentIndex != 4 // Hide on profile tab
          ? KolabingFAB(
              onPressed: _onFabPressed,
              tooltip: 'Create Opportunity',
            )
          : null,
      bottomNavigationBar: KolabingBottomNavBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab Screens (Placeholders)
// -----------------------------------------------------------------------------

class _CommunityHomeTab extends StatelessWidget {
  const _CommunityHomeTab({required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return CommunityDashboardScreen(onSwitchTab: onSwitchTab);
  }
}

class _CommunityExploreTab extends StatelessWidget {
  const _CommunityExploreTab();

  @override
  Widget build(BuildContext context) {
    // Reuse the ExploreScreen from business feature
    // Lock to business creator type so community users only see business offers
    return const ExploreScreen(
      detailRoutePrefix: '/community/explore/offer',
      lockedCreatorType: 'business',
    );
  }
}

class _CommunityMyOppsTab extends StatelessWidget {
  const _CommunityMyOppsTab();

  @override
  Widget build(BuildContext context) {
    return const MyOpportunitiesScreen();
  }
}

class _CommunityApplicationsTab extends StatelessWidget {
  const _CommunityApplicationsTab();

  @override
  Widget build(BuildContext context) {
    return const ApplicationsScreen();
  }
}

class _CommunityProfileTab extends StatelessWidget {
  const _CommunityProfileTab();

  @override
  Widget build(BuildContext context) {
    return const CommunityProfileScreen();
  }
}

// -----------------------------------------------------------------------------
// ---------------------------------------------------------------------------
