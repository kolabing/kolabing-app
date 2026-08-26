import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/multi_kolab_creator_summary.dart';

/// "2 open · 1 filled" — icon + text, per the plan's "never color alone"
/// accessibility rule. Used on both the Explore card and the event detail
/// screen.
class MultiKolabRoleProgress extends StatelessWidget {
  const MultiKolabRoleProgress({required this.counts, super.key});

  final MultiKolabRoleCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Semantics(
      label: l10n.multiKolabRoleProgressSemanticLabel(
        counts.open,
        counts.filled,
        counts.total,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.users, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: KolabingSpacing.xxxs),
          Text(
            l10n.multiKolabRoleProgressLabel(counts.open, counts.filled),
            style: KolabingTextStyles.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
