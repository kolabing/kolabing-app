import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
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
    this.otherName,
    this.points,
  });

  final String completionId;
  final TogetherRole role;
  final String? challengeName;
  final String? otherName;

  /// What each side stands to earn. Server truth; never computed here.
  final int? points;

  static Future<void> open(
    BuildContext context, {
    required String completionId,
    required TogetherRole role,
    String? challengeName,
    String? otherName,
    int? points,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeTogetherScreen(
          completionId: completionId,
          role: role,
          challengeName: challengeName,
          otherName: otherName,
          points: points,
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
      otherName: completion.challengerName,
      points: completion.challenge?.points,
    );
  }

  @override
  ConsumerState<ChallengeTogetherScreen> createState() =>
      _ChallengeTogetherScreenState();
}

class _ChallengeTogetherScreenState
    extends ConsumerState<ChallengeTogetherScreen> {
  bool _submitting = false;

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

    // Points come from the server once settled, and only fall back to the
    // challenge's face value while still pending.
    final points = settledVerified
        ? (completion?.pointsEarned ?? widget.points ?? 0)
        : (widget.points ?? 0);

    final challengeName =
        completion?.challengeName ?? widget.challengeName ?? '';
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
              ? _Reveal(points: points, otherName: otherName)
              : settledRejected
              ? _Rejected(onDone: _dismiss)
              : _Agreed(
                  challengeName: challengeName,
                  otherName: otherName,
                  points: points,
                  role: widget.role,
                  submitting: _submitting,
                  onConfirm: () => _decide(confirm: true),
                  onDecline: () => _decide(confirm: false),
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
    required this.otherName,
    required this.points,
    required this.role,
    required this.submitting,
    required this.onConfirm,
    required this.onDecline,
  });

  final String challengeName;
  final String otherName;
  final int points;
  final TogetherRole role;
  final bool submitting;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

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
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

/// The same reveal on both devices.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.points, required this.otherName});

  final int points;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.colors.xpGreenContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.check,
            size: 48,
            color: context.colors.xpGreen,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          l10n.challengeTogetherRevealTitle,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.displaySmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.challengeTogetherRevealBody(otherName),
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
            l10n.challengeTogetherEachEarns(points),
            style: KolabingTextStyles.statNumber.copyWith(
              color: context.colors.xpGreenOnContainer,
            ),
          ),
        ),
        const Spacer(),
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
