import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/chat_thread.dart';
import '../providers/chat_providers.dart';
import '../services/chat_service.dart';

/// Reusable chat-management actions (create / rename / delete / join / ban),
/// usable from any surface — the Chats tab and the community hub — instead of
/// being trapped inside the community profile.
///
/// Each helper performs the call, refreshes [chatThreadsProvider] +
/// [chatUnreadProvider], and surfaces a snackbar. All are no-ops on cancel.
class ChatManagement {
  ChatManagement._();

  static const int maxCustomChats = 5;

  /// Prompt for a name then create a custom chat in [communityId].
  static Future<void> createCustomChat(
    BuildContext context,
    WidgetRef ref, {
    required String communityId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      context,
      title: l10n.chatManageNewChatTitle,
      confirmLabel: l10n.chatManageCreate,
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref
          .read(chatServiceProvider)
          .createCommunityChat(communityId, name: name);
      ref.read(chatThreadsProvider.notifier).reload();
      if (context.mounted) {
        _snack(context, l10n.chatManageChatCreated(name));
      }
    } on ChatException catch (e) {
      if (context.mounted) {
        _snack(
          context,
          e.isChatLimitReached
              ? l10n.chatManageChatLimit(maxCustomChats)
              : e.message,
        );
      }
    }
  }

  /// Prompt for a new name then rename [thread] (custom chats only).
  static Future<void> renameChat(
    BuildContext context,
    WidgetRef ref,
    ChatThread thread,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      context,
      title: l10n.chatManageRenameTitle,
      confirmLabel: l10n.chatManageRename,
      initial: thread.name,
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(chatServiceProvider).renameCommunityChat(thread.id, name);
      ref.read(chatThreadsProvider.notifier).reload();
      if (context.mounted) {
        _snack(context, l10n.chatManageChatRenamed);
      }
    } on ChatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  /// Confirm then soft-delete [thread] (recoverable). Returns true if deleted.
  static Future<bool> deleteChat(
    BuildContext context,
    WidgetRef ref,
    ChatThread thread,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = thread.name ?? l10n.chatThreadFallbackTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.chatManageDeleteTitle),
        content: Text(l10n.chatManageDeleteBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: Text(l10n.chatManageDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await ref.read(chatServiceProvider).deleteCommunityChat(thread.id);
      ref.read(chatThreadsProvider.notifier).reload();
      ref.read(chatUnreadProvider.notifier).refresh();
      if (context.mounted) _snack(context, l10n.chatManageChatDeleted);
      return true;
    } on ChatException catch (e) {
      if (context.mounted) _snack(context, e.message);
      return false;
    }
  }

  /// Self-join an open [thread].
  static Future<void> joinChat(
    BuildContext context,
    WidgetRef ref,
    ChatThread thread,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(chatServiceProvider).joinThread(thread.id);
      ref.read(chatThreadsProvider.notifier).reload();
      ref.read(chatUnreadProvider.notifier).refresh();
      if (context.mounted) {
        _snack(
          context,
          l10n.chatJoinedSnack(thread.name ?? l10n.chatThreadFallbackTitle),
        );
      }
    } on ChatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    }
  }

  static Future<String?> _promptName(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? initial,
  }) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.chatManageNameLabel,
            hintText: l10n.chatManageNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
