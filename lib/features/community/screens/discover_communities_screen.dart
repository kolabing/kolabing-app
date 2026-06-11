import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/community.dart';
import '../providers/community_providers.dart';
import '../services/community_service.dart';

/// Attendee-facing community DISCOVERY surface (`GET /communities/discover`).
///
/// Lists joinable communities (featured-first, backend-ordered) as cards with a
/// Join action wired to [CommunityService.joinCommunity]. Self-gates: when the
/// backend endpoint is not deployed yet (404 → empty list) it shows a friendly
/// "coming soon" state rather than crashing.
class DiscoverCommunitiesScreen extends ConsumerStatefulWidget {
  const DiscoverCommunitiesScreen({super.key});

  @override
  ConsumerState<DiscoverCommunitiesScreen> createState() =>
      _DiscoverCommunitiesScreenState();
}

class _DiscoverCommunitiesScreenState
    extends ConsumerState<DiscoverCommunitiesScreen> {
  /// Ids the user joined this session — their cards switch to "Joined".
  final Set<String> _joined = <String>{};

  /// Ids with a join request in flight — disables the button while awaited.
  final Set<String> _pending = <String>{};

  Future<void> _join(Community community) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pending.add(community.id));
    try {
      await ref
          .read(communityServiceProvider)
          .joinCommunity(community.id);
      if (!mounted) return;
      setState(() {
        _joined.add(community.id);
        _pending.remove(community.id);
      });
      // Refresh the attendee's memberships so the profile/Communities tab show
      // the newly joined community.
      await ref.read(myMembershipsProvider.notifier).reload();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.discoverCommunitiesJoinedToast(community.name)),
        ),
      );
    } on CommunityException catch (e) {
      if (!mounted) return;
      setState(() => _pending.remove(community.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isInviteOnly
                ? l10n.discoverCommunitiesInviteOnlyMessage(community.name)
                : l10n.discoverCommunitiesJoinError,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _pending.remove(community.id));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.discoverCommunitiesJoinError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(discoverCommunitiesProvider(null));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(title: Text(l10n.discoverCommunitiesTitle)),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KolabingColors.primary),
        ),
        error: (_, _) => _DiscoverMessage(
          icon: LucideIcons.alertCircle,
          iconColor: KolabingColors.error,
          title: l10n.discoverCommunitiesError,
          action: OutlinedButton(
            onPressed: () => ref.invalidate(discoverCommunitiesProvider(null)),
            child: Text(l10n.commonRetry),
          ),
        ),
        data: (communities) {
          if (communities.isEmpty) {
            // Empty list also covers the 404 self-gate (endpoint not deployed).
            return _DiscoverMessage(
              icon: LucideIcons.compass,
              iconColor: KolabingColors.onSurface,
              title: l10n.discoverCommunitiesEmptyTitle,
              body: l10n.discoverCommunitiesEmptyBody,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(discoverCommunitiesProvider(null)),
            child: ListView.separated(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              itemCount: communities.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: KolabingSpacing.sm),
              itemBuilder: (_, i) {
                final c = communities[i];
                return _DiscoverCard(
                  community: c,
                  joined: _joined.contains(c.id),
                  pending: _pending.contains(c.id),
                  onJoin: () => _join(c),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.community,
    required this.joined,
    required this.pending,
    required this.onJoin,
  });

  final Community community;
  final bool joined;
  final bool pending;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inviteOnly = community.joinPolicy == CommunityJoinPolicy.inviteOnly;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
                backgroundImage: community.avatarUrl != null
                    ? NetworkImage(community.avatarUrl!)
                    : null,
                child: community.avatarUrl == null
                    ? const Icon(
                        LucideIcons.users,
                        color: KolabingColors.onSurface,
                      )
                    : null,
              ),
              const SizedBox(width: KolabingSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KolabingTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: KolabingSpacing.xs,
                      runSpacing: KolabingSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Badge(label: community.type.displayName),
                        if (community.memberCount != null)
                          Text(
                            l10n.discoverCommunitiesMembers(
                              community.memberCount!,
                            ),
                            style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: KolabingColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (community.description != null &&
              community.description!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              community.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: KolabingSpacing.md),
          SizedBox(
            width: double.infinity,
            child: _buildAction(context, l10n, inviteOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    AppLocalizations l10n,
    bool inviteOnly,
  ) {
    if (joined) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(LucideIcons.check, size: 18),
        label: Text(l10n.discoverCommunitiesJoined),
      );
    }
    if (inviteOnly) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(LucideIcons.lock, size: 16),
        label: Text(l10n.discoverCommunitiesInviteOnly),
      );
    }
    return ElevatedButton(
      onPressed: pending ? null : onJoin,
      child: pending
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KolabingColors.onPrimary,
              ),
            )
          : Text(l10n.discoverCommunitiesJoin),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(KolabingRadius.sm),
        ),
        child: Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: KolabingColors.onSurface,
          ),
        ),
      );
}

class _DiscoverMessage extends StatelessWidget {
  const _DiscoverMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: KolabingColors.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: KolabingSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      );
}
