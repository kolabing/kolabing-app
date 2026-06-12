// lib/features/dashboard/widgets/xp_missions_section.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import 'earn_xp_action_card.dart';

/// "Today's XP Missions" section for Variant B of the dashboard redesign.
///
/// Mission list and done/pending states are hardcoded for the preview.
/// Real completion state would be derived from WalletNotifier ledger entries.
class XpMissionsSection extends StatelessWidget {
  const XpMissionsSection({super.key});

  // Preview data — hardcoded for local comparison.
  // isDone states simulate a user who has posted a review but not yet
  // completed a kolab, shared content, or referred anyone.
  static const _missions = [
    _MissionData(
      icon: LucideIcons.star,
      iconBg: _MissionAccent.mint,
      title: 'Post a review',
      description: 'Share your last Kolab experience',
      xpReward: 20,
      isDone: true,
    ),
    _MissionData(
      icon: LucideIcons.zap,
      iconBg: _MissionAccent.amber,
      title: 'Complete a Kolab',
      description: 'Finish your active collaboration',
      xpReward: 100,
      isDone: false,
    ),
    _MissionData(
      icon: LucideIcons.camera,
      iconBg: _MissionAccent.lavender,
      title: 'Share content',
      description: 'Post UGC from your event',
      xpReward: 30,
      isDone: false,
    ),
    _MissionData(
      icon: LucideIcons.userPlus,
      iconBg: _MissionAccent.red,
      title: 'Refer a community',
      description: 'Invite someone to join Kolabing',
      xpReward: 50,
      isDone: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final doneCount = _missions.where((m) => m.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TODAY'S XP MISSIONS",
              style: KolabingTextStyles.labelLarge.copyWith(
                color: c.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$doneCount of ${_missions.length} done',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: c.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        // Mission cards
        ...List.generate(_missions.length, (i) {
          final m = _missions[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _missions.length - 1 ? KolabingSpacing.xs : 0,
            ),
            child: EarnXpActionCard(
              icon: m.icon,
              iconBgColor: m.iconBg.resolve(c),
              title: m.title,
              description: m.description,
              xpReward: m.xpReward,
              isDone: m.isDone,
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data class — preview only
// ---------------------------------------------------------------------------

enum _MissionAccent {
  mint,
  amber,
  lavender,
  red;

  Color resolve(KolabingColorTokens c) => switch (this) {
        _MissionAccent.mint => c.categoryMintBg,
        _MissionAccent.amber => c.amberChipContainer,
        _MissionAccent.lavender => c.categoryLavenderBg,
        _MissionAccent.red => c.categoryRedBg,
      };
}

class _MissionData {
  const _MissionData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.isDone,
  });

  final IconData icon;
  final _MissionAccent iconBg;
  final String title;
  final String description;
  final int xpReward;
  final bool isDone;
}
