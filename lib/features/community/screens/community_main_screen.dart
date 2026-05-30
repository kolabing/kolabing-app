import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../../widgets/ui_icon.dart';
import '../../application/providers/application_provider.dart';
import '../../application/screens/applications_screen.dart';
import '../../business/screens/explore_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/community_dashboard_screen.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../rewards/providers/wallet_provider.dart';
import '../../rewards/widgets/badge_celebration_overlay.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import 'community_profile_screen.dart';
import 'my_opportunities_screen.dart';

/// Community user main screen with bottom navigation
///
/// This is the main container for community users after login.
/// Contains 5 tabs: Home, Explore, My Kolabs, Applications, Profile
class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({super.key, this.initialTab = 0});

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
    final allowed = await SubscriptionPaywall.checkAndShow(context, ref);
    if (!allowed || !mounted) {
      return;
    }

    await context.push(KolabingRoutes.communityOpportunitiesNew);
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ref
          ..invalidate(dashboardProvider)
          ..invalidate(myOpportunitiesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show badge celebration overlay whenever new badges are unlocked.
    // Clear newlyEarnedBadges immediately (before the overlay shows) so that
    // any subsequent wallet reload does not re-trigger the listener.
    ref.listen<WalletState>(walletProvider, (_, next) {
      if (next.newlyEarnedBadges.isEmpty) return;
      final badge = next.badges.firstWhere(
        (b) => b.slug == next.newlyEarnedBadges.first,
        orElse: () => next.badges.first,
      );
      ref.read(walletProvider.notifier).clearNewBadges();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        BadgeCelebrationOverlay.show(context, badge, () {});
      });
    });

    // Badge counts from providers
    final dashboardState = ref.watch(dashboardProvider);
    final pendingSentCount =
        dashboardState.communityData?.applicationsSent.pending ?? 0;
    final pendingReceivedCount =
        dashboardState.communityData?.applicationsReceived.pending ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final badgeCount = pendingSentCount + pendingReceivedCount + totalUnread;

    final navItems = [
      const NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: 'Home',
        iconSlug: UiIconSlug.home,
      ),
      const NavItem(
        icon: LucideIcons.compass,
        activeIcon: LucideIcons.compass,
        label: 'Explore',
        iconSlug: UiIconSlug.compass,
      ),
      const NavItem(
        icon: LucideIcons.star,
        activeIcon: LucideIcons.star,
        label: 'My Kolabs',
        iconSlug: UiIconSlug.star,
      ),
      NavItem(
        icon: LucideIcons.send,
        activeIcon: LucideIcons.send,
        label: 'Applications',
        badgeCount: badgeCount > 0 ? badgeCount : null,
        iconSlug: UiIconSlug.send,
      ),
      const NavItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: 'Profile',
        iconSlug: UiIconSlug.user,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.surface
          : KolabingColors.background,
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
      floatingActionButton:
          _currentIndex != 4 &&
              _currentIndex !=
                  2 // Hide on profile and My Kolabs tabs
          ? KolabingFAB(
              onPressed: _onFabPressed,
              tooltip: 'Create Opportunity',
              heroTag: 'community_main_fab',
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
  Widget build(BuildContext context) =>
      CommunityDashboardScreen(onSwitchTab: onSwitchTab);
}

class _CommunityExploreTab extends StatelessWidget {
  const _CommunityExploreTab();

  @override
  Widget build(BuildContext context) =>
      // Reuse the ExploreScreen from business feature
      // Lock to business creator type so community users only see business offers
      const ExploreScreen(
        detailRoutePrefix: '/community/explore/offer',
        lockedCreatorType: 'business',
      );
}

class _CommunityMyOppsTab extends StatelessWidget {
  const _CommunityMyOppsTab();

  @override
  Widget build(BuildContext context) => const MyOpportunitiesScreen();
}

class _CommunityApplicationsTab extends StatelessWidget {
  const _CommunityApplicationsTab();

  @override
  Widget build(BuildContext context) => const ApplicationsScreen();
}

class _CommunityProfileTab extends StatelessWidget {
  const _CommunityProfileTab();

  @override
  Widget build(BuildContext context) => const CommunityProfileScreen();
}

// -----------------------------------------------------------------------------
// ---------------------------------------------------------------------------
