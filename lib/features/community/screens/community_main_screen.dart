import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../application/screens/applications_screen.dart';
import '../../business/screens/explore_screen.dart';
import '../../dashboard/screens/community_dashboard_screen.dart';
import 'community_profile_screen.dart';
import 'my_opportunities_screen.dart';
import '../../../config/theme/colors.dart';
import '../../../widgets/navigation/navigation.dart';

/// Community user main screen with bottom navigation
///
/// This is the main container for community users after login.
/// Contains 5 tabs: Home, Explore, My Opps, Applications, Profile
class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({
    super.key,
    this.initialTab = 0,
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

  void _onFabPressed() {
    context.push(KolabingRoutes.communityOpportunitiesNew);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual badge counts from providers
    const int unreadApplicationUpdates = 0;
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
        label: 'My Opps',
      ),
      NavItem(
        icon: LucideIcons.send,
        activeIcon: LucideIcons.send,
        label: 'Applications',
        badgeCount:
            unreadApplicationUpdates > 0 ? unreadApplicationUpdates : null,
      ),
      NavItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: 'Profile',
        showDot: hasIncompleteProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _CommunityHomeTab(),
          _CommunityExploreTab(),
          _CommunityMyOppsTab(),
          _CommunityApplicationsTab(),
          _CommunityProfileTab(),
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
  const _CommunityHomeTab();

  @override
  Widget build(BuildContext context) {
    return const CommunityDashboardScreen();
  }
}

class _CommunityExploreTab extends StatelessWidget {
  const _CommunityExploreTab();

  @override
  Widget build(BuildContext context) {
    // Reuse the ExploreScreen from business feature
    // API automatically returns business opportunities for community users
    return const ExploreScreen(
      detailRoutePrefix: '/community/explore/offer',
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
