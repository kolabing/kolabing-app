import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/blocked_profiles_provider.dart';
import '../services/moderation_service.dart';
import 'report_sheet.dart';

/// Shared builders + handlers for the UGC-moderation overflow actions
/// ("Report" / "Block user") reused across profile, chat, kolab and review
/// surfaces (App Review Guideline 1.2).
///
/// Callers wire these into their existing `PopupMenuButton` / overflow. The
/// action keys are stable strings so a screen can switch on them in `onSelected`.
class ModerationMenu {
  ModerationMenu._();

  static const String reportAction = 'moderation_report';
  static const String blockAction = 'moderation_block';

  /// A single overflow row (icon + label) matching the app's menu style.
  static PopupMenuItem<String> _item(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? context.colors.onSurface),
          const SizedBox(width: KolabingSpacing.sm),
          Text(label),
        ],
      ),
    );
  }

  /// Overflow item: report a piece of content or a user. [label] lets the
  /// caller pick the surface-specific wording (Report user / Report this Kolab
  /// / Report review …); defaults to the generic "Report".
  static PopupMenuItem<String> reportItem(
    BuildContext context, {
    String? label,
  }) {
    final l10n = AppLocalizations.of(context);
    return _item(
      context,
      value: reportAction,
      icon: LucideIcons.flag,
      label: label ?? l10n.moderationReport,
    );
  }

  /// Overflow item: block a user.
  static PopupMenuItem<String> blockItem(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _item(
      context,
      value: blockAction,
      icon: LucideIcons.ban,
      label: l10n.moderationBlockUser,
      color: context.colors.error,
    );
  }

  /// Open the report sheet for the given target.
  static Future<void> report(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? reportedProfileId,
  }) {
    return ReportSheet.show(
      context,
      targetType: targetType,
      targetId: targetId,
      reportedProfileId: reportedProfileId,
    );
  }

  /// Confirm, then block [profileId] via [blockedProfilesProvider] (optimistic).
  /// Shows a success/error snackbar.
  static Future<void> confirmAndBlock(
    BuildContext context,
    WidgetRef ref, {
    required String profileId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.moderationBlockConfirmTitle),
        content: Text(l10n.moderationBlockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.moderationBlockConfirmAction,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(blockedProfilesProvider.notifier).block(profileId);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.moderationBlockSuccess)),
      );
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.moderationBlockError)),
      );
    }
  }
}
