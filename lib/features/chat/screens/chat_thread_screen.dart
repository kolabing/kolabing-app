import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/models/community_tier.dart';
import '../../community/providers/community_providers.dart';
import '../../community/services/community_service.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../providers/chat_providers.dart';
import '../services/chat_service.dart';
import '../services/realtime_chat_service.dart';

/// A single conversation: message list + composer. Messages are held in local
/// state (the screen is ephemeral) — no provider needed.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.thread});

  final ChatThread thread;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  RealtimeThreadSubscription? _realtimeSub;

  /// Local copy so a rename updates the title without leaving the screen.
  late ChatThread _thread = widget.thread;

  ChatService get _svc => ref.read(chatServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
    // NF-16 B4 — live updates via Laravel Reverb. Subscribes to
    // `private-chat.thread.{id}` and appends inbound messages without a
    // refetch. No-op until Reverb is configured (RealtimeConfig.appKey); the
    // poll-on-open in `_load()` is the fallback / reconnect baseline.
    unawaited(_subscribeRealtime());
  }

  @override
  void dispose() {
    unawaited(_realtimeSub?.cancel());
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _subscribeRealtime() async {
    if (!RealtimeChatService.instance.isEnabled) return;
    final token = await ref.read(authServiceProvider).getToken();
    if (!mounted) return;
    _realtimeSub = await RealtimeChatService.instance.subscribeToThread(
      widget.thread.id,
      token: token,
      onMessage: _onRealtimeMessage,
    );
  }

  /// Append a live message, ignoring ones we already have (our own sends are
  /// appended optimistically in [_send] and echo back over the socket).
  void _onRealtimeMessage(ChatMessage message) {
    if (!mounted) return;
    if (_messages.any((m) => m.id == message.id)) return;
    setState(() => _messages = [..._messages, message]);
    _jumpToBottom();
    _markRead();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final msgs = await _svc.getMessages(widget.thread.id);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _markRead();
      _jumpToBottom();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markRead() async {
    try {
      await _svc.markRead(widget.thread.id);
      ref.read(chatUnreadProvider.notifier).refresh();
      ref.read(chatThreadsProvider.notifier).reload();
    } catch (_) {/* non-critical */}
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await _svc.sendMessage(widget.thread.id, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, msg];
        _composer.clear();
        _sending = false;
      });
      _jumpToBottom();
      ref.read(chatThreadsProvider.notifier).reload();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(_thread.name ?? l10n.chatThreadFallbackTitle),
        actions: [_manageMenu(l10n)],
      ),
      body: Column(
        children: [
          Expanded(child: _body(l10n)),
          _Composer(
            controller: _composer,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  // Manager-only chat management (custom community chats) --------------------

  Widget _manageMenu(AppLocalizations l10n) {
    if (_thread.type != ChatThreadType.communityCustom ||
        _thread.communityId == null) {
      return const SizedBox.shrink();
    }
    final manage = ref.watch(communityManageProvider);
    final managed = (manage.communities.asData?.value ?? const [])
        .any((c) => c.id == _thread.communityId);
    if (!managed) return const SizedBox.shrink();
    final tiers = manage.tiers.asData?.value ?? const [];
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'rename') _rename(l10n);
        if (v == 'access') _manageAccess(l10n, tiers);
        if (v == 'members') _manageMembers(l10n, tiers);
        if (v == 'delete') _delete(l10n);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
            value: 'rename',
            child: _menuRow(LucideIcons.pencil, l10n.chatManageRename)),
        PopupMenuItem<String>(
            value: 'members',
            child: _menuRow(LucideIcons.users, l10n.chatManageMembers)),
        PopupMenuItem<String>(
            value: 'access',
            child: _menuRow(LucideIcons.lock, l10n.chatManageAccess)),
        PopupMenuItem<String>(
            value: 'delete',
            child: _menuRow(LucideIcons.trash2, l10n.chatManageDelete,
                color: KolabingColors.error)),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label, {Color? color}) => Row(
        children: [
          Icon(icon, size: 18, color: color ?? KolabingColors.onSurface),
          const SizedBox(width: KolabingSpacing.sm),
          Text(label),
        ],
      );

  Future<void> _rename(AppLocalizations l10n) async {
    final controller = TextEditingController(text: _thread.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.chatManageRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              labelText: l10n.chatRenameHint,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(d, controller.text.trim()),
              child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == _thread.name) return;
    try {
      final updated = await _svc.renameCommunityChat(_thread.id, name);
      if (!mounted) return;
      setState(() => _thread = updated);
      ref.read(chatThreadsProvider.notifier).reload();
      _snack(l10n.chatRenamed);
    } on ChatException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _delete(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.chatDeleteTitle),
        content: Text(l10n.chatDeleteBody(_thread.name ?? '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteCommunityChat(_thread.id);
      ref.read(chatThreadsProvider.notifier).reload();
      if (!mounted) return;
      _snack(l10n.chatDeleted);
      Navigator.of(context).pop();
    } on ChatException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _manageAccess(
      AppLocalizations l10n, List<CommunityTier> tiers) async {
    final slug = _thread.slug;
    if (slug == null) return;
    if (tiers.isEmpty) {
      _snack(l10n.communityHubCreateTiersFirst);
      return;
    }
    final selected = {
      for (final t in tiers) t.id: t.permissions.chatChannels.contains(slug),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setLocal) => AlertDialog(
          title: Text(l10n.communityHubAccessDialogTitle(_thread.name ?? '')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
                  child: Text(l10n.communityHubAccessDialogBody,
                      style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant)),
                ),
                for (final t in tiers)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: selected[t.id] ?? false,
                    title: Text(t.name),
                    onChanged: (v) => setLocal(() => selected[t.id] = v ?? false),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: Text(l10n.commonCancel)),
            TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: Text(l10n.commonSave)),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final svc = ref.read(communityServiceProvider);
    try {
      for (final t in tiers) {
        final has = t.permissions.chatChannels.contains(slug);
        final want = selected[t.id] ?? false;
        if (has == want) continue;
        final next = [...t.permissions.chatChannels];
        if (want) {
          next.add(slug);
        } else {
          next.remove(slug);
        }
        await svc.updateTier(t.id,
            permissions: t.permissions.copyWith(chatChannels: next));
      }
      await ref.read(communityManageProvider.notifier).reloadTiers();
      ref.read(chatThreadsProvider.notifier).reload();
      if (mounted) _snack(l10n.communityHubChatAccessUpdated);
    } on CommunityException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  /// Roster of members who can access this custom chat (tier-granted + managers),
  /// with per-member block/unblock (overrides tier).
  Future<void> _manageMembers(
      AppLocalizations l10n, List<CommunityTier> tiers) async {
    final slug = _thread.slug;
    if (slug == null) return;
    final members =
        ref.read(communityManageProvider).members.asData?.value ?? const [];
    final roster = members
        .where((m) =>
            m.canManage ||
            tiers.any((t) =>
                t.id == m.tierId &&
                t.permissions.chatChannels.contains(slug)))
        .toList();

    List<String> banned;
    try {
      banned = await _svc.getChatBans(_thread.id);
    } on ChatException catch (e) {
      if (mounted) _snack(e.message);
      return;
    }
    if (!mounted) return;
    final bannedSet = {...banned};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KolabingColors.surface,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: KolabingSpacing.md,
            right: KolabingSpacing.md,
            top: KolabingSpacing.md,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + KolabingSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.chatManageMembers,
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: KolabingSpacing.md),
              if (roster.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
                  child: Text(l10n.chatMembersEmpty,
                      style: KolabingTextStyles.bodySmall
                          .copyWith(color: KolabingColors.onSurfaceVariant)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in roster)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                KolabingColors.primary.withValues(alpha: 0.2),
                            backgroundImage: m.memberAvatarUrl != null
                                ? NetworkImage(m.memberAvatarUrl!)
                                : null,
                            child: m.memberAvatarUrl == null
                                ? const Icon(LucideIcons.user, size: 16)
                                : null,
                          ),
                          title: Text(m.memberName ?? l10n.chatThreadFallbackTitle,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: bannedSet.contains(m.profileId)
                              ? Text(l10n.chatBlockedTag,
                                  style: KolabingTextStyles.bodySmall
                                      .copyWith(color: KolabingColors.error))
                              : null,
                          trailing: m.canManage
                              ? null
                              : TextButton(
                                  onPressed: () async {
                                    try {
                                      final wasBanned =
                                          bannedSet.contains(m.profileId);
                                      final updated = wasBanned
                                          ? await _svc.unblockChatMember(
                                              _thread.id, m.profileId)
                                          : await _svc.blockChatMember(
                                              _thread.id, m.profileId);
                                      setSheet(() {
                                        bannedSet
                                          ..clear()
                                          ..addAll(updated);
                                      });
                                    } on ChatException catch (e) {
                                      if (mounted) _snack(e.message);
                                    }
                                  },
                                  child: Text(bannedSet.contains(m.profileId)
                                      ? l10n.chatUnblock
                                      : l10n.chatBlock),
                                ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    ref.read(chatThreadsProvider.notifier).reload();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _body(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: context.colors.onSurfaceVariant)),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(l10n.chatThreadEmptyMessage,
            style: KolabingTextStyles.bodyMedium
                .copyWith(color: context.colors.onSurfaceVariant)),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md, vertical: KolabingSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine
              ? context.colors.primary
              : context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(message.sender.name,
                  style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurfaceVariant)),
            Text(message.body,
                style: KolabingTextStyles.bodyMedium.copyWith(
                    color: mine
                        ? context.colors.onPrimary
                        : context.colors.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
              top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).chatComposerHint,
                  filled: true,
                  fillColor: context.colors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.md,
                      vertical: KolabingSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Material(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: sending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.onSurface))
                      : Icon(LucideIcons.send,
                          size: 20, color: context.colors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
