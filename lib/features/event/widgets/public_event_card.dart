import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/public_event.dart';

/// Card for one item in the attendee public-events (Explore) feed.
///
/// Shows the PUBLIC badge, community, date and going-count, plus an RSVP
/// button. RSVP is delegated to [onRsvp] (the screen owns the network call and
/// the members-only gate). [isRsvping] disables the button mid-request and
/// [isGoing] flips it to the confirmed state.
class PublicEventCard extends StatelessWidget {
  const PublicEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onRsvp,
    this.isRsvping = false,
    this.isGoing = false,
  });

  final PublicEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onRsvp;
  final bool isRsvping;
  final bool isGoing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cover(),
                const SizedBox(width: KolabingSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _publicBadge(l10n),
                      const SizedBox(height: 4),
                      Text(
                        event.name,
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.community != null ||
                          event.partnerName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          event.community?.name ?? event.partnerName ?? '',
                          style: KolabingTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: KolabingColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      _metaRow(l10n),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.md),
            _rsvpButton(l10n),
          ],
        ),
      ),
    );
  }

  Widget _cover() {
    final url = event.coverPhotoUrl;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: KolabingColors.primary.withValues(alpha: 0.1),
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? const Icon(
              LucideIcons.calendar,
              size: 30,
              color: KolabingColors.primary,
            )
          : null,
    );
  }

  Widget _publicBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: KolabingColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.explorePublicBadge,
        style: KolabingTextStyles.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: KolabingColors.success,
        ),
      ),
    );
  }

  Widget _metaRow(AppLocalizations l10n) {
    return Wrap(
      spacing: KolabingSpacing.sm,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _iconText(LucideIcons.calendar, event.formattedDate),
        _iconText(LucideIcons.users, l10n.exploreGoingCount(event.goingCount)),
      ],
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: KolabingColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: KolabingTextStyles.labelSmall.copyWith(
            color: KolabingColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _rsvpButton(AppLocalizations l10n) {
    if (isGoing) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.check, size: 16),
          label: Text(l10n.exploreGoing),
        ),
      );
    }
    if (event.isFull) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: null, child: Text(l10n.exploreFull)),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isRsvping ? null : onRsvp,
        style: FilledButton.styleFrom(
          backgroundColor: KolabingColors.primary,
          foregroundColor: KolabingColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isRsvping
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.calendarCheck, size: 16),
        label: Text(l10n.exploreRsvp),
      ),
    );
  }
}
