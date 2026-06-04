import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../gamification/screens/leaderboard_screen.dart';
import '../models/community_membership.dart';
import '../providers/community_providers.dart';

/// The Community Member's view of the communities they belong to and their
/// tier in each (`GET /me/memberships`). Read-only in v1; tier perks/content
/// gating render here in later phases.
class MyCommunitiesScreen extends ConsumerWidget {
  const MyCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMembershipsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Error(
        message: e.toString(),
        onRetry: () => ref.read(myMembershipsProvider.notifier).reload(),
      ),
      data: (memberships) {
        if (memberships.isEmpty) return const _Empty();
        return RefreshIndicator(
          onRefresh: () async => ref.read(myMembershipsProvider.notifier).reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            itemCount: memberships.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: KolabingSpacing.sm),
            itemBuilder: (_, i) => _MembershipCard(membership: memberships[i]),
          ),
        );
      },
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership});

  final CommunityMembership membership;

  @override
  Widget build(BuildContext context) {
    final community = membership.community;
    final tier = membership.tier;
    Color tierColor;
    try {
      tierColor = tier?.color != null
          ? Color(int.parse(tier!.color!.replaceFirst('#', '0xff')))
          : KolabingColors.primary;
    } catch (_) {
      tierColor = KolabingColors.primary;
    }
    return Material(
      color: KolabingColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => LeaderboardScreen(
              communityId: community.id,
              communityName: community.name,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KolabingColors.outlineVariant),
          ),
          child: Row(
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
                      style: KolabingTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      community.type.displayName,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Row(
                      children: [
                        if (tier != null) ...[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: tierColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tier.name,
                            style: KolabingTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else
                          Text(
                            'No tier yet',
                            style: KolabingTextStyles.bodySmall.copyWith(
                              color: KolabingColors.onSurfaceVariant,
                            ),
                          ),
                        if (membership.canManage) ...[
                          const SizedBox(width: KolabingSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: KolabingColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ADMIN',
                              style: KolabingTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: KolabingColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              const Icon(
                LucideIcons.trophy,
                size: 18,
                color: KolabingColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

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
            child: const Icon(
              LucideIcons.users,
              size: 32,
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            "You're not in any communities yet",
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'Join a community to earn your place on its tiers and see '
            'member-only events and perks.',
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 32,
            color: KolabingColors.error,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
