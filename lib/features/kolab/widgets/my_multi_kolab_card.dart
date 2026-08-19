// lib/features/kolab/widgets/my_multi_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../multi_kolab/models/multi_kolab_enums.dart';
import '../../multi_kolab/models/multi_kolab_event_summary.dart';

/// One organizer-owned Multi-Kolab event rendered as an ORDINARY My Kolabs
/// card.
///
/// A Multi-Kolab Event is still a Kolab, so this deliberately uses the same
/// [KolabCardShell] as [MyKolabCard] and [CollaborationsListTab]'s cards —
/// same surface, border, radius, padding, thumbnail slot, status badge and
/// chip family. The only thing that marks it out is a small "Multi-Kolab"
/// chip; there is no promo treatment and no separate section.
class MyMultiKolabCard extends StatelessWidget {
  const MyMultiKolabCard({required this.event, this.onTap, super.key});

  final MultiKolabEventSummary event;

  /// Defaults to the Multi-Kolab Manage event screen for this event.
  final VoidCallback? onTap;

  /// Maps the Multi-Kolab lifecycle onto the status vocabulary
  /// [KolabStatusBadge] already renders for ordinary kolabs, so the badge
  /// treatment is identical rather than merely similar.
  static String badgeStatusFor(MultiKolabEventStatus status) =>
      switch (status) {
        MultiKolabEventStatus.draft => 'draft',
        MultiKolabEventStatus.recruiting => 'published',
        MultiKolabEventStatus.confirmed => 'active',
        MultiKolabEventStatus.completed => 'completed',
        MultiKolabEventStatus.cancelled => 'cancelled',
        MultiKolabEventStatus.expired => 'closed',
      };

  String get _initials {
    final cleaned = event.title
        .replaceAll(RegExp('^[^A-Za-z0-9]+'), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned[0].toUpperCase() : 'K';
  }

  String? _dateLabel(AppLocalizations l10n) {
    final date = event.eventDate;
    if (date != null) {
      return DateFormat('MMM d').format(date);
    }
    // The summary payload carries no range endpoints, so a range event can
    // only be labelled by its mode until it is opened.
    if (event.dateMode == MultiKolabDateMode.range) {
      return l10n.multiKolabEventFormDateModeRange;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = _dateLabel(l10n);
    final city = event.city;

    return KolabCardShell(
      key: Key('myKolabsMultiKolabCard_${event.id}'),
      initials: _initials,
      onTap:
          onTap ??
          () => context.push(multiKolabOrganizerEventLocation(event.id)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              KolabStatusBadge(status: badgeStatusFor(event.status)),
              KolabChip(
                key: Key('myKolabsMultiKolabBadge_${event.id}'),
                label: l10n.multiKolabCardBadge,
                icon: LucideIcons.users,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            event.title.isNotEmpty ? event.title : l10n.myKolabCardUntitled,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (date != null)
                KolabChip(
                  label: date,
                  variant: KolabChipVariant.sage,
                  icon: LucideIcons.calendar,
                ),
              if (city != null && city.isNotEmpty)
                KolabChip(
                  label: city,
                  variant: KolabChipVariant.amber,
                  icon: LucideIcons.mapPin,
                ),
            ],
          ),
          const SizedBox(height: 7),
          // Open ROLE count only — `GET /multi-kolab-events/me` returns
          // `role_counts` ({total, open, filled}) computed with `withCount`
          // over the roles table and carries no partner-spot aggregate, so a
          // "N partners confirmed" line here would be invented data (one role
          // can recruit several partners). The partner-spot breakdown lives
          // one level deeper, on Manage event, which loads the roles.
          Text(
            key: Key('myKolabsMultiKolabRoles_${event.id}'),
            l10n.multiKolabOpenRolesCount(event.roleCounts.open),
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
