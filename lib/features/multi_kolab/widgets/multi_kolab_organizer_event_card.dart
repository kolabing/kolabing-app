import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event_summary.dart';
import 'multi_kolab_labels.dart';

/// One organizer-owned Multi-Kolab event on the organizer dashboard.
///
/// Everything rendered here comes from the `GET /multi-kolab-events/me`
/// summary payload alone — no per-event fan-out. In particular the
/// per-status application counts are NOT available on this endpoint and are
/// deliberately shown one level deeper, on the event-management screen,
/// rather than costing one dashboard request per row.
class MultiKolabOrganizerEventCard extends StatelessWidget {
  const MultiKolabOrganizerEventCard({
    required this.event,
    required this.onManage,
    super.key,
  });

  final MultiKolabEventSummary event;
  final VoidCallback onManage;

  /// A draft has never been published, and a recruiting event with unfilled
  /// roles is still waiting on partners — both are things the organizer can
  /// act on right now. Derived purely from the summary payload.
  bool get needsAttention =>
      event.status == MultiKolabEventStatus.draft ||
      (event.status == MultiKolabEventStatus.recruiting &&
          event.roleCounts.open > 0);

  String _monogram() {
    final trimmed = event.title.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  String? _dateLabel(AppLocalizations l10n) {
    if (event.eventDate != null) {
      return DateFormat.yMMMd().format(event.eventDate!);
    }
    // The summary resource carries no range endpoints, so a range event can
    // only be labelled by its mode until it is opened.
    if (event.dateMode == MultiKolabDateMode.range) {
      return l10n.multiKolabEventFormDateModeRange;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final date = _dateLabel(l10n);

    return Semantics(
      container: true,
      button: true,
      label: event.title,
      child: InkWell(
        key: Key('multiKolabOrganizerEventCard_${event.id}'),
        onTap: onManage,
        borderRadius: KolabingRadius.borderRadiusCard,
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: KolabingRadius.borderRadiusCard,
            border: Border.all(color: colors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MultiKolabEvent has no media column at all (API contract
                  // §13), so a monogram is the only deterministic visual.
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    child: Text(
                      _monogram(),
                      style: KolabingTextStyles.titleMedium.copyWith(
                        color: colors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: KolabingTextStyles.titleMedium.copyWith(
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: KolabingSpacing.xxs),
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            MultiKolabStatusChip.event(event.status, l10n),
                            if (event.city != null && event.city!.isNotEmpty)
                              _MetaText(
                                icon: LucideIcons.mapPin,
                                text: event.city!,
                              ),
                            if (date != null)
                              _MetaText(
                                icon: LucideIcons.calendar,
                                text: date,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.sm),
              Semantics(
                label: l10n.multiKolabRoleProgressSemanticLabel(
                  event.roleCounts.open,
                  event.roleCounts.total,
                  event.roleCounts.filled,
                ),
                excludeSemantics: true,
                child: Text(
                  l10n.multiKolabManageRolesProgress(
                    event.roleCounts.filled,
                    event.roleCounts.total,
                  ),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: colors.inkBody,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              Row(
                children: [
                  if (needsAttention)
                    Container(
                      key: Key('multiKolabNeedsAttention_${event.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: KolabingSpacing.sm,
                        vertical: KolabingSpacing.xxxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.pendingBg,
                        borderRadius: KolabingRadius.borderRadiusRound,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 12,
                            color: colors.pendingText,
                          ),
                          const SizedBox(width: KolabingSpacing.xxs),
                          Text(
                            l10n.multiKolabOrganizerNeedsAttention,
                            style: KolabingTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.pendingText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    key: Key('multiKolabManageCta_${event.id}'),
                    onPressed: onManage,
                    child: Text(l10n.multiKolabOrganizerManageCta),
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

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.muted),
        const SizedBox(width: KolabingSpacing.xxs),
        Text(
          text,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: colors.inkBody,
          ),
        ),
      ],
    );
  }
}
