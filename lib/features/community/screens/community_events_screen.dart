import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../event/providers/event_provider.dart';
import '../models/community.dart';
import '../widgets/community_events_panel.dart';

/// A community's events on their own screen (#174).
///
/// Manage → Events used to push the whole old Community page and rely on the
/// leader scrolling past the cover, the photo strip and the rewards admin to
/// reach the events at the bottom. Same content, nothing else in front of it.
class CommunityEventsScreen extends ConsumerWidget {
  const CommunityEventsScreen({
    super.key,
    required this.community,
    required this.canManage,
  });

  final Community community;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          l10n.communityDetailTabEvents,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => Future.wait([
          ref
              .read(communityUpcomingEventsProvider(community.id).notifier)
              .reload(),
          ref.read(communityPastEventsProvider(community.id).notifier).reload(),
        ]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            KolabingSpacing.md,
            KolabingSpacing.md,
            KolabingSpacing.xxl,
          ),
          children: [
            CommunityEventsPanel(community: community, canManage: canManage),
          ],
        ),
      ),
    );
  }
}
