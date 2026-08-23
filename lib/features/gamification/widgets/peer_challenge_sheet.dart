import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../event/models/event.dart';
import '../models/active_event_session.dart';
import '../models/challenge.dart';
import '../providers/active_event_session_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/peer_profile_provider.dart';
import '../providers/todays_events_provider.dart';
import '../services/challenge_service.dart';
import '../services/checkin_service.dart';
import 'challenge_card.dart';

/// What the pairing sheet wants the caller to do after it closes.
enum PeerSheetOutcome {
  /// Nothing to do — dismissed, or the challenge screen was already pushed.
  dismissed,

  /// The member has no active check-in: reopen the scanner for an event code.
  scanEventCode,

  /// A challenge was started; [PeerChallengeSheet.show] returns the completion
  /// id so the caller can show the verification QR.
  challengeStarted,
}

/// The result of showing the pairing sheet.
@immutable
class PeerSheetResult {
  const PeerSheetResult(
    this.outcome, {
    this.completionId,
    this.verifierName,
    this.challengeName,
    this.challengeDescription,
    this.points,
  });

  final PeerSheetOutcome outcome;
  final String? completionId;
  final String? verifierName;

  /// What the pair agreed to do, and what each of them earns for it — carried
  /// through so the shared screen can render immediately.
  final String? challengeName;

  /// What the pair actually has to DO. Carried through because the shared
  /// screen is where the challenge is played, and a title alone ("Take a selfie
  /// together") is a label, not an instruction.
  final String? challengeDescription;

  final int? points;
}

/// Step 2 of the loop: paired with another member, pick one of **this event's**
/// challenges to play.
///
/// The event comes from the local [ActiveEventSession] that the check-in scan
/// opened — the backend exposes no "which events am I checked into", so without
/// a check-in there is nothing to scope the challenge list to and the sheet
/// says so instead of guessing.
class PeerChallengeSheet extends ConsumerStatefulWidget {
  const PeerChallengeSheet({super.key, required this.peerProfileRef});

  /// The profile reference decoded from the scanned QR.
  final String peerProfileRef;

  static Future<PeerSheetResult> show(
    BuildContext context, {
    required String peerProfileRef,
  }) async {
    final result = await showModalBottomSheet<PeerSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PeerChallengeSheet(peerProfileRef: peerProfileRef),
    );
    return result ?? const PeerSheetResult(PeerSheetOutcome.dismissed);
  }

  @override
  ConsumerState<PeerChallengeSheet> createState() => _PeerChallengeSheetState();
}

class _PeerChallengeSheetState extends ConsumerState<PeerChallengeSheet> {
  /// Id of the challenge currently being started, so only that row spins.
  String? _startingChallengeId;

  /// Why the last attempt failed, shown INSIDE the sheet.
  ///
  /// It used to be a `SnackBar`, which a full-height modal sheet covers — so a
  /// refused challenge looked like the tap doing nothing at all, which is
  /// exactly how it was reported. The most common refusal is the honest one
  /// ("you both have to be checked in"), and it has to be readable without
  /// closing the sheet you are being refused in.
  String? _error;

  Future<void> _start(Challenge challenge, ScannedPeer peer) async {
    final session = ref.read(activeEventSessionProvider);
    if (session == null || session.isExpired || _startingChallengeId != null) {
      return;
    }

    setState(() {
      _startingChallengeId = challenge.id;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);

    final completion = await ref
        .read(initiateChallengeProvider.notifier)
        .initiate(
          challengeId: challenge.id,
          eventId: session.eventId,
          verifierProfileId: peer.profileId,
        );

    if (!mounted) return;

    if (completion == null) {
      // The notifier turns exceptions into state rather than rethrowing, so
      // read the classified reason back out — never the raw backend message.
      final kind = ref.read(initiateChallengeProvider).failure;
      setState(() {
        _startingChallengeId = null;
        _error = _messageFor(kind, l10n);
      });
      return;
    }

    Navigator.of(context).pop(
      PeerSheetResult(
        PeerSheetOutcome.challengeStarted,
        completionId: completion.id,
        verifierName: peer.displayName,
        challengeName: challenge.name,
        challengeDescription: challenge.description,
        points: challenge.points,
      ),
    );
  }

  String _messageFor(ChallengeFailure? kind, AppLocalizations l10n) =>
      switch (kind) {
        ChallengeFailure.bothMustCheckIn => l10n.peerInitiateBothCheckedIn,
        // Three different refusals that used to share one generic message
        // (#150). "You already asked them" and "you two have done this one" are
        // not the same sentence, and neither tells you to go find someone new.
        ChallengeFailure.alreadyPending => l10n.peerInitiateAlreadyPending,
        ChallengeFailure.alreadyCompleted => l10n.peerInitiateAlreadyCompleted,
        ChallengeFailure.needsNewPerson => l10n.peerInitiateNeedsNewPerson,
        ChallengeFailure.eventLimitReached => l10n.peerInitiateEventLimit,
        _ => l10n.peerInitiateFailed,
      };

  @override
  Widget build(BuildContext context) {
    // A session that expired while the app sat open is no session: pairing must
    // not scope challenges to yesterday's event.
    final stored = ref.watch(activeEventSessionProvider);
    final session = stored == null || stored.isExpired ? null : stored;
    final peerAsync = ref.watch(scannedPeerProvider(widget.peerProfileRef));
    final peer =
        peerAsync.asData?.value ??
        ScannedPeer(profileId: widget.peerProfileRef);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Grabber(),
          _Header(peer: peer, session: session),
          const SizedBox(height: KolabingSpacing.md),
          if (_error != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.lg,
              ),
              child: _SheetError(message: _error!),
            ),
            const SizedBox(height: KolabingSpacing.md),
          ],
          Flexible(
            child: session == null
                ? const _NoCheckinState()
                : _ChallengeList(
                    eventId: session.eventId,
                    startingChallengeId: _startingChallengeId,
                    onPick: (challenge) => _start(challenge, peer),
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: context.colors.outlineVariant,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.peer, required this.session});

