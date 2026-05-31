import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/navigation/navigation.dart';
import '../../application/screens/applications_screen.dart';
import '../../collaboration/providers/collaborations_list_provider.dart';
import '../../collaboration/widgets/collaborations_list_tab.dart';

/// Hub for the merged "My Kolabs" bottom-nav destination.
///
/// Hosts four internal tabs — Offers, Requests, Active, Finished — under a
/// single destination. The former standalone Applications screen is absorbed
/// here as the "Requests" tab. Active/Finished are placeholders until the
/// kolab completion flow lands (Phase 3).
///
/// The role-specific "Offers" content is injected via [offersTab] so the same
/// hub serves both business (kolabs) and community (opportunities) users.
class MyKolabsHubScreen extends StatefulWidget {
  const MyKolabsHubScreen({
    required this.offersTab,
    this.initialSubTab = 0,
    super.key,
  });

  /// Role-specific "Offers" tab content.
  final Widget offersTab;

  /// Initial sub-tab: 0 Offers, 1 Requests, 2 Active, 3 Finished.
  final int initialSubTab;

  @override
  State<MyKolabsHubScreen> createState() => _MyKolabsHubScreenState();
}

class _MyKolabsHubScreenState extends State<MyKolabsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialSubTab.clamp(0, 3),
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // Rebuild so the create FAB only shows on the Offers tab.
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.surface
          : KolabingColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KolabingSpacing.md,
                KolabingSpacing.md,
                KolabingSpacing.md,
                KolabingSpacing.xs,
              ),
              child: Text(
                'MY KOLABS',
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.onSurface,
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelStyle: KolabingTextStyles.labelLarge,
              labelColor: KolabingColors.charcoal,
              unselectedLabelColor: KolabingColors.navInactive,
              indicatorColor: KolabingColors.navBarBackground,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'OFFERS'),
                Tab(text: 'REQUESTS'),
                Tab(text: 'ACTIVE'),
                Tab(text: 'FINISHED'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  widget.offersTab,
                  const ApplicationsScreen(embedded: true),
                  const CollaborationsListTab(
                    bucket: CollaborationBucket.active,
                    emptyTitle: 'No active kolabs',
                    emptyMessage:
                        'Once an application is accepted by both sides, the '
                        'kolab shows up here while it’s underway.',
                  ),
                  const CollaborationsListTab(
                    bucket: CollaborationBucket.finished,
                    emptyTitle: 'Nothing finished yet',
                    emptyMessage:
                        'Completed and cancelled kolabs will be collected here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? KolabingFAB(
              onPressed: () => context.push(KolabingRoutes.kolabNew),
              tooltip: 'Create Kolab',
              heroTag: 'my_kolabs_hub_fab',
            )
          : null,
    );
  }
}
