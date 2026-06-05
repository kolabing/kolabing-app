import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/friend_providers.dart';

/// Reusable add-friend control for any attendee profile header.
///
/// States (driven by [friendRelationshipProvider] for [profileId]):
/// - `none`            → "Add"      → sends a request.
/// - `requestSent`     → "Pending"  → menu to cancel the request.
/// - `requestReceived` → "Respond"  → menu to accept / decline.
/// - `friends`         → "Friends ▾"→ menu to unfriend / block.
/// - `blocked`         → "Blocked"  → menu to unblock.
///
/// Drop it into the attendee-profile lane as `FriendActionButton(profileId: id)`.
/// Pass [profileName] so confirmation dialogs can name the person.
class FriendActionButton extends ConsumerStatefulWidget {
  const FriendActionButton({
    required this.profileId,
    super.key,
    this.profileName,
    this.compact = false,
  });

  final String profileId;
  final String? profileName;

  /// When true, render a tighter button (for list rows / suggested cards).
  final bool compact;

  @override
  ConsumerState<FriendActionButton> createState() => _FriendActionButtonState();
}

enum _FriendMenuAction { cancel, accept, decline, unfriend, block, unblock }

class _FriendActionButtonState extends ConsumerState<FriendActionButton> {
  bool _busy = false;

  String get _name =>
      widget.profileName ?? AppLocalizations.of(context).friendFallbackName;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(title),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _onMenu(_FriendMenuAction action) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(friendsProvider.notifier);
    final incomingId = ref.read(incomingFriendshipIdProvider(widget.profileId));
    switch (action) {
      case _FriendMenuAction.accept:
        if (incomingId != null) {
          await _run(() => notifier.acceptRequest(incomingId));
        }
      case _FriendMenuAction.decline:
        if (incomingId != null) {
          await _run(() => notifier.declineRequest(incomingId));
        }
      case _FriendMenuAction.cancel:
        await _run(() => notifier.unfriend(widget.profileId));
      case _FriendMenuAction.unfriend:
        if (await _confirm(
          l10n.friendUnfriendTitle,
          l10n.friendUnfriendBody(_name),
        )) {
          await _run(() => notifier.unfriend(widget.profileId));
        }
      case _FriendMenuAction.block:
        if (await _confirm(
          l10n.friendBlockTitle,
          l10n.friendBlockBody(_name),
        )) {
          await _run(() => notifier.block(widget.profileId));
        }
      case _FriendMenuAction.unblock:
        await _run(
          () => ref.read(friendServiceProvider).unblock(widget.profileId),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final relationship = ref.watch(
      friendRelationshipProvider(widget.profileId),
    );

    if (_busy) {
      return const SizedBox(
        height: 36,
        width: 36,
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    switch (relationship) {
      case FriendRelationship.none:
        return _AddButton(
          compact: widget.compact,
          label: l10n.friendActionAdd,
          onPressed: () => _run(
            () => ref
                .read(friendsProvider.notifier)
                .sendRequest(widget.profileId),
          ),
        );

      case FriendRelationship.requestSent:
        return _MenuButton(
          icon: LucideIcons.clock,
          label: l10n.friendActionPending,
          compact: widget.compact,
          items: [
            _menuItem(
              _FriendMenuAction.cancel,
              LucideIcons.x,
              l10n.friendActionCancelRequest,
            ),
          ],
          onSelected: _onMenu,
        );

      case FriendRelationship.requestReceived:
        return _MenuButton(
          icon: LucideIcons.userCheck,
          label: l10n.friendActionRespond,
          compact: widget.compact,
          highlight: true,
          items: [
            _menuItem(
              _FriendMenuAction.accept,
              LucideIcons.check,
              l10n.friendActionAccept,
            ),
            _menuItem(
              _FriendMenuAction.decline,
              LucideIcons.x,
              l10n.friendActionDecline,
            ),
          ],
          onSelected: _onMenu,
        );

      case FriendRelationship.friends:
        return _MenuButton(
          icon: LucideIcons.userCheck,
          label: l10n.friendActionFriends,
          compact: widget.compact,
          items: [
            _menuItem(
              _FriendMenuAction.unfriend,
              LucideIcons.userMinus,
              l10n.friendActionUnfriend,
            ),
            _menuItem(
              _FriendMenuAction.block,
              LucideIcons.ban,
              l10n.friendActionBlock,
              destructive: true,
            ),
          ],
          onSelected: _onMenu,
        );

      case FriendRelationship.blocked:
        return _MenuButton(
          icon: LucideIcons.ban,
          label: l10n.friendActionBlocked,
          compact: widget.compact,
          items: [
            _menuItem(
              _FriendMenuAction.unblock,
              LucideIcons.userPlus,
              l10n.friendActionUnblock,
            ),
          ],
          onSelected: _onMenu,
        );
    }
  }

  PopupMenuItem<_FriendMenuAction> _menuItem(
    _FriendMenuAction value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) {
    final color = destructive ? KolabingColors.error : KolabingColors.onSurface;
    return PopupMenuItem<_FriendMenuAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.label,
    required this.onPressed,
    required this.compact,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: const Icon(LucideIcons.userPlus, size: 18),
    label: Text(label),
    style: FilledButton.styleFrom(
      backgroundColor: KolabingColors.primary,
      foregroundColor: KolabingColors.onPrimary,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : null,
      visualDensity: compact ? VisualDensity.compact : null,
    ),
  );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.items,
    required this.onSelected,
    required this.compact,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final List<PopupMenuItem<_FriendMenuAction>> items;
  final ValueChanged<_FriendMenuAction> onSelected;
  final bool compact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? KolabingColors.onPrimary : KolabingColors.onSurface;
    final bg = highlight
        ? KolabingColors.primary
        : KolabingColors.surfaceContainerHigh;
    return PopupMenuButton<_FriendMenuAction>(
      onSelected: onSelected,
      itemBuilder: (_) => items,
      position: PopupMenuPosition.under,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KolabingColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 13 : 14,
              ),
            ),
            Icon(LucideIcons.chevronDown, size: 14, color: fg),
          ],
        ),
      ),
    );
  }
}
