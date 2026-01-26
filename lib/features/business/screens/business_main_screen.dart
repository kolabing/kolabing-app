import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../widgets/navigation/navigation.dart';
import 'business_profile_screen.dart';
import 'explore_screen.dart';

/// Business user main screen with bottom navigation
///
/// This is the main container for business users after login.
/// Contains 4 tabs: Explore, My Offers, Applications, Profile
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

  void _onFabPressed() {
    context.push(KolabingRoutes.businessOffersNew);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual badge counts from providers
    const int pendingApplicationsCount = 0;
    const bool hasIncompleteProfile = false;

    final navItems = [
      const NavItem(
        icon: LucideIcons.compass,
        activeIcon: LucideIcons.compass,
        label: 'Explore',
      ),
      const NavItem(
        icon: LucideIcons.briefcase,
        activeIcon: LucideIcons.briefcase,
        label: 'My Offers',
      ),
      NavItem(
        icon: LucideIcons.inbox,
        activeIcon: LucideIcons.inbox,
        label: 'Applications',
        badgeCount: pendingApplicationsCount > 0 ? pendingApplicationsCount : null,
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
          _BusinessExploreTab(),
          _BusinessOffersTab(),
          _BusinessApplicationsTab(),
          _BusinessProfileTab(),
        ],
      ),
      floatingActionButton: _currentIndex != 3 // Hide on profile tab
          ? KolabingFAB(
              onPressed: _onFabPressed,
              tooltip: 'Create Offer',
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

class _BusinessExploreTab extends StatelessWidget {
  const _BusinessExploreTab();

  @override
  Widget build(BuildContext context) {
    return const ExploreScreen();
  }
}

class _BusinessOffersTab extends StatelessWidget {
  const _BusinessOffersTab();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      icon: LucideIcons.briefcase,
      title: 'My Offers',
      subtitle: 'Manage your collaboration offers',
    );
  }
}

class _BusinessApplicationsTab extends StatelessWidget {
  const _BusinessApplicationsTab();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      icon: LucideIcons.inbox,
      title: 'Applications',
      subtitle: 'Review applications from communities',
    );
  }
}

class _BusinessProfileTab extends StatelessWidget {
  const _BusinessProfileTab();

  @override
  Widget build(BuildContext context) {
    return const BusinessProfileScreen();
  }
}

// -----------------------------------------------------------------------------
// Shared Placeholder Widget
// -----------------------------------------------------------------------------

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: KolabingColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: KolabingColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 12,
                color: KolabingColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
