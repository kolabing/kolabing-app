import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendee_profile_detail.dart';
import '../providers/attendee_profile_provider.dart';
import 'events_attended_screen.dart';

/// Batch 4 attendee profile screen — points, level, badges, communities and
/// the events-attended preview.
///
/// Works as a self view (the current user's id) and a public view (someone
/// else's id). When [profileId] is null it falls back to the authenticated
/// user's id, so it can be mounted as a tab without arguments.
class AttendeeProfileDetailScreen extends ConsumerWidget {
  const AttendeeProfileDetailScreen({super.key, this.profileId});

  /// Profile to display. Null means "the current user" (self view).
  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = ref.watch(authProvider).user?.id;
    final targetId = profileId ?? currentUserId;

    if (targetId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.attendeeProfileTitle)),
        body: Center(child: Text(l10n.attendeeProfileError)),
      );
    }

    final isSelf = targetId == currentUserId;
    final profileAsync = ref.watch(attendeeProfileDetailProvider(targetId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.attendeeProfileTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: l10n.attendeeProfileError,
          onRetry: () =>
              ref.invalidate(attendeeProfileDetailProvider(targetId)),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(attendeeProfileDetailProvider(targetId)),
          child: ListView(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            children: [
              _ProfileHeader(profile: profile, isSelf: isSelf),
              const SizedBox(height: KolabingSpacing.xl),
              _BadgesSection(profile: profile),
              const SizedBox(height: KolabingSpacing.xl),
              _CommunitiesSection(profile: profile),
              const SizedBox(height: KolabingSpacing.xl),
              _EventsAttendedSection(profile: profile, canSeeAll: isSelf),
              const SizedBox(height: KolabingSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Header
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.isSelf});

  final AttendeeProfileDetail profile;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final identity = profile.identity;
    final gamification = profile.gamification;
    final level = gamification.level;
    final levelColor = level?.color ?? KolabingColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(name: identity.name, avatarUrl: identity.avatarUrl),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          identity.name,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KolabingColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (level != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${l10n.attendeeProfileLevelLabel(level.number)} · ${level.title}',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),
              )
            else
              Text(
                l10n.attendeeProfileNoLevel,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.textTertiary,
                ),
              ),
            const SizedBox(width: KolabingSpacing.sm),
            const Icon(
              LucideIcons.star,
              size: 14,
              color: KolabingColors.warning,
            ),
            const SizedBox(width: 2),
            Text(
              l10n.attendeeProfilePoints(gamification.points),
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (level != null) ...[
          const SizedBox(height: KolabingSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: level.progressFor(gamification.points),
              minHeight: 8,
              backgroundColor: KolabingColors.darkBorder,
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.attendeeProfileXpProgress(gamification.points, level.maxXp),
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: KolabingColors.textTertiary,
            ),
          ),
        ],
        if (profile.friendsCount != null) ...[
          const SizedBox(height: KolabingSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.users,
                size: 16,
                color: KolabingColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.attendeeProfileFriendsCount(profile.friendsCount!),
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Public view only: placeholder slot the Batch 5 friends lane fills
          // with a real add-friend action. Kept isolated and inert for now.
          if (!isSelf) ...[
            const SizedBox(height: KolabingSpacing.sm),
            const AddFriendPlaceholder(),
          ],
        ],
      ],
    );
  }
}

/// Inert "Add friend" affordance shown on the public view.
///
/// Batch 5 (friends lane) replaces the [onPressed] with the real add-friend
/// flow. Kept as a separate public widget so the friends lane can swap it in
/// without touching the profile screen layout.
class AddFriendPlaceholder extends StatelessWidget {
  const AddFriendPlaceholder({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.userPlus, size: 18),
      label: Text(l10n.attendeeProfileAddFriend),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KolabingColors.primary.withValues(alpha: 0.2),
        border: Border.all(color: KolabingColors.primary, width: 3),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: KolabingColors.primary,
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'A';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// =============================================================================
// Sections
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: KolabingColors.onSurface,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
      child: Text(
        message,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: KolabingColors.textTertiary,
        ),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.profile});

  final AttendeeProfileDetail profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badges = profile.gamification.badges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.attendeeProfileBadges),
        const SizedBox(height: KolabingSpacing.sm),
        if (badges.isEmpty)
          _EmptyHint(message: l10n.attendeeProfileBadgesEmpty)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: KolabingSpacing.sm,
              crossAxisSpacing: KolabingSpacing.sm,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) => _BadgeChip(badge: badges[index]),
          ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final AttendeeBadge badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: KolabingColors.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: KolabingColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.award,
              size: 26,
              color: KolabingColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _label(badge.slug),
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: KolabingColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Humanise a badge slug (e.g. `first-event` -> `First event`) for display.
  String _label(String slug) {
    if (slug.isEmpty) {
      return '';
    }
    final words = slug.replaceAll(RegExp('[-_]+'), ' ').trim();
    if (words.isEmpty) {
      return '';
    }
    return words[0].toUpperCase() + words.substring(1);
  }
}

class _CommunitiesSection extends StatelessWidget {
  const _CommunitiesSection({required this.profile});

  final AttendeeProfileDetail profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final communities = profile.communities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.attendeeProfileCommunities),
        const SizedBox(height: KolabingSpacing.sm),
        if (communities.isEmpty)
          _EmptyHint(message: l10n.attendeeProfileCommunitiesEmpty)
        else
          ...communities.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: _CommunityTile(community: c),
            ),
          ),
      ],
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({required this.community});

  final AttendeeCommunity community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAvatar =
        community.avatarUrl != null && community.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KolabingColors.darkBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: KolabingColors.secondary.withValues(alpha: 0.15),
            backgroundImage: hasAvatar
                ? NetworkImage(community.avatarUrl!)
                : null,
            child: hasAvatar
                ? null
                : Text(
                    community.name.isNotEmpty
                        ? community.name[0].toUpperCase()
                        : '?',
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.secondary,
                    ),
                  ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (community.tierName != null &&
                    community.tierName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    community.tierName!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (community.canManage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: KolabingColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.crown,
                    size: 12,
                    color: KolabingColors.info,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.attendeeProfileManageBadge,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.info,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EventsAttendedSection extends StatelessWidget {
  const _EventsAttendedSection({
    required this.profile,
    required this.canSeeAll,
  });

  final AttendeeProfileDetail profile;
  final bool canSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recent = profile.eventsAttended.recent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.attendeeProfileEventsAttendedSection,
          // The full list reads `/me/events-attended`, which is self-only, so
          // only offer "see all" on the self view.
          trailing: canSeeAll && recent.isNotEmpty
              ? TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EventsAttendedScreen(),
                    ),
                  ),
                  child: Text(l10n.attendeeProfileSeeAll),
                )
              : null,
        ),
        const SizedBox(height: KolabingSpacing.sm),
        if (recent.isEmpty)
          _EmptyHint(message: l10n.attendeeProfileEventsAttendedEmpty)
        else
          ...recent.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: AttendedEventTile(event: e),
            ),
          ),
      ],
    );
  }
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
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
