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
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chats_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/screens/business_dashboard_screen.dart';
import '../../kolab/screens/my_kolabs_hub_screen.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import 'business_profile_screen.dart';
import 'explore_screen.dart';
import 'my_kollabs_screen.dart';

/// Business user main screen with bottom navigation
///
/// This is the main container for business users after login.
/// 5 tabs: Home, Explore, My Kolabs (Offers/Requests/Active/Finished), Chats,
/// Profile. The former Applications tab is now the "Requests" tab inside
/// My Kolabs.
class BusinessMainScreen extends ConsumerStatefulWidget {
  const BusinessMainScreen({
    super.key,
    this.initialTab = 0,
    this.initialKolabsSubTab = 0,
  });

  final int initialTab;

  /// Sub-tab to open inside My Kolabs (0 Offers, 1 Requests, 2 Active,
  /// 3 Finished). Used by deep links to the legacy /applications route.
  final int initialKolabsSubTab;

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
    final allowed = await SubscriptionPaywall.checkAndShow(context, ref);
    if (!allowed || !mounted) {
      return;
    }

    await context.push(KolabingRoutes.kolabNew);
    // Refresh dashboard stats when returning from create form
    if (mounted) {
      // Small delay to ensure dashboard widget is mounted after pop
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
    final pendingApplicationsCount =
        dashboardState.businessData?.applicationsReceived.pending ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final badgeCount = pendingApplicationsCount + totalUnread;

    final l10n = AppLocalizations.of(context);
    final chatUnread = ref.watch(chatUnreadProvider);
    final navItems = [
      NavItem(
        icon: LucideIcons.home,
        activeIcon: LucideIcons.home,
        label: l10n.businessNavHome,
        iconSlug: UiIconSlug.home,
      ),
      NavItem(
        icon: LucideIcons.compass,
        activeIcon: LucideIcons.compass,
        label: l10n.businessNavExplore,
        iconSlug: UiIconSlug.compass,
      ),
      NavItem(
        icon: LucideIcons.briefcase,
        activeIcon: LucideIcons.briefcase,
        label: l10n.businessNavMyKolabs,
        badgeCount: badgeCount > 0 ? badgeCount : null,
        iconSlug: UiIconSlug.briefcase,
      ),
      NavItem(
        // Chats promoted to the nav (NF-12); business keeps its Profile tab.
        // TODO(i18n): localize when chat strings are localized.
        icon: LucideIcons.messageCircle,
        activeIcon: LucideIcons.messageCircle,
        label: 'Chats',
        badgeCount: chatUnread > 0 ? chatUnread : null,
      ),
      NavItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: l10n.businessNavProfile,
        iconSlug: UiIconSlug.user,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.surface
          : context.colors.background,
      appBar: const KolabingAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _BusinessHomeTab(onSwitchTab: _onTabChanged),
          const _BusinessExploreTab(),
          _BusinessKollabsTab(initialSubTab: widget.initialKolabsSubTab),
          const ChatsScreen(embedded: true),
          const _BusinessProfileTab(),
        ],
      ),
      floatingActionButton:
          // Show only on Home (0) / Explore (1). Hidden on My Kolabs (2, has its
          // own create FAB), Chats (3), and Profile (4).
          _currentIndex < 2
          ? KolabingFAB(
              onPressed: _onFabPressed,
              tooltip: l10n.businessMainCreateKolabTooltip,
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
  Widget build(BuildContext context) =>
      BusinessDashboardScreen(onSwitchTab: onSwitchTab);
}

class _BusinessExploreTab extends StatelessWidget {
  const _BusinessExploreTab();

  @override
  Widget build(BuildContext context) => const ExploreScreen();
}

class _BusinessKollabsTab extends StatelessWidget {
  const _BusinessKollabsTab({this.initialSubTab = 0});

  final int initialSubTab;

  @override
  Widget build(BuildContext context) => MyKolabsHubScreen(
    offersTab: const MyKollabsScreen(embedded: true),
    initialSubTab: initialSubTab,
  );
}

class _BusinessProfileTab extends StatelessWidget {
  const _BusinessProfileTab();

  @override
  Widget build(BuildContext context) => const BusinessProfileScreen();
}
