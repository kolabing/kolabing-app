import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/challenge.dart';
import '../models/encounter.dart';
import '../providers/encounter_provider.dart';
import '../services/encounter_service.dart';

/// Doing a challenge with someone who is not on Kolabing (#183, kolabing-v2#246).
///
/// The person standing next to you at an event without the app is the best
/// prospect this product has, and until now they could not take part at all.
/// This is the whole path: a name, an optional way to reach them, and a link.
///
/// Two things about the copy are load-bearing:
///
/// - **The reward is named and not paid.** "Ana gets 15 XP for both of you when
///   she joins" is the pull. Paying up front would invite imaginary friends.
/// - **A name is all that is required.** Asking a stranger for their number at
///   the moment you meet them is bad manners, and the server never needs it.
class GhostInviteSheet extends ConsumerStatefulWidget {
  const GhostInviteSheet({
    super.key,
    required this.eventId,
    required this.challenge,
  });

  final String eventId;
  final Challenge challenge;

  static Future<void> open(
    BuildContext context, {
    required String eventId,
    required Challenge challenge,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GhostInviteSheet(eventId: eventId, challenge: challenge),
    );
  }

  @override
  ConsumerState<GhostInviteSheet> createState() => _GhostInviteSheetState();
}

class _GhostInviteSheetState extends ConsumerState<GhostInviteSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _contact = TextEditingController();

  bool _sending = false;
  String? _error;

  /// Set once the server has written the invite. From here the sheet stops
  /// being a form and becomes a code plus a share button.
  GhostInvite? _invite;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context);
    try {
      final invite = await ref
          .read(encounterServiceProvider)
          .createGhostInvite(
            eventId: widget.eventId,
            challengeId: widget.challenge.id,
            ghostName: name,
            ghostContact: _contact.text,
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _invite = invite;
      });
    } on EncounterException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = _messageFor(e, l10n);
      });
    }
  }

  /// Localized off the classified reason, never off the backend's English.
  String _messageFor(EncounterException e, AppLocalizations l10n) {
    if (e.isFeatureOff) return l10n.ghostInviteUnavailable;
    if (e.notCheckedIn) return l10n.ghostInviteNotCheckedIn;
    if (e.ghostLimitReached) return l10n.ghostInviteLimitReached;
    return l10n.ghostInviteFailed;
  }

  Future<void> _share() async {
    final invite = _invite;
    if (invite == null) return;
    final l10n = AppLocalizations.of(context);

    // Same call the referral and wallet screens already make, so sharing
    // behaves identically wherever it happens in the app.
    await Share.share(
      l10n.ghostInviteShareMessage(
        invite.encounter.displayName,
        invite.claimCode,
        invite.inviteUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invite = _invite;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: invite == null
                ? _form(context, l10n)
                : _created(context, l10n, invite),
          ),
        ),
      ),
    );
  }

  List<Widget> _form(BuildContext context, AppLocalizations l10n) => [
    Text(
      l10n.ghostInviteTitle,
      style: KolabingTextStyles.titleLarge.copyWith(
        color: context.colors.onSurface,
      ),
    ),
    const SizedBox(height: KolabingSpacing.xs),
    Text(
      l10n.ghostInviteBody(widget.challenge.points),
      style: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: KolabingSpacing.lg),
    TextField(
      controller: _name,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: l10n.ghostInviteNameLabel),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: KolabingSpacing.sm),
    TextField(
      controller: _contact,
      decoration: InputDecoration(
        labelText: l10n.ghostInviteContactLabel,
        // Said out loud, because a form that does not say a field is optional
        // reads as one that requires it — and this one must never feel like
        // it is asking a stranger for their number.
        helperText: l10n.ghostInviteContactHint,
      ),
    ),
    if (_error != null) ...[
      const SizedBox(height: KolabingSpacing.sm),
      Text(
        _error!,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.error,
        ),
      ),
    ],
    const SizedBox(height: KolabingSpacing.lg),
    KolabingButton(
      label: l10n.ghostInviteCreate,
      onPressed: _name.text.trim().isEmpty || _sending ? null : _create,
      isLoading: _sending,
      variant: KolabingButtonVariant.primary,
    ),
  ];

  List<Widget> _created(
    BuildContext context,
    AppLocalizations l10n,
    GhostInvite invite,
  ) => [
    Row(
      children: [
        Icon(LucideIcons.check, color: context.colors.xpGreen),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            l10n.ghostInviteReadyTitle(invite.encounter.displayName),
            style: KolabingTextStyles.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: KolabingSpacing.xs),
    Text(
      l10n.ghostInvitePending(
        invite.encounter.displayName,
        invite.encounter.pendingPoints,
      ),
      style: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: KolabingSpacing.lg),
    // The code is shown as well as shared: a Universal Link does not survive
    // an install, so this is the half that reaches someone on the other side
    // of the App Store.
    Container(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            l10n.ghostInviteCodeLabel,
            style: KolabingTextStyles.eyebrow.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          SelectableText(
            invite.claimCode,
            style: KolabingTextStyles.statNumber.copyWith(
              color: context.colors.onSurface,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: KolabingSpacing.lg),
    KolabingButton(
      label: l10n.ghostInviteShare,
      onPressed: _share,
      variant: KolabingButtonVariant.primary,
    ),
    const SizedBox(height: KolabingSpacing.sm),
    TextButton(
      onPressed: () => Navigator.of(context).maybePop(),
      child: Text(l10n.commonDone),
    ),
  ];
}
