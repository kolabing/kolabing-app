import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../application/providers/application_provider.dart';
import '../../application/screens/applications_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/business_dashboard_screen.dart';
import 'business_profile_screen.dart';
import 'explore_screen.dart';
import 'my_kollabs_screen.dart';

/// Business user main screen with bottom navigation
///
/// This is the main container for business users after login.
/// Contains 5 tabs: Home, Explore, My Kollabs, Applications, Profile
class BusinessMainScreen extends ConsumerStatefulWidget {
  const BusinessMainScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  ConsumerState<BusinessMainScreen> createState() => _BusinessMainScreenState();
}

class _BusinessMainScreenState extends ConsumerState<BusinessMainScreen> {
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
    await context.push(KolabingRoutes.businessOffersNew);
    // Refresh dashboard stats when returning from create form
    if (mounted) {
      ref.read(dashboardProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Badge counts from providers
    final dashboardState = ref.watch(dashboardProvider);
    final pendingApplicationsCount =
        dashboardState.businessData?.applicationsReceived.pending ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final badgeCount = pendingApplicationsCount + totalUnread;
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
        icon: LucideIcons.briefcase,
        activeIcon: LucideIcons.briefcase,
        label: 'My Kollabs',
      ),
      NavItem(
        icon: LucideIcons.inbox,
        activeIcon: LucideIcons.inbox,
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
          _BusinessHomeTab(onSwitchTab: _onTabChanged),
          const _BusinessExploreTab(),
          const _BusinessKollabsTab(),
          const _BusinessApplicationsTab(),
          const _BusinessProfileTab(),
        ],
      ),
      floatingActionButton: _currentIndex != 4 // Hide on profile tab
          ? KolabingFAB(
              onPressed: _onFabPressed,
              tooltip: 'Create Collab Request',
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
// Tab Screens
// -----------------------------------------------------------------------------

class _BusinessHomeTab extends StatelessWidget {
  const _BusinessHomeTab({required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return BusinessDashboardScreen(onSwitchTab: onSwitchTab);
  }
}

class _BusinessExploreTab extends StatelessWidget {
  const _BusinessExploreTab();

  @override
  Widget build(BuildContext context) {
    return const ExploreScreen();
  }
}

class _BusinessKollabsTab extends StatelessWidget {
  const _BusinessKollabsTab();

  @override
  Widget build(BuildContext context) {
    return const MyKollabsScreen();
  }
}

class _BusinessApplicationsTab extends StatelessWidget {
  const _BusinessApplicationsTab();

  @override
  Widget build(BuildContext context) {
    return const ApplicationsScreen();
  }
}

class _BusinessProfileTab extends StatelessWidget {
  const _BusinessProfileTab();

  @override
  Widget build(BuildContext context) {
    return const BusinessProfileScreen();
  }
}
