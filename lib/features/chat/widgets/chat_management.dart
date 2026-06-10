import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
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
      await ref.read(chatServiceProvider).renameThread(thread.id, name);
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
      await ref.read(chatServiceProvider).deleteThread(thread.id);
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

  /// Confirm then ban [participant] from [thread]. Returns true if removed.
  static Future<bool> removeMember(
    BuildContext context,
    WidgetRef ref,
    ChatThread thread,
    ChatParticipant participant,
  ) async {
    final l10n = AppLocalizations.of(context);
    final profileId = participant.profileId;
    if (profileId == null) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.chatMemberRemoveTitle(participant.name)),
        content: Text(l10n.chatMemberRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: Text(l10n.chatMemberRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await ref.read(chatServiceProvider).removeMember(thread.id, profileId);
      ref.read(chatThreadsProvider.notifier).reload();
      if (context.mounted) {
        _snack(context, l10n.chatMemberRemoved(participant.name));
      }
      return true;
    } on ChatException catch (e) {
      if (context.mounted) _snack(context, e.message);
      return false;
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

/// A bottom sheet listing a thread's known members (derived from message
/// senders, which carry a profile id) so a manager can ban any of them.
///
/// The backend exposes no thread-members listing, so the caller passes the
/// participants it already knows about (distinct, non-self senders gathered
/// while the thread was open).
class ChatMembersSheet extends ConsumerWidget {
  const ChatMembersSheet({
    super.key,
    required this.thread,
    required this.members,
  });

  final ChatThread thread;
  final List<ChatParticipant> members;

  static Future<void> show(
    BuildContext context, {
    required ChatThread thread,
    required List<ChatParticipant> members,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: KolabingColors.surface,
      showDragHandle: true,
      builder: (_) => ChatMembersSheet(thread: thread, members: members),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final manageable =
        members.where((m) => m.profileId != null).toList(growable: false);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          0,
          KolabingSpacing.md,
          KolabingSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KolabingSpacing.sm,
              ),
              child: Text(
                l10n.chatMembersTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (manageable.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.lg,
                ),
                child: Text(
                  l10n.chatMembersEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KolabingColors.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...manageable.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: KolabingColors.onSurface),
                    ),
                  ),
                  title: Text(m.name),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: KolabingColors.error,
                    ),
                    onPressed: () async {
                      final removed = await ChatManagement.removeMember(
                        context,
                        ref,
                        thread,
                        m,
                      );
                      if (removed && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(l10n.chatMemberRemove),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
