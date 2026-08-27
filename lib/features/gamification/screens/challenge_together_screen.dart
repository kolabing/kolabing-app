import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../friends/providers/friends_provider.dart';
import '../../friends/services/friendship_service.dart';
import '../models/challenge_completion.dart';
import '../providers/challenge_provider.dart';
import '../providers/completion_watch_provider.dart';
import '../providers/pending_challenge_provider.dart';
import '../services/challenge_service.dart';

/// Which end of the challenge this device is.
enum TogetherRole {
  /// Picked the challenge and is waiting for the other person.
  starter,

  /// Was asked, and confirms.
  partner,
}

/// The one screen both devices show once a challenge is agreed
/// (kolabing-app#140).
///
/// It replaces the verification QR. Two people completing a challenge together
/// now involves exactly **one** scan between them — one scans the other, picks
/// a challenge, and the other's phone finds out on its own
/// ([pendingChallengeProvider]) and opens this same screen.
///
/// The point is that the app holds the moment rather than the paperwork: both
/// sides see the same challenge, and the reveal lands on both devices saying
/// what **each** of them earned. The challenge pays both people who did it, so
/// there is no "verifier" doing someone else a favour any more.
class ChallengeTogetherScreen extends ConsumerStatefulWidget {
  const ChallengeTogetherScreen({
    super.key,
    required this.completionId,
    required this.role,
    this.challengeName,
    this.challengeDescription,
    this.otherName,
    this.points,
    this.photoPath,
    this.otherProfileId,
  });

  final String completionId;
  final TogetherRole role;
  final String? challengeName;

  /// What to actually do. The title names the challenge; this is the game.
  final String? challengeDescription;

  final String? otherName;

  /// What each side stands to earn. Server truth; never computed here.
  final int? points;

  /// The frame this challenge produced, if it asked for one (#183). A local
  /// path — it is drawn immediately while the upload happens in the background.
  final String? photoPath;

  /// The other person, so the reveal can offer to connect. An encounter is a
  /// fact; a friendship is a choice, and this is where the choice is offered.
  final String? otherProfileId;

  static Future<void> open(
    BuildContext context, {
    required String completionId,
    required TogetherRole role,
    String? challengeName,
    String? challengeDescription,
    String? otherName,
    int? points,
    String? photoPath,
    String? otherProfileId,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeTogetherScreen(
          completionId: completionId,
          role: role,
          challengeName: challengeName,
          challengeDescription: challengeDescription,
          otherName: otherName,
          points: points,
          photoPath: photoPath,
          otherProfileId: otherProfileId,
        ),
      ),
    );
  }

  /// Opens the screen for the person who was *asked*, from a pending
  /// completion the poller found.
  static Future<void> openForPartner(
    BuildContext context,
    ChallengeCompletion completion,
  ) {
    return open(
      context,
      completionId: completion.id,
      role: TogetherRole.partner,
      challengeName: completion.challengeName ?? completion.challenge?.name,
      challengeDescription: completion.challenge?.description,
      otherName: completion.challengerName,
      points: completion.challenge?.points,
      otherProfileId: completion.challengerProfileId,
    );
  }

  @override
  ConsumerState<ChallengeTogetherScreen> createState() =>
      _ChallengeTogetherScreenState();
}

