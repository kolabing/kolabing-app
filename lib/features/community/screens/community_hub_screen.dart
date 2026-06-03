import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
import 'create_community_screen.dart';

/// The Community Leader's "Community" tab.
///
/// Reads [myCommunitiesProvider]:
/// - none yet  → create-your-community empty state
/// - one       → its overview (header + tiers + roster preview)
/// - more (NF-7 Premium) → a picker; for now shows the first.
class CommunityHubScreen extends ConsumerWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCommunitiesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(myCommunitiesProvider),
      ),
      data: (communities) {
        if (communities.isEmpty) {
          return _EmptyState(onCreate: () => _openCreate(context, ref));
        }
        return _CommunityOverview(community: communities.first);
      },
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
    );
    if (created ?? false) {
      ref.invalidate(myCommunitiesProvider);
    }
  }
}

// -----------------------------------------------------------------------------
// Empty state
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              child: const Icon(LucideIcons.users,
                  size: 32, color: KolabingColors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              'Start your community',
              style: KolabingTextStyles.bodyLarge
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              'Create a community to build a member roster and set up your own '
              'tiers. Your first community is free.',
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('CREATE COMMUNITY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Single-community overview
// -----------------------------------------------------------------------------

class _CommunityOverview extends ConsumerWidget {
  const _CommunityOverview({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myCommunitiesProvider)
          ..invalidate(communityTiersProvider(community.id))
          ..invalidate(communityMembersProvider(community.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          _Header(community: community),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel('Tiers'),
          const SizedBox(height: KolabingSpacing.sm),
          _TiersSection(communityId: community.id),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel('Members'),
          const SizedBox(height: KolabingSpacing.sm),
          _MembersPreview(communityId: community.id),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
            backgroundImage: community.avatarUrl != null
                ? NetworkImage(community.avatarUrl!)
                : null,
            child: community.avatarUrl == null
                ? const Icon(LucideIcons.users, color: KolabingColors.onSurface)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${community.type.displayName}'
                  '${community.memberCount != null ? '  ·  ${community.memberCount} members' : ''}',
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(
            community.joinPolicy.allowsSelfJoin
                ? LucideIcons.globe
                : LucideIcons.lock,
            size: 18,
            color: KolabingColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _TiersSection extends ConsumerWidget {
  const _TiersSection({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityTiersProvider(communityId));
    return async.when(
      loading: () => const _InlineLoader(),
      error: (e, _) => _InlineError(message: e.toString()),
      data: (tiers) {
        if (tiers.isEmpty) {
          return _InlineHint(
            icon: LucideIcons.layers,
            text: 'No tiers yet. Add tiers to give members a status ladder.',
          );
        }
        return Column(children: tiers.map((t) => _TierRow(tier: t)).toList());
      },
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier});

  final CommunityTier tier;

  @override
  Widget build(BuildContext context) {
    Color dot;
    try {
      dot = tier.color != null
          ? Color(int.parse(tier.color!.replaceFirst('#', '0xff')))
          : KolabingColors.primary;
    } catch (_) {
      dot = KolabingColors.primary;
    }
    final detail = tier.assignmentRule.isAutomatic && tier.threshold != null
        ? '${tier.assignmentRule.displayName} · ${tier.threshold} ${tier.assignmentRule.thresholdUnit}'
        : tier.assignmentRule.displayName;
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md, vertical: KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tier.name,
                        style: KolabingTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (tier.isDefault) ...[
                      const SizedBox(width: KolabingSpacing.xs),
                      _Chip(label: 'DEFAULT'),
                    ],
                  ],
                ),
                Text(detail,
                    style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 12, color: KolabingColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text('#${tier.rank}',
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MembersPreview extends ConsumerWidget {
  const _MembersPreview({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityMembersProvider(communityId));
    return async.when(
      loading: () => const _InlineLoader(),
      error: (e, _) => _InlineError(message: e.toString()),
      data: (members) {
        if (members.isEmpty) {
          return _InlineHint(
            icon: LucideIcons.userPlus,
            text: 'No members yet. Invite people or share your join link.',
          );
        }
        final preview = members.take(5).toList();
        return Column(
          children: [
            for (final m in preview) _MemberRow(member: m),
            if (members.length > preview.length)
              Padding(
                padding: const EdgeInsets.only(top: KolabingSpacing.xs),
                child: Text('+ ${members.length - preview.length} more',
                    style: KolabingTextStyles.bodySmall
                        .copyWith(color: KolabingColors.onSurfaceVariant)),
              ),
          ],
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: KolabingColors.surfaceContainerHigh,
            backgroundImage: member.memberAvatarUrl != null
                ? NetworkImage(member.memberAvatarUrl!)
                : null,
            child: member.memberAvatarUrl == null
                ? const Icon(LucideIcons.user, size: 16)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(member.memberName ?? 'Member',
                style: KolabingTextStyles.bodyMedium),
          ),
          if (member.canManage) ...[
            _Chip(label: 'ADMIN'),
            const SizedBox(width: KolabingSpacing.xs),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small shared bits
// -----------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: KolabingTextStyles.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: KolabingColors.onSurfaceVariant,
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurface)),
      );
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(KolabingSpacing.md),
        child: Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KolabingColors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: KolabingColors.onSurfaceVariant),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(text,
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant)),
            ),
          ],
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => _InlineHint(
        icon: LucideIcons.alertCircle,
        text: message,
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle,
                  size: 32, color: KolabingColors.error),
              const SizedBox(height: KolabingSpacing.md),
              Text("Couldn't load your community",
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: KolabingSpacing.xs),
              Text(message,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant)),
              const SizedBox(height: KolabingSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
