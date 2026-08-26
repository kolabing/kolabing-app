/// The leader-facing pieces of the merged community page (#174).
///
/// Identity, the two actions a leader reaches for most, and **Manage** — the
/// surfaces that used to be scattered down the Community tab behind twenty
/// separate `canManage` checks, gathered into one block that is either there or
/// not there.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/community.dart';
import '../screens/roster_screen.dart';
import '../screens/tier_editor_screen.dart';
import 'community_page_sections.dart';

/// Name, then one quiet meta line: `type · N members · city`.
///
/// Deliberately not a card. The hero above it already reads as the page's
/// header; wrapping the name in a second surface made the top of the page look
/// like two competing headers.
class CommunityIdentity extends StatelessWidget {
  const CommunityIdentity({super.key, required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = <String>[
      if (community.typeSlug case final slug?) _humanize(slug),
      l10n.attendeeCommunityProfileMemberCount(community.memberCount ?? 0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          community.name,
          style: KolabingTextStyles.pageTitleSmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            meta.join(' · '),
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  static String _humanize(String slug) => slug
      .split(RegExp('[_-]'))
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}

/// The one action that belongs at the top of the page: hand out the invite.
///
/// It is alone on purpose. "New event" was here and came out — creating an event
/// is not what a leader opens this page to do, and Manage → Events is one tap
/// away for it. "Edit community" never shipped either: the service has
/// `updateCommunity()` but nothing in the app calls it, and a control that goes
/// nowhere is the trap the dead "Save for later" button already fell into.
///
/// Full width rather than half a row with a gap beside nothing.
class CommunityActionRow extends StatelessWidget {
  const CommunityActionRow({super.key, required this.community});

  final Community community;

  Future<void> _copyInvite(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final url = community.inviteUrl;
    final messenger = ScaffoldMessenger.of(context);
    if (url == null || url.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.communityManageInviteUnavailable)),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.communityManageInviteCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ActionButton(
      icon: LucideIcons.link2,
      label: l10n.communityManageInvite,
      onTap: () => _copyInvite(context),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(KolabingRadius.md),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      child: Container(
        // A fixed height, so the two buttons cannot end up different sizes
        // when one label wraps in Spanish or Catalan.
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KolabingRadius.md),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: context.colors.onSurface),
            const SizedBox(width: KolabingSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Everything a leader can run, in one block.
///
/// Renders nothing at all for a non-manager: the section is present or absent,
/// rather than a card with its rows quietly missing.
class CommunityManageSection extends ConsumerWidget {
  const CommunityManageSection({
    super.key,
    required this.community,
    required this.canManage,
    required this.onOpenEvents,
    required this.onOpenRewards,
  });

  final Community community;
  final bool canManage;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenRewards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canManage) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunitySectionLabel(l10n.communityManageSectionTitle),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(KolabingRadius.lg),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            children: [
              CommunityNavRow(
                key: const Key('communityManageMembers'),
                icon: LucideIcons.users,
                title: l10n.communityDetailTabMembers,
                subtitle: l10n.attendeeCommunityProfileMemberCount(
                  community.memberCount ?? 0,
                ),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => RosterScreen(communityId: community.id),
                  ),
                ),
              ),
              const _RowDivider(),
              CommunityNavRow(
                key: const Key('communityManageTiers'),
                icon: LucideIcons.layers,
                title: l10n.communityManageTiers,
                subtitle: l10n.communityManageTiersSubtitle,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => TierEditorScreen(communityId: community.id),
                  ),
                ),
              ),
              const _RowDivider(),
              CommunityNavRow(
                key: const Key('communityManageRewards'),
                icon: LucideIcons.gift,
                title: l10n.communityRewardsRewardsTitle,
                subtitle: l10n.communityManageRewardsSubtitle,
                onTap: onOpenRewards,
              ),
              const _RowDivider(),
              CommunityNavRow(
                key: const Key('communityManageEvents'),
                icon: LucideIcons.calendar,
                title: l10n.communityDetailTabEvents,
                subtitle: l10n.communityManageEventsSubtitle,
                onTap: onOpenEvents,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A hairline that stops short of the card's edges, so the rows read as one
/// list rather than four stacked boxes.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
    child: Divider(height: 1, thickness: 1, color: context.colors.hairline),
  );
}
