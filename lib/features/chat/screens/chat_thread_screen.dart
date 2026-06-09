import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
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
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
          title: Text(widget.thread.name ?? l10n.chatThreadFallbackTitle)),
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
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(l10n.chatThreadEmptyMessage,
            style: KolabingTextStyles.bodyMedium
                .copyWith(color: KolabingColors.onSurfaceVariant)),
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
              ? KolabingColors.primary
              : KolabingColors.surfaceContainerHigh,
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
                      color: KolabingColors.onSurfaceVariant)),
            Text(message.body,
                style: KolabingTextStyles.bodyMedium.copyWith(
                    color: mine
                        ? KolabingColors.onPrimary
                        : KolabingColors.onSurface)),
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
          color: KolabingColors.surface,
          border: Border(
              top: BorderSide(color: KolabingColors.outlineVariant)),
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
                  fillColor: KolabingColors.surfaceContainerLow,
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
              color: KolabingColors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: sending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KolabingColors.onSurface))
                      : const Icon(LucideIcons.send,
                          size: 20, color: KolabingColors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
