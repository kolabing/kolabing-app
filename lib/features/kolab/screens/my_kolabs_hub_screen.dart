import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_segmented_control.dart';
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
class MyKolabsHubScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MyKolabsHubScreen> createState() => _MyKolabsHubScreenState();
}

class _MyKolabsHubScreenState extends ConsumerState<MyKolabsHubScreen>
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
    // Refresh collaborations each time the hub opens so Active/Finished never
    // show a stale session-cached snapshot (e.g. after a new kolab is formed).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(collaborationsListProvider);
    });
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.surface
          : context.colors.background,
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
                l10n.myKolabsHubTitle.toUpperCase(),
                style: KolabingTextStyles.displayTitle.copyWith(
                  color: context.colors.titleInk,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
              ),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) => KolabingSegmentedControl<int>(
                  segments: [
                    (0, l10n.myKolabsHubTabOffers.toUpperCase()),
                    (1, l10n.myKolabsHubTabRequests.toUpperCase()),
                    (2, l10n.myKolabsHubTabActive.toUpperCase()),
                    (3, l10n.myKolabsHubTabFinished.toUpperCase()),
                  ],
                  selectedValue: _tabController.index,
                  onChanged: (i) => _tabController.animateTo(i),
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  widget.offersTab,
                  const ApplicationsScreen(embedded: true),
                  CollaborationsListTab(
                    bucket: CollaborationBucket.active,
                    emptyTitle: l10n.myKolabsHubActiveEmptyTitle,
                    emptyMessage: l10n.myKolabsHubActiveEmptyMessage,
                  ),
                  CollaborationsListTab(
                    bucket: CollaborationBucket.finished,
                    emptyTitle: l10n.myKolabsHubFinishedEmptyTitle,
                    emptyMessage: l10n.myKolabsHubFinishedEmptyMessage,
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
              tooltip: l10n.myKolabsHubCreateTooltip,
              heroTag: 'my_kolabs_hub_fab',
            )
          : null,
    );
  }
}