class _ChallengeTogetherScreenState
    extends ConsumerState<ChallengeTogetherScreen> {
  bool _submitting = false;
  bool _cancelling = false;

  /// Set once this device has settled it, so the partner sees the reveal
  /// immediately rather than waiting for a poll to come back.
  ChallengeCompletion? _settled;

  Future<void> _decide({required bool confirm}) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final service = ref.read(challengeServiceProvider);
    try {
      final updated = confirm
          ? await service.verifyChallenge(widget.completionId)
          : await service.rejectChallenge(widget.completionId);

      // Stop the poller re-surfacing this one.
      ref.read(pendingChallengeProvider.notifier).resolve(widget.completionId);
      ref.read(myChallengeCompletionsProvider.notifier).refresh();

      if (!mounted) return;
      setState(() {
        _settled = updated;
        _submitting = false;
      });
    } on ChallengeException {
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).maybePop();
    }
  }

  /// Takes the request back. Only the starter can, and only while nobody has
  /// answered — the server enforces both.
  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    final l10n = AppLocalizations.of(context);

    try {
      await ref
          .read(challengeServiceProvider)
          .cancelChallenge(widget.completionId);
      ref.read(myChallengeCompletionsProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.challengeTogetherCancelled)));
      Navigator.of(context).maybePop();
    } on Object {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.challengeTogetherCancelFailed)),
      );
    }
  }

  void _dismiss() {
    ref.read(pendingChallengeProvider.notifier).resolve(widget.completionId);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // The starter learns the outcome by watching; the partner already knows it,
    // because they are the one who settled it.
    final watched = widget.role == TogetherRole.starter
        ? ref.watch(completionWatchProvider(widget.completionId))
        : null;

    final completion = _settled ?? watched?.completion;
    final settledVerified = completion?.isVerified ?? false;
    final settledRejected = completion?.isRejected ?? false;
    // Withdrawn or run out (#154). These were falling through to _Agreed, so a
    // request that ended without an answer left the starter watching a spinner
    // for something that no longer existed.
    final settledDead =
        completion?.status == ChallengeCompletionStatus.cancelled ||
        completion?.status == ChallengeCompletionStatus.expired;
    // The watch gave up (2 minutes). Nothing re-armed it and nothing read this,
    // so a pair who took longer than that left the starter on "waiting for X"
    // forever — and their XP never appeared even after the partner confirmed.
    final gaveUp = watched?.timedOut ?? false;

    // Points come from the server once settled, and only fall back to the
    // challenge's face value while still pending.
    final points = settledVerified
        ? (completion?.pointsEarned ?? widget.points ?? 0)
        : (widget.points ?? 0);

    final challengeName =
        completion?.challengeName ?? widget.challengeName ?? '';
    final challengeDescription =
        completion?.challenge?.description ?? widget.challengeDescription;
    final otherName = widget.otherName ?? l10n.challengeCompletionDefaultName;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.colors.onSurface),
          onPressed: _dismiss,
        ),
        title: Text(
          l10n.challengeTogetherTitle,
          style: KolabingTextStyles.titleSmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: settledVerified
              ? _Reveal(
                  points: points,
                  otherName: otherName,
                  photoPath: widget.photoPath,
                  otherProfileId: widget.otherProfileId,
                )
              : settledRejected
              ? _Rejected(onDone: _dismiss)
              : settledDead
              ? _NoLongerWaiting(onDone: _dismiss)
              : gaveUp
              ? _StoppedWatching(
                  otherName: otherName,
                  onKeepWaiting: () => ref
                      .read(
                        completionWatchProvider(widget.completionId).notifier,
                      )
                      .start(),
                  onDone: _dismiss,
                )
              : _Agreed(
                  challengeName: challengeName,
                  challengeDescription: challengeDescription,
                  otherName: otherName,
                  points: points,
                  role: widget.role,
                  submitting: _submitting,
                  onConfirm: () => _decide(confirm: true),
                  onDecline: () => _decide(confirm: false),
                  cancelling: _cancelling,
                  onCancel: _cancel,
                ),
        ),
      ),
    );
  }
}

/// What both devices show between agreeing and the reveal. Identical on both,
/// except that the partner has the buttons.
class _Agreed extends StatelessWidget {
  const _Agreed({
    required this.challengeName,
    required this.challengeDescription,
    required this.otherName,
    required this.points,
    required this.role,
    required this.submitting,
    required this.onConfirm,
    required this.onDecline,
    required this.cancelling,
    required this.onCancel,
  });

