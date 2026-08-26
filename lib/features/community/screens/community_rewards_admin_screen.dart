import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/community_rewards_providers.dart';
import '../widgets/community_rewards_admin_panel.dart';

/// The leader's reward programme, on its own screen (#174).
///
/// The merged profile page's Manage → Rewards row used to open `/rewards`,
/// which is `PersonalRewardsScreen` — the *attendee's own* points wallet. Wrong
/// audience: a leader wants to set what members can earn and redeem, not read
/// their own balance. Before that it opened the whole old Community page and
/// relied on the Rewards tab being selected, which is what made the row feel
/// like a step backwards.
///
/// The programme UI itself lives in [CommunityRewardsAdminPanel], shared with
/// the Community detail screen's Rewards tab. This screen is the frame: a title,
/// a line saying what the page is for, and pull-to-refresh.
class CommunityRewardsAdminScreen extends ConsumerWidget {
  const CommunityRewardsAdminScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          l10n.communityRewardsAdminTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => ref
            .read(communityRewardsAdminProvider(communityId).notifier)
            .reloadAll(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            KolabingSpacing.md,
            KolabingSpacing.md,
            KolabingSpacing.xxl,
          ),
          children: [
            Text(
              l10n.communityRewardsAdminBlurb,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            CommunityRewardsAdminPanel(communityId: communityId),
          ],
        ),
      ),
    );
  }
}
