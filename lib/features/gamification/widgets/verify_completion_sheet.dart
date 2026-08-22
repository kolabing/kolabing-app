import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_completion.dart';
import '../providers/challenge_provider.dart';
import '../services/challenge_service.dart';

/// Outcome handed back to the scanner so it can show the right result sheet.
@immutable
class VerifyOutcome {
  const VerifyOutcome.confirmed({required this.challengerName, this.points})
    : rejected = false,
      notForYou = false,
      failed = false;

  const VerifyOutcome.rejected()
    : challengerName = null,
      points = null,
      rejected = true,
      notForYou = false,
      failed = false;

  const VerifyOutcome.notForYou()
    : challengerName = null,
      points = null,
      rejected = false,
      notForYou = true,
      failed = false;

  const VerifyOutcome.failed()
    : challengerName = null,
      points = null,
      rejected = false,
      notForYou = false,
      failed = true;

  const VerifyOutcome.dismissed()
    : challengerName = null,
      points = null,
      rejected = false,
      notForYou = false,
      failed = false;

  final String? challengerName;
  final int? points;
  final bool rejected;
  final bool notForYou;
  final bool failed;

  bool get isConfirmed => !rejected && !notForYou && !failed;
}

/// Step 4 of the loop: the verifier scanned the challenger's QR and confirms
/// (or rejects) that the challenge actually happened.
///
/// The sheet names the challenge and the challenger before asking, so nobody
/// confirms blind — the scan alone only carries a completion id.
class VerifyCompletionSheet extends ConsumerStatefulWidget {
  const VerifyCompletionSheet({super.key, required this.completionId});

  final String completionId;

  static Future<VerifyOutcome> show(
    BuildContext context, {
    required String completionId,
  }) async {
    final result = await showModalBottomSheet<VerifyOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => VerifyCompletionSheet(completionId: completionId),
    );
    return result ?? const VerifyOutcome.dismissed();
  }

  @override
  ConsumerState<VerifyCompletionSheet> createState() =>
      _VerifyCompletionSheetState();
}

class _VerifyCompletionSheetState extends ConsumerState<VerifyCompletionSheet> {
  bool _loading = true;
  bool _submitting = false;
  ChallengeCompletion? _completion;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  /// How many recent completions to search for the scanned id.
  ///
  /// Read directly rather than through `myChallengeCompletionsProvider`, whose
  /// `load()` takes the endpoint's default page of 10: at a busy event that
  /// could push a just-created completion off page one and make a perfectly
  /// valid code report "not waiting for your confirmation".
  static const int _searchLimit = 50;

  /// `GET /me/challenge-completions` returns completions where the viewer is
  /// either side, so the verifier's own list is where the scanned id resolves.
  Future<void> _load() async {
    final myProfileId = ref.read(authProvider).user?.id;

    ChallengeCompletion? match;
    try {
      final response = await ref
          .read(challengeServiceProvider)
          .getMyChallengeCompletions(limit: _searchLimit);
      match = response.completions
          .where(
            (c) =>
                c.id == widget.completionId &&
                c.isPending &&
                c.verifierProfileId == myProfileId,
          )
          .firstOrNull;
    } on ChallengeException {
      match = null;
    }

    if (!mounted) return;

    if (match == null) {
      Navigator.of(context).pop(const VerifyOutcome.notForYou());
      return;
    }

    setState(() {
      _completion = match;
      _loading = false;
    });
  }

  Future<void> _submit({required bool confirm}) async {
    final completion = _completion;
    if (completion == null || _submitting) return;

    setState(() => _submitting = true);
    final service = ref.read(challengeServiceProvider);

    try {
      final updated = confirm
          ? await service.verifyChallenge(completion.id)
          : await service.rejectChallenge(completion.id);
      if (!mounted) return;

      ref.read(myChallengeCompletionsProvider.notifier).refresh();

      Navigator.of(context).pop(
        confirm
            ? VerifyOutcome.confirmed(
                challengerName: updated.challengerName,
                points: updated.pointsEarned,
              )
            : const VerifyOutcome.rejected(),
      );
    } on ChallengeException {
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pop(const VerifyOutcome.failed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completion = _completion;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: _loading || completion == null
          ? const Padding(
              padding: EdgeInsets.all(KolabingSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.colors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.badgeCheck,
                    size: 30,
                    color: context.colors.charcoal,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),
                Text(
                  l10n.verifyScanTitle,
                  style: KolabingTextStyles.labelMedium.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  _question(l10n, completion),
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.titleMedium.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: KolabingButton(
                    label: l10n.challengeCompletionVerify,
                    onPressed: _submitting
                        ? null
                        : () => _submit(confirm: true),
                    variant: KolabingButtonVariant.primary,
                    isLoading: _submitting,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => _submit(confirm: false),
                    child: Text(
                      l10n.challengeCompletionReject,
                      style: KolabingTextStyles.button.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _question(AppLocalizations l10n, ChallengeCompletion completion) {
    final name =
        completion.challengerName ?? l10n.challengeCompletionDefaultChallenger;
    final challenge = completion.challengeName ?? completion.challenge?.name;

    return challenge == null
        ? l10n.verifyScanQuestionFallback(name)
        : l10n.verifyScanQuestion(name, challenge);
  }
}
