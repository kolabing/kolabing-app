import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/providers/public_profile_provider.dart';
import '../models/friendship.dart';
import '../providers/friends_provider.dart';
import '../services/friendship_service.dart';

/// Member-profile-header friend CTA (NF-17), driven by [PublicProfile.friendStatus].
///
/// - `none`             → "Add friend"
/// - `pendingOutgoing`  → "Pending" + cancel
/// - `pendingIncoming`  → "Accept" / "Decline"
/// - `friends`          → "Friends" + remove
/// - `self` / null      → caller hides this widget (`supportsFriends`)
///
/// Each action runs optimistically then reloads the profile provider so the
/// authoritative `friend_status` is refetched. On a 404 (feature not deployed)
/// it degrades silently — the button just disappears on the next reload.
class FriendCtaButton extends ConsumerStatefulWidget {
  const FriendCtaButton({
    required this.profileId,
    required this.status,
    super.key,
  });

  final String profileId;
  final FriendStatus status;

  @override
  ConsumerState<FriendCtaButton> createState() => _FriendCtaButtonState();
}

class _FriendCtaButtonState extends ConsumerState<FriendCtaButton> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      // Refresh the authoritative status + any friend lists.
      ref
        ..invalidate(publicProfileProvider(widget.profileId))
        ..invalidate(friendsProvider)
        ..invalidate(friendRequestsProvider);
    } on FriendshipException catch (e) {
      // Self-gating: a 404 means the feature is off — stay quiet. Any other
      // failure shows a single, generic snackbar (no error spam).
      if (!e.isFeatureOff && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.friendActionFailed)),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.friendActionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(friendshipServiceProvider);

    switch (widget.status) {
      case FriendStatus.self:
        return const SizedBox.shrink();

      case FriendStatus.none:
        return _PrimaryPill(
          icon: LucideIcons.userPlus,
          label: l10n.friendAdd,
          busy: _busy,
          onTap: () => _run(() => service.sendRequest(widget.profileId)),
        );

      case FriendStatus.pendingOutgoing:
        return _SecondaryPill(
          icon: LucideIcons.clock,
          label: l10n.friendPending,
          busy: _busy,
          onTap: () => _run(() => service.remove(widget.profileId)),
        );

      case FriendStatus.pendingIncoming:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrimaryPill(
              icon: LucideIcons.check,
              label: l10n.friendAccept,
              busy: _busy,
              onTap: () => _run(() => service.accept(widget.profileId)),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            _SecondaryPill(
              icon: LucideIcons.x,
              label: l10n.friendDecline,
              busy: _busy,
              onTap: () => _run(() => service.decline(widget.profileId)),
            ),
          ],
        );

      case FriendStatus.friends:
        return _SecondaryPill(
          icon: LucideIcons.userCheck,
          label: l10n.friendFriends,
          busy: _busy,
          onTap: () => _confirmRemove(context, service),
        );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    FriendshipService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.friendRemoveTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.md),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.md),
                  ),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(l10n.friendRemoveConfirm),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed ?? false) {
      await _run(() => service.remove(widget.profileId));
    }
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Pill(
    icon: icon,
    label: label,
    busy: busy,
    onTap: onTap,
    background: KolabingColors.onSurface,
    foreground: KolabingColors.primary,
    border: null,
  );
}

class _SecondaryPill extends StatelessWidget {
  const _SecondaryPill({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Pill(
    icon: icon,
    label: label,
    busy: busy,
    onTap: onTap,
    background: Colors.white.withValues(alpha: 0.9),
    foreground: KolabingColors.onSurface,
    border: KolabingColors.onSurface.withValues(alpha: 0.2),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: KolabingRadius.borderRadiusRound,
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: KolabingRadius.borderRadiusRound,
          border: border != null ? Border.all(color: border!) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            else
              Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