  final String challengeName;
  final String? challengeDescription;
  final String otherName;
  final int points;
  final TogetherRole role;
  final bool submitting;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  /// Withdrawing is the starter's only move while they wait (#154).
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        const Spacer(),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: context.colors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.users,
            size: 40,
            color: context.colors.charcoal,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          challengeName.isEmpty
              ? l10n.challengeTogetherTitle
              : l10n.challengeTogetherPrompt(challengeName),
          textAlign: TextAlign.center,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        // The instruction, not just the label. Without it the screen names a
        // game and never says how to play it.
        if (challengeDescription != null &&
            challengeDescription!.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            challengeDescription!,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.sm),
        // Both sides earn, and saying so is the whole point of the change.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.colors.xpGreenContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.challengeTogetherEachEarns(points),
            style: KolabingTextStyles.labelLarge.copyWith(
              color: context.colors.xpGreenOnContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (role == TogetherRole.partner) ...[
          SizedBox(
            width: double.infinity,
            child: KolabingButton(
              label: l10n.challengeCompletionVerify,
              onPressed: submitting ? null : onConfirm,
              variant: KolabingButtonVariant.primary,
              isLoading: submitting,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: submitting ? null : onDecline,
              child: Text(
                l10n.challengeCompletionReject,
                style: KolabingTextStyles.button.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
          ),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Flexible(
                child: Text(
                  l10n.challengeTogetherWaiting(otherName),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        if (role == TogetherRole.starter) ...[
          const SizedBox(height: KolabingSpacing.sm),
          TextButton(
            onPressed: cancelling ? null : onCancel,
            child: Text(
              l10n.challengeTogetherCancel,
              style: KolabingTextStyles.button.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

/// The same reveal on both devices — and it ends on the **person**, not the
/// number (#183).
///
/// This used to close on "+15 XP each" and a Done button, which is the whole
/// reason a completed challenge left two ledger rows and no relationship. The
/// points are still here; they are just no longer the last thing you read.
///
/// The frame, when the challenge produced one, is the hero: it is drawn from
/// the local file so it appears instantly, while the upload happens somewhere
/// else entirely.
class _Reveal extends ConsumerStatefulWidget {
  const _Reveal({
    required this.points,
    required this.otherName,
    this.photoPath,
    this.otherProfileId,
  });

  final int points;
  final String otherName;
  final String? photoPath;
  final String? otherProfileId;

  @override
  ConsumerState<_Reveal> createState() => _RevealState();
}

class _RevealState extends ConsumerState<_Reveal> {
  /// null = not asked yet, true = sent, false = the graph is not available.
  bool? _friendRequested;
  bool _sendingFriendRequest = false;

  /// An encounter is a fact; a friendship is a choice. This is where the choice
  /// is offered — once, quietly, and never imposed.
  Future<void> _addFriend() async {
    final id = widget.otherProfileId;
    if (id == null || _sendingFriendRequest) return;
    setState(() => _sendingFriendRequest = true);
    try {
      await ref.read(friendshipServiceProvider).sendRequest(id);
      if (!mounted) return;
      setState(() {
        _sendingFriendRequest = false;
        _friendRequested = true;
      });
    } on FriendshipException catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingFriendRequest = false;
        // Already friends, or a request already open, both read as "done" to
        // the person tapping. Only a genuinely absent backend hides the row.
        _friendRequested = e.isFeatureOff ? false : true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photoPath = widget.photoPath;
    final canOfferFriend =
        widget.otherProfileId != null && _friendRequested != false;

    return Column(
      children: [
        const Spacer(),
        if (photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(photoPath),
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              // The file can be gone by the time this rebuilds. That costs the
              // wall a frame; it must never cost anyone a red screen.
              errorBuilder: (context, error, stack) => _RevealMark(),
            ),
          )
        else
          _RevealMark(),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          l10n.challengeTogetherRevealTitle,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.displaySmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        // The line that changed: you met a person, and that is the fact worth
        // remembering. The XP is the receipt for it.
        Text(
          l10n.challengeTogetherMetPerson(widget.otherName),
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.lg,
            vertical: KolabingSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.colors.xpGreenContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.challengeTogetherEachEarns(widget.points),
            style: KolabingTextStyles.statNumber.copyWith(
              color: context.colors.xpGreenOnContainer,
            ),
          ),
        ),
        const Spacer(),
        if (canOfferFriend) ...[
          SizedBox(
            width: double.infinity,
            child: KolabingButton(
              label: _friendRequested == true
                  ? l10n.challengeTogetherFriendRequested
                  : l10n.challengeTogetherAddFriend,
              onPressed: _friendRequested == true ? null : _addFriend,
              isLoading: _sendingFriendRequest,
              variant: KolabingButtonVariant.secondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
        ],
        SizedBox(
          width: double.infinity,
          child: KolabingButton(
            label: l10n.commonDone,
            onPressed: () => Navigator.of(context).maybePop(),
            variant: KolabingButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}

/// The green tick, for a challenge that produced no frame.
class _RevealMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: context.colors.xpGreenContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(LucideIcons.check, size: 48, color: context.colors.xpGreen),
    );
  }
}

/// The request ended without an answer — withdrawn, or it ran out (#154).
///
/// Muted, not an error: nothing went wrong, it just is not happening.
class _NoLongerWaiting extends StatelessWidget {
  const _NoLongerWaiting({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.minusCircle,
          size: 64,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          l10n.challengeTogetherNoLongerWaiting,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: KolabingButton(
            label: l10n.commonDone,
            onPressed: onDone,
            variant: KolabingButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}

/// The watch stopped after two minutes without an answer.
///
/// It used to stop silently: `timedOut` was set and read by nothing, so the
/// starter kept looking at a spinner and "waiting for X" — and if the partner
/// confirmed after that, the XP never showed up on this screen at all. Some
/// challenges genuinely take longer than two minutes, so the honest options are
/// "keep waiting" and "leave", not a spinner that means nothing.
class _StoppedWatching extends StatelessWidget {
  const _StoppedWatching({
    required this.otherName,
    required this.onKeepWaiting,
    required this.onDone,
  });

  final String otherName;
  final VoidCallback onKeepWaiting;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.clock,
          size: 64,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          l10n.challengeTogetherStillWaitingTitle(otherName),
          textAlign: TextAlign.center,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.challengeTogetherStillWaitingBody,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: KolabingButton(
            label: l10n.challengeTogetherKeepWaiting,
            onPressed: onKeepWaiting,
            variant: KolabingButtonVariant.primary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        TextButton(onPressed: onDone, child: Text(l10n.commonDone)),
      ],
    );
  }
}

class _Rejected extends StatelessWidget {
  const _Rejected({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.xCircle, size: 64, color: context.colors.error),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          l10n.verifyQrRejectedTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.verifyQrRejectedBody,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: KolabingButton(
            label: l10n.commonDone,
            onPressed: onDone,
            variant: KolabingButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}
