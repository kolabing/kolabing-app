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
import '../../identity/models/profile_lookup_result.dart';
import '../../identity/providers/identity_provider.dart';
import '../../identity/services/identity_service.dart';
import '../models/friendship.dart';
import '../providers/friends_provider.dart';
import '../services/friendship_service.dart';

/// Add-friend-by-identifier screen (identity contract §5). Resolves an exact
/// email OR `@handle` via `GET /profiles/lookup`, then shows the matched public
/// card with the right CTA (Add / Pending / Already friends / Self) wired to
/// [FriendshipService]. Self-gates: a route 404 surfaces as a friendly empty
/// state rather than an error.
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _controller = TextEditingController();

  bool _searching = false;
  bool _searched = false;
  ProfileLookupResult? _result;
  String? _errorKey; // 'not_found' | 'feature_off' | 'generic'

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searched = true;
      _result = null;
      _errorKey = null;
    });
    try {
      final result = await ref.read(identityServiceProvider).lookup(query);
      if (!mounted) return;
      setState(() {
        _result = result;
        if (result == null) _errorKey = 'not_found';
      });
    } on IdentityException catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = e.isNotFound ? 'not_found' : 'feature_off');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorKey = 'generic');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.background,
        elevation: 0,
        title: Text(l10n.addFriendTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addFriendSubtitle,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              TextField(
                controller: _controller,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l10n.addFriendInputHint,
                  prefixIcon: const Icon(LucideIcons.atSign, size: 20),
                  filled: true,
                  fillColor: KolabingColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                    vertical: KolabingSpacing.sm,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KolabingColors.onPrimary,
                          ),
                        )
                      : const Icon(LucideIcons.search, size: 18),
                  label: Text(l10n.addFriendSearch),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KolabingRadius.md),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Expanded(child: _buildResult(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(AppLocalizations l10n) {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: KolabingColors.primary),
      );
    }
    if (_result != null) {
      return _ResultCard(
        result: _result!,
        onChanged: () => setState(() {}),
      );
    }
    if (!_searched) {
      return const SizedBox.shrink();
    }
    final message = switch (_errorKey) {
      'not_found' => l10n.addFriendNoMatch,
      'feature_off' => l10n.addFriendUnavailable,
      _ => l10n.addFriendError,
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand empty-state treatment: yellow glyph in a soft-yellow circle.
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: KolabingColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.searchX,
              size: 30,
              color: KolabingColors.primary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends ConsumerStatefulWidget {
  const _ResultCard({required this.result, required this.onChanged});

  final ProfileLookupResult result;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends ConsumerState<_ResultCard> {
  bool _busy = false;
  late FriendStatus _status =
      widget.result.friendStatus ?? FriendStatus.none;

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(friendshipServiceProvider).sendRequest(widget.result.id);
      if (!mounted) return;
      setState(() => _status = FriendStatus.pendingOutgoing);
      ref
        ..invalidate(friendsProvider)
        ..invalidate(friendRequestsProvider);
    } on FriendshipException catch (e) {
      if (e.alreadyFriends) {
        if (mounted) setState(() => _status = FriendStatus.friends);
      } else if (e.requestExists) {
        if (mounted) setState(() => _status = FriendStatus.pendingOutgoing);
      } else if (!e.isFeatureOff && mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.friendActionFailed)));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.friendActionFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.result;
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(avatarUrl: r.avatarUrl, initial: r.initial),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name.isNotEmpty ? r.name : l10n.friendUnknownName,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: KolabingColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (r.handle != null && r.handle!.isNotEmpty)
                      Text(
                        '@${r.handle}',
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),
          SizedBox(width: double.infinity, child: _buildCta(l10n)),
        ],
      ),
    );
  }

  Widget _buildCta(AppLocalizations l10n) {
    switch (_status) {
      case FriendStatus.self:
        return OutlinedButton(
          onPressed: null,
          child: Text(l10n.addFriendSelf),
        );
      case FriendStatus.friends:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.userCheck, size: 18),
          label: Text(l10n.friendFriends),
        );
      case FriendStatus.pendingOutgoing:
      case FriendStatus.pendingIncoming:
        return OutlinedButton.icon(
          onPressed: () => context.push('/profile/${widget.result.id}'),
          icon: const Icon(LucideIcons.clock, size: 18),
          label: Text(l10n.friendPending),
        );
      case FriendStatus.none:
        return ElevatedButton.icon(
          onPressed: _busy ? null : _add,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KolabingColors.onPrimary,
                  ),
                )
              : const Icon(LucideIcons.userPlus, size: 18),
          label: Text(l10n.friendAdd),
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KolabingRadius.md),
            ),
            elevation: 0,
          ),
        );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.avatarUrl});

  final String? avatarUrl;
  final String initial;
  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _initialCircle(),
        ),
      );
    }
    return _initialCircle();
  }

  Widget _initialCircle() => Container(
    width: _size,
    height: _size,
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
