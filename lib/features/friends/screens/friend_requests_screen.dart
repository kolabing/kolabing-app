import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friend.dart';
import '../providers/friend_providers.dart';
import '../widgets/friend_tile.dart';

/// Friend requests inbox: incoming requests (with Accept / Decline) and sent
/// requests (shown as pending, cancellable). Embeddable as a tab body.
class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(friendsProvider).requests;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBody(
        message: e.toString(),
        onRetry: () => ref.read(friendsProvider.notifier).reloadRequests(),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyRequests(label: l10n.friendsRequestsEmpty);
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(friendsProvider.notifier).reloadRequests(),
          child: ListView(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            children: [
              if (requests.incoming.isNotEmpty) ...[
                _SectionHeader(label: l10n.friendsRequestsIncomingSection),
                ...requests.incoming.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
                    child: FriendTile(
                      friend: f,
                      trailing: _IncomingActions(friend: f),
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],
              if (requests.sent.isNotEmpty) ...[
                _SectionHeader(label: l10n.friendsRequestsSentSection),
                ...requests.sent.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
                    child: FriendTile(
                      friend: f,
                      trailing: _PendingChip(label: l10n.friendActionPending),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _IncomingActions extends ConsumerStatefulWidget {
  const _IncomingActions({required this.friend});

  final Friend friend;

  @override
  ConsumerState<_IncomingActions> createState() => _IncomingActionsState();
}

class _IncomingActionsState extends ConsumerState<_IncomingActions> {
  bool _busy = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.friend.friendshipId;
    if (_busy || id == null) {
      return const SizedBox(
        height: 32,
        width: 32,
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final notifier = ref.read(friendsProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.friendActionDecline,
          onPressed: () => _run(() => notifier.declineRequest(id)),
          icon: const Icon(LucideIcons.x),
          color: KolabingColors.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: KolabingSpacing.xs),
        FilledButton(
          onPressed: () => _run(() => notifier.acceptRequest(id)),
          style: FilledButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(l10n.friendActionAccept),
        ),
      ],
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: KolabingColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          LucideIcons.clock,
          size: 14,
          color: KolabingColors.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      bottom: KolabingSpacing.sm,
      top: KolabingSpacing.xs,
    ),
    child: Text(
      label.toUpperCase(),
      style: KolabingTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: KolabingColors.onSurfaceVariant,
      ),
    ),
  );
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.inbox,
            size: 32,
            color: KolabingColors.onSurfaceVariant,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            label,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