  final ScannedPeer peer;
  final ActiveEventSession? session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = peer.displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.users,
              color: context.colors.charcoal,
              size: 28,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            name == null
                ? l10n.peerPairedTitleFallback
                : l10n.peerPairedTitle(name),
            textAlign: TextAlign.center,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            session == null ? '' : l10n.peerPairedSubtitle,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (session?.eventName != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _EventChip(eventName: session!.eventName!),
          ],
        ],
      ),
    );
  }
}

/// Shows which event's challenges are on screen — the one thing a member can't
/// otherwise tell when two events run back to back.
class _EventChip extends StatelessWidget {
  const _EventChip({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.mapPin,
            size: 14,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.peerPairedAtEvent(eventName),
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.labelSmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the member scanned a peer without checking in first. Rather than
/// guessing an event, it sends them back to the event's QR code.
/// What the sheet shows when there is no active event session.
///
/// This used to be a dead end: "check in first", one button, and the only way in
/// was a QR the organizer had to be displaying at that moment. Most small
/// community events do not have anyone holding a phone at the entrance, so the
/// challenge loop was unreachable for them (#144).
///
/// Now the events you already said you were going to **today** are right here.
/// Picking one checks you in and opens the session; because the sheet watches
/// [activeEventSessionProvider], it swaps itself for the challenge list without
/// the attendee going anywhere. The organizer's QR stays as the option that
/// works when you never RSVPed — and as the stronger proof of presence.
class _NoCheckinState extends ConsumerStatefulWidget {
  const _NoCheckinState();

  @override
  ConsumerState<_NoCheckinState> createState() => _NoCheckinStateState();
}

class _NoCheckinStateState extends ConsumerState<_NoCheckinState> {
  String? _busyEventId;

  Future<void> _pick(Event event) async {
    if (_busyEventId != null) return;
    setState(() => _busyEventId = event.id);

    try {
      final checkin = await ref
          .read(checkinServiceProvider)
          .selfCheckIn(event.id);

      final sessions = ref.read(activeEventSessionProvider.notifier);
      if (checkin != null) {
        await sessions.start(checkin);
      } else {
        // A 409 body is not guaranteed to carry the check-in, and the event id
        // is the only thing the session needs.
        await sessions.startForEvent(eventId: event.id, eventName: event.name);
      }
      // No navigation: the sheet is watching the session and will rebuild into
      // the challenge list on its own.
      if (mounted) setState(() => _busyEventId = null);
    } on CheckinException catch (e) {
      if (!mounted) return;
      setState(() => _busyEventId = null);
      // Not deployed yet → the QR door is the honest answer, not an error.
      if (e.kind == CheckinFailure.unavailable) {
        Navigator.of(
          context,
        ).pop(const PeerSheetResult(PeerSheetOutcome.scanEventCode));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busyEventId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(todaysGoingEventsProvider);
    final events = async.asData?.value ?? const <Event>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.peerNoSessionTitle,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.titleSmall.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            events.isEmpty
                ? l10n.peerNoSessionBody
                : l10n.eventCheckinPickEvent,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          if (async.isLoading && events.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (events.isEmpty)
            Text(
              l10n.eventCheckinPickEventEmpty,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else
            for (final event in events) ...[
              _TodaysEventTile(
                event: event,
                busy: _busyEventId == event.id,
                onTap: () => _pick(event),
              ),
              const SizedBox(height: KolabingSpacing.xs),
            ],
          const SizedBox(height: KolabingSpacing.md),
          TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pop(const PeerSheetResult(PeerSheetOutcome.scanEventCode)),
            icon: const Icon(LucideIcons.qrCode, size: 14),
            label: Text(l10n.eventCheckinScanOrganizerQr),
          ),
        ],
      ),
    );
  }
}

/// A refusal, rendered where the person can actually see it.
class _SheetError extends StatelessWidget {
  const _SheetError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 18,
            color: context.colors.errorText,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.errorText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysEventTile extends StatelessWidget {
  const _TodaysEventTile({
    required this.event,
    required this.busy,
    required this.onTap,
  });

  final Event event;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Row(
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  event.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeList extends ConsumerWidget {
  const _ChallengeList({
    required this.eventId,
    required this.startingChallengeId,
    required this.onPick,
  });

  final String eventId;
  final String? startingChallengeId;
  final ValueChanged<Challenge> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(eventChallengesProvider(eventId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(KolabingSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.peerChallengesLoadFailed,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextButton(
              onPressed: () => ref.invalidate(eventChallengesProvider(eventId)),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
      data: (response) {
        if (response.challenges.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Text(
              l10n.peerChallengesEmpty,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.lg,
            vertical: KolabingSpacing.xs,
          ),
          itemCount: response.challenges.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: KolabingSpacing.sm),
          itemBuilder: (context, index) {
            final challenge = response.challenges[index];
            final isStarting = startingChallengeId == challenge.id;
            final anyStarting = startingChallengeId != null;

            return Opacity(
              opacity: anyStarting && !isStarting ? 0.45 : 1,
              child: Stack(
                children: [
                  ChallengeCard(
                    challenge: challenge,
                    onTap: anyStarting ? null : () => onPick(challenge),
                  ),
                  if (isStarting)
                    const Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
