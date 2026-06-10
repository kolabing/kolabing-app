import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friendship.dart';
import '../providers/friends_provider.dart';

/// NF-17 Friends list (self). Shows accepted friends from `GET /me/friends`
/// and an incoming-Requests section (Accept / Decline) with a count badge from
/// `GET /me/friend-requests`. Self-gates: when the backend hasn't deployed the
/// friend graph both providers resolve empty, so the screen shows its empty
/// state rather than an error.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final friendsAsync = ref.watch(friendsProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.primary,
        foregroundColor: KolabingColors.onSurface,
        elevation: 0,
        title: Text(
          l10n.friendsTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color: KolabingColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(friendsProvider)
            ..invalidate(friendRequestsProvider);
          await Future.wait([
            ref.read(friendsProvider.future),
            ref.read(friendRequestsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          children: [
            // Incoming requests section.
            requestsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (requests) {
                if (requests.requests.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: KolabingSpacing.md),
                  child: _RequestsSection(requests: requests),
                );
              },
            ),

            // Friends section header.
            _SectionTitle(
              icon: LucideIcons.users,
              title: l10n.friendsTitle,
              count: friendsAsync.maybeWhen(
                data: (f) => f.length,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),

            friendsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _FriendsError(
                onRetry: () => ref.invalidate(friendsProvider),
              ),
              data: (friends) {
                if (friends.isEmpty) return const _FriendsEmpty();
                return Column(
                  children: [
                    for (final friend in friends) ...[
                      _FriendTile(friend: friend),
                      const SizedBox(height: KolabingSpacing.sm),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({required this.requests});

  final FriendRequests requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: LucideIcons.userPlus,
            title: l10n.friendRequestsTitle,
            count: requests.count,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          for (final req in requests.requests) ...[
            _RequestTile(request: req),
            if (req != requests.requests.last)
              const SizedBox(height: KolabingSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.request});

  final FriendSummary request;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (_) {
      // Self-gating / transient: stay quiet, just stop the spinner.
    } finally {
      if (mounted) setState(() => _busy = false);
      ref
        ..invalidate(friendRequestsProvider)
        ..invalidate(friendsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(friendshipServiceProvider);
    final r = widget.request;
    return Row(
      children: [
        _Avatar(avatarUrl: r.avatarUrl, initial: r.initial, size: 40),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            r.name.isNotEmpty ? r.name : l10n.friendUnknownName,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_busy)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else ...[
          IconButton(
            icon: const Icon(LucideIcons.check),
            color: KolabingColors.success,
            tooltip: l10n.friendAccept,
            onPressed: () => _act(() => service.accept(r.profileId)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            color: KolabingColors.error,
            tooltip: l10n.friendDecline,
            onPressed: () => _act(() => service.decline(r.profileId)),
          ),
        ],
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});

  final FriendSummary friend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: KolabingColors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      child: InkWell(
        borderRadius: KolabingRadius.borderRadiusLg,
        onTap: () => context.push('/profile/${friend.profileId}'),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          child: Row(
            children: [
              _Avatar(
                avatarUrl: friend.avatarUrl,
                initial: friend.initial,
                size: 44,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  friend.name.isNotEmpty ? friend.name : l10n.friendUnknownName,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: KolabingColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.count,
  });

  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: KolabingColors.primary),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            title,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: KolabingColors.onSurface,
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: KolabingSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: KolabingColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurface,
                ),
              ),
            ),
          ],
        ],
      );
}

class _FriendsEmpty extends StatelessWidget {
  const _FriendsEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.users,
              size: 40,
              color: KolabingColors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.friendsEmpty,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsError extends StatelessWidget {
  const _FriendsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 40,
              color: KolabingColors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.friendsLoadError,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.textTertiary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.size,
    this.avatarUrl,
  });

  final String? avatarUrl;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _initialCircle(),
        ),
      );
    }
    return _initialCircle();
  }

  Widget _initialCircle() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: KolabingColors.onSurface,
            ),
          ),
        ),
      );
}
