import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/navigation/kolabing_app_bar.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../../widgets/ui_icon.dart';
import '../../application/providers/application_provider.dart';
import '../../business/screens/explore_screen.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chats_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/community_dashboard_screen.dart';
import '../../kolab/screens/my_kolabs_hub_screen.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../rewards/providers/wallet_provider.dart';
import '../../rewards/widgets/badge_celebration_overlay.dart';
import 'community_hub_screen.dart';
import 'my_opportunities_screen.dart';

/// Community user main screen with bottom navigation
///
/// This is the main container for community users after login.
/// 5 tabs: Home, Explore, My Kolabs (Offers/Requests/Active/Finished), Chats,
/// Community (roster + tiers — NF-6). Profile moved off the nav (NF-12) — reached
/// via the app-bar avatar. The former Applications tab is the "Requests" sub-tab
/// inside My Kolabs.
class CommunityMainScreen extends ConsumerStatefulWidget {
  const CommunityMainScreen({
    super.key,
    this.initialTab = 0,
    this.initialKolabsSubTab = 0,
  });

  final int initialTab;

  /// Sub-tab to open inside My Kolabs (0 Offers, 1 Requests, 2 Active,
  /// 3 Finished). Used by deep links to the legacy /applications route.
  final int initialKolabsSubTab;

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
    // Communities are never paywalled (the paywall is Business-only). Creating an
    // opportunity is always allowed here — no subscription gate.
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

    final l10n = AppLocalizations.of(context);
    final chatUnread = ref.watch(chatUnreadProvider);
    final navItems = [
      NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: l10n.communityMainNavHome,
        iconSlug: UiIconSlug.home,
      ),
      NavItem(
        icon: LucideIcons.compass,
        activeIcon: LucideIcons.compass,
        label: l10n.communityMainNavExplore,
        iconSlug: UiIconSlug.compass,
      ),
      NavItem(
        icon: LucideIcons.star,
        activeIcon: LucideIcons.star,
        label: l10n.communityMainNavMyKolabs,
        badgeCount: badgeCount > 0 ? badgeCount : null,
        iconSlug: UiIconSlug.star,
      ),
      NavItem(
        // Chats promoted to the nav (NF-12), placed before Community per the IA.
        // TODO(i18n): localize when chat strings are localized.
        icon: LucideIcons.messageCircle,
        activeIcon: LucideIcons.messageCircle,
        label: 'Chats',
        badgeCount: chatUnread > 0 ? chatUnread : null,
      ),
      NavItem(
        // Flag (chapter/club banner) reads as the community hub and is clearly
        // distinct from the lone-person Profile icon — they were near-identical
        // when both used users/user.
        icon: LucideIcons.flag,
        activeIcon: LucideIcons.flag,
        label: l10n.communityMainNavCommunity,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.surface
          : KolabingColors.background,
      appBar: const KolabingAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _CommunityHomeTab(onSwitchTab: _onTabChanged),
          const _CommunityExploreTab(),
          _CommunityMyOppsTab(initialSubTab: widget.initialKolabsSubTab),
          const ChatsScreen(embedded: true),
          const CommunityHubScreen(),
        ],
      ),
      floatingActionButton:
          // Create-Opportunity FAB only on Home (0) / Explore (1). Hidden on
          // My Kolabs (2), Chats (3), and Community (4).
          _currentIndex < 2
          ? KolabingFAB(
              onPressed: _onFabPressed,
              tooltip: l10n.communityMainCreateOpportunityTooltip,
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
  const _CommunityMyOppsTab({this.initialSubTab = 0});

  final int initialSubTab;

  @override
  Widget build(BuildContext context) => MyKolabsHubScreen(
    offersTab: const MyOpportunitiesScreen(embedded: true),
    initialSubTab: initialSubTab,
  );
}

// -----------------------------------------------------------------------------
// ---------------------------------------------------------------------------
