import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/active_event_session.dart';
import '../models/challenge.dart';
import '../providers/active_event_session_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/peer_profile_provider.dart';
import '../services/challenge_service.dart';
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
  const PeerSheetResult(this.outcome, {this.completionId, this.verifierName});

  final PeerSheetOutcome outcome;
  final String? completionId;
  final String? verifierName;
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

  Future<void> _start(Challenge challenge, ScannedPeer peer) async {
    final session = ref.read(activeEventSessionProvider);
    if (session == null || _startingChallengeId != null) return;

    setState(() => _startingChallengeId = challenge.id);
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
      setState(() => _startingChallengeId = null);
      _snack(_messageFor(kind, l10n));
      return;
    }

    Navigator.of(context).pop(
      PeerSheetResult(
        PeerSheetOutcome.challengeStarted,
        completionId: completion.id,
        verifierName: peer.displayName,
      ),
    );
  }

  String _messageFor(ChallengeFailure? kind, AppLocalizations l10n) =>
      switch (kind) {
        ChallengeFailure.bothMustCheckIn => l10n.peerInitiateBothCheckedIn,
        _ => l10n.peerInitiateFailed,
      };

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeEventSessionProvider);
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
class _NoCheckinState extends StatelessWidget {
  const _NoCheckinState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.peerNoSessionTitle,
            style: KolabingTextStyles.titleSmall.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.peerNoSessionBody,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: KolabingButton(
              label: l10n.peerNoSessionAction,
              onPressed: () => Navigator.of(
                context,
              ).pop(const PeerSheetResult(PeerSheetOutcome.scanEventCode)),
              variant: KolabingButtonVariant.primary,
            ),
          ),
        ],
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
