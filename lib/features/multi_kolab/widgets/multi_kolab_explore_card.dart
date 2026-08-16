import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/remote_media_url.dart';
import '../models/multi_kolab_event_summary.dart';
import 'multi_kolab_role_progress.dart';

/// The distinct Multi-Kolab Event Explore card. Deliberately a separate
/// widget from `ExploreSwipeCard`/`OpportunityCard` — never modifies either
/// — so ordinary Kolab discovery is completely unaffected by this feature.
class MultiKolabExploreCard extends StatelessWidget {
  const MultiKolabExploreCard({required this.event, super.key, this.onTap});

  final MultiKolabEventSummary event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final avatarUrl = normalizeRemoteMediaUrlOrNull(
      event.creatorProfile?.avatarUrl,
    );

    return Material(
      color: colors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(color: colors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.sm,
                      vertical: KolabingSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                    child: Text(
                      l10n.multiKolabExploreCardBadge,
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (event.eventDate != null)
                    Text(
                      DateFormat.MMMd().format(event.eventDate!),
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                event.title,
                style: KolabingTextStyles.titleSmall.copyWith(
                  color: colors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.valueSummary != null &&
                  event.valueSummary!.isNotEmpty) ...[
                const SizedBox(height: KolabingSpacing.xxxs),
                Text(
                  event.valueSummary!,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: KolabingSpacing.sm),
              Row(
                children: [
                  if (event.city != null && event.city!.isNotEmpty) ...[
                    Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: KolabingSpacing.xxxs),
                    Text(
                      event.city!,
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                  ],
                  MultiKolabRoleProgress(counts: event.roleCounts),
                ],
              ),
              const SizedBox(height: KolabingSpacing.sm),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: colors.surfaceVariant,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(
                            LucideIcons.building2,
                            size: 12,
                            color: colors.textTertiary,
                          )
                        : null,
                  ),
                  const SizedBox(width: KolabingSpacing.xxxs),
                  Expanded(
                    child: Text(
                      event.creatorProfile?.displayName ?? '',
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
