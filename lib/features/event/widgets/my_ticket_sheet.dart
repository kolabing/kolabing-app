import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event_ticket.dart';

/// The holder's ticket, at the size a door needs.
///
/// The QR is the server's own SVG, never one drawn here from [EventTicket.code]
/// — a locally generated code could disagree with the link the door expects,
/// and being wrong at a door is worse than being absent.
class MyTicketSheet extends StatelessWidget {
  const MyTicketSheet({super.key, required this.ticket});

  final EventTicket ticket;

  static Future<void> show(BuildContext context, EventTicket ticket) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MyTicketSheet(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // The QR should be as large as the sheet allows: at a door, in bad light,
    // through a scratched camera lens, size is the whole feature.
    final side = MediaQuery.sizeOf(context).width - KolabingSpacing.xxl * 2;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(KolabingSpacing.sm),
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(KolabingRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.eventTicketSheetTitle,
                    style: KolabingTextStyles.titleMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            if (ticket.event != null)
              Text(
                ticket.event!.name,
                textAlign: TextAlign.center,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: KolabingSpacing.md),

            // The QR, or the code alone when the payload predates qr_svg.
            if (ticket.isScannable)
              Container(
                width: side,
                height: side,
                padding: const EdgeInsets.all(KolabingSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(KolabingRadius.lg),
                  border: Border.all(color: context.colors.hairline),
                ),
                child: SvgPicture.string(ticket.qrSvg!, fit: BoxFit.contain),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.lg,
                ),
                child: Text(
                  l10n.eventTicketNoQr,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),

            const SizedBox(height: KolabingSpacing.md),

            // The code, tappable to copy: a scanner that will not focus is the
            // reason a human reads it out instead.
            Text(
              l10n.eventTicketCodeLabel.toUpperCase(),
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: ticket.code));
              },
              borderRadius: BorderRadius.circular(KolabingRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                  vertical: KolabingSpacing.xxs,
                ),
                child: Text(
                  ticket.code,
                  style: KolabingTextStyles.titleMedium.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ),
            if (ticket.holderName != null) ...[
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                ticket.holderName!,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: KolabingSpacing.md),
            _StatusLine(ticket: ticket, locale: locale),
          ],
        ),
      ),
    );
  }
}

/// What the ticket is worth right now: already used, not yet valid, or good.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.ticket, required this.locale});

  final EventTicket ticket;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (ticket.isAdmitted) {
      return _Banner(
        icon: LucideIcons.checkCircle,
        text: l10n.eventTicketAdmitted(
          DateFormat.Hm(locale).format(ticket.usedAt!.toLocal()),
        ),
        fill: context.colors.activeBg,
        ink: context.colors.activeText,
      );
    }
    if (ticket.isWaitlisted) {
      return _Banner(
        icon: LucideIcons.clock,
        text: l10n.eventTicketWaitlistedBody,
        fill: context.colors.pendingBg,
        ink: context.colors.pendingText,
      );
    }
    return _Banner(
      icon: LucideIcons.scanLine,
      text: l10n.eventTicketShowAtDoor,
      fill: context.colors.surfaceContainerHigh,
      ink: context.colors.onSurfaceVariant,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.fill,
    required this.ink,
  });

  final IconData icon;
  final String text;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: ink),
        const SizedBox(width: KolabingSpacing.xs),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );
}
