import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../providers/blocked_profiles_provider.dart';
import '../services/moderation_service.dart';

/// Bottom sheet that lets a user report objectionable content
/// (App Review Guideline 1.2).
///
/// Presents the four report reasons as selectable chips plus an optional note,
/// then submits via [ModerationService.report]. Shows a success/error snackbar
/// and pops on success.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    required this.targetType,
    required this.targetId,
    this.reportedProfileId,
    super.key,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String? reportedProfileId;

  /// Present the report sheet. Returns `true` if a report was submitted.
  static Future<bool?> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? reportedProfileId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        targetType: targetType,
        targetId: targetId,
        reportedProfileId: reportedProfileId,
      ),
    );
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  ReportReason? _reason;
  final TextEditingController _note = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return l10n.moderationReasonSpam;
      case ReportReason.harassment:
        return l10n.moderationReasonHarassment;
      case ReportReason.inappropriate:
        return l10n.moderationReasonInappropriate;
      case ReportReason.other:
        return l10n.moderationReasonOther;
    }
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(moderationServiceProvider)
          .report(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: reason,
            reportedProfileId: widget.reportedProfileId,
            note: _note.text,
          );
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.moderationReportSuccess)),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.moderationReportError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.lg,
          KolabingSpacing.md,
          KolabingSpacing.lg,
          KolabingSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                l10n.moderationReportSheetTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                l10n.moderationReportSheetSubtitle,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Wrap(
                spacing: KolabingSpacing.sm,
                runSpacing: KolabingSpacing.sm,
                children: [
                  for (final reason in ReportReason.values)
                    ChoiceChip(
                      label: Text(_reasonLabel(l10n, reason)),
                      selected: _reason == reason,
                      onSelected: _submitting
                          ? null
                          : (_) => setState(() => _reason = reason),
                    ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.md),
              TextField(
                controller: _note,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.moderationNoteHint,
                  border: OutlineInputBorder(
                    borderRadius: KolabingRadius.borderRadiusMd,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              KolabingButton(
                label: l10n.moderationSubmitReport,
                isLoading: _submitting,
                isDisabled: _reason == null,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
