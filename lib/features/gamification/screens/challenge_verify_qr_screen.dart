import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/environment.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../providers/completion_watch_provider.dart';

/// Builds the URL a verification QR encodes.
///
/// `/qr/verify/{id}` is app-only: it is read by the in-app scanner, not opened
/// in a browser. Kept as an https URL (rather than a custom scheme) so the
/// parser can treat all Kolabing codes uniformly, and so a stray scan by a
/// generic camera app lands on the website instead of failing to resolve.
String buildVerifyQrData(String completionId) =>
    'https://${Environment.shareHost}/qr/verify/$completionId';

/// Step 3 of the loop: the challenger shows this, the verifier scans it.
///
/// The screen polls until the verifier settles the completion, then reveals the
/// XP the **server** awarded. It never computes points locally — a wrong number
/// here is worse than no number (BACKLOG FX-8).
class ChallengeVerifyQrScreen extends ConsumerWidget {
  const ChallengeVerifyQrScreen({
    super.key,
    required this.completionId,
    this.verifierName,
    this.challengeName,
  });

  final String completionId;

  /// Shown in the instruction line. Null falls back to a name-free wording.
  final String? verifierName;

  final String? challengeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final watch = ref.watch(completionWatchProvider(completionId));

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.colors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.verifyQrTitle,
          style: KolabingTextStyles.titleSmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: switch (watch) {
            CompletionWatchState(isVerified: true) => _VerifiedView(
              points: watch.completion?.pointsEarned ?? 0,
              challengeName: watch.completion?.challengeName ?? challengeName,
            ),
            CompletionWatchState(isRejected: true) => const _RejectedView(),
            CompletionWatchState(timedOut: true) => _TimedOutView(
              completionId: completionId,
            ),
            _ => _WaitingView(
              completionId: completionId,
              verifierName: verifierName,
              challengeName: challengeName,
            ),
          },
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.completionId,
    this.verifierName,
    this.challengeName,
  });

  final String completionId;
  final String? verifierName;
  final String? challengeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (challengeName != null)
          Text(
            challengeName!,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          verifierName == null
              ? l10n.verifyQrBodyFallback
              : l10n.verifyQrBody(verifierName!),
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        // White quiet zone regardless of theme: QR readers need the contrast,
        // and a themed background breaks scanning in dark mode.
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: QrImageView(
            data: buildVerifyQrData(completionId),
            size: 240,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        const Spacer(),
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
            Text(
              l10n.verifyQrWaiting,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

class _VerifiedView extends StatelessWidget {
  const _VerifiedView({required this.points, this.challengeName});

  final int points;
  final String? challengeName;

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
          l10n.verifyQrVerifiedTitle,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.displaySmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        if (challengeName != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            challengeName!,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
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
            l10n.checkinXpEarned(points),
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

class _RejectedView extends StatelessWidget {
  const _RejectedView();

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
            onPressed: () => Navigator.of(context).maybePop(),
            variant: KolabingButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}

/// The verifier walked off before scanning. The completion is still pending
/// server-side, so the way out is to keep waiting — not to fail.
class _TimedOutView extends ConsumerWidget {
  const _TimedOutView({required this.completionId});

  final String completionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          l10n.verifyQrTimeoutTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.verifyQrTimeoutBody,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: KolabingButton(
            label: l10n.verifyQrKeepWaiting,
            onPressed: () => ref
                .read(completionWatchProvider(completionId).notifier)
                .start(),
            variant: KolabingButtonVariant.primary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(l10n.commonDone),
          ),
        ),
      ],
    );
  }
}
