import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friend.dart';
import '../providers/friend_providers.dart';
import 'friend_action_button.dart';

/// Horizontal row of co-attendance suggestions (>= 3 shared events). Each card
/// has an Add button. Hidden entirely when there are no suggestions.
class SuggestedFriendsSection extends ConsumerWidget {
  const SuggestedFriendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(friendsProvider).suggested;

    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (suggested) {
        if (suggested.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KolabingSpacing.md,
                KolabingSpacing.md,
                KolabingSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.friendsSuggestedSection,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.friendsSuggestedSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 184,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(KolabingSpacing.md),
                itemCount: suggested.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: KolabingSpacing.sm),
                itemBuilder: (_, i) => _SuggestedCard(friend: suggested[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 148,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: KolabingColors.surfaceContainerHigh,
            backgroundImage: friend.avatarUrl != null
                ? NetworkImage(friend.avatarUrl!)
                : null,
            child: friend.avatarUrl == null
                ? const Icon(LucideIcons.user, size: 24)
                : null,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            friend.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (friend.sharedEventCount != null)
            Text(
              l10n.friendsSharedEvents(friend.sharedEventCount!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: KolabingSpacing.sm),
          FriendActionButton(
            profileId: friend.profileId,
            profileName: friend.name,
            compact: true,
          ),
        ],
      ),
    );
  }
}
