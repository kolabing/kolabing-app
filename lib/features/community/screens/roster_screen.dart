import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../../identity/services/identity_service.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/community_member.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
import '../services/community_service.dart';

/// Full roster for a community (leader / can_manage view). Tap a member to set
/// their tier, toggle the admin capability, change status, or remove them.
class RosterScreen extends ConsumerWidget {
  const RosterScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityManageProvider).members;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.rosterTitle),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: l10n.rosterInviteTooltip,
            onPressed: () => _invite(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Text(e.toString(),
                textAlign: TextAlign.center,
                style: KolabingTextStyles.bodySmall
                    .copyWith(color: context.colors.onSurfaceVariant)),
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return _EmptyRoster(onInvite: () => _invite(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(communityManageProvider.notifier).reloadMembers(),
            child: ListView.separated(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              itemCount: members.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: KolabingSpacing.xs),
              itemBuilder: (_, i) => _MemberTile(
                member: members[i],
                onTap: () => _editMember(context, ref, members[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editMember(
    BuildContext context,
    WidgetRef ref,
    CommunityMember member,
  ) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) =>
          _MemberEditSheet(communityId: communityId, member: member),
    );
    if (changed ?? false) {
      ref.read(communityManageProvider.notifier).reloadMembers();
    }
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final identifier = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.rosterInviteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rosterInviteBody),
            const SizedBox(height: KolabingSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l10n.rosterInviteIdentifierLabel,
                hintText: l10n.rosterInviteIdentifierHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim().toLowerCase()),
            child: Text(l10n.rosterInvite),
          ),
        ],
      ),
    );
    if (identifier == null || identifier.isEmpty) return;

    // Branch on the identifier shape: an "@" with a "." is an email; otherwise
    // treat it as a @handle (the backend resolves either — contract §6).
    final isEmail = identifier.contains('@') && identifier.contains('.');
    final handle = identifier.startsWith('@')
        ? identifier.substring(1)
        : identifier;
    if (!isEmail && !IdentityService.isValidHandleFormat(handle)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.rosterInviteInvalidIdentifier)));
      }
      return;
    }
    try {
      await ref.read(communityServiceProvider).addMember(
            communityId,
            email: isEmail ? identifier : null,
            handle: isEmail ? null : handle,
          );
      ref.read(communityManageProvider.notifier).reloadMembers();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.rosterMemberAdded)));
      }
    } on CommunityException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.isProfileNotFound
                ? l10n.rosterNoAccountForIdentifier
                : e.message)));
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final CommunityMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CompactListCard(
      onTap: onTap,
      child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.surfaceContainerHigh,
                backgroundImage: member.memberAvatarUrl != null
                    ? NetworkImage(member.memberAvatarUrl!)
                    : null,
                child: member.memberAvatarUrl == null
                    ? const Icon(LucideIcons.user, size: 18)
                    : null,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        member.memberName ??
                            AppLocalizations.of(context).rosterMemberFallback,
                        style: KolabingTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    if (!member.isActive)
                      Text(member.status.displayName,
                          style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (member.canManage)
                Icon(LucideIcons.shield,
                    size: 16, color: context.colors.onSurfaceVariant),
              const SizedBox(width: KolabingSpacing.xs),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: context.colors.onSurfaceVariant),
            ],
          ),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onInvite});
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: EmptyStateCard(
        icon: LucideIcons.users,
        title: l10n.rosterEmptyTitle,
        action: FilledButton.icon(
          onPressed: onInvite,
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: Text(l10n.rosterInviteMember),
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Member edit sheet
// -----------------------------------------------------------------------------

class _MemberEditSheet extends ConsumerStatefulWidget {
  const _MemberEditSheet({required this.communityId, required this.member});

  final String communityId;
  final CommunityMember member;

  @override
  ConsumerState<_MemberEditSheet> createState() => _MemberEditSheetState();
}

class _MemberEditSheetState extends ConsumerState<_MemberEditSheet> {
  late String? _tierId = widget.member.tierId;
  late bool _canManage = widget.member.canManage;
  late MembershipStatus _status = widget.member.status;
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(communityServiceProvider).updateMember(
            widget.communityId,
            widget.member.id,
            tierId: _tierId,
            canManage: _canManage,
            status: _status,
          );
      ref.read(communityManageProvider.notifier).reloadMembers();
      if (mounted) Navigator.of(context).pop(true);
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.rosterRemoveTitle),
        content: Text(l10n.rosterRemoveBody(
            widget.member.memberName ?? l10n.rosterRemoveBodyFallback)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.rosterRemove)),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(communityServiceProvider)
          .removeMember(widget.communityId, widget.member.id);
      ref.read(communityManageProvider.notifier).reloadMembers();
      if (mounted) Navigator.of(context).pop(true);
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiersAsync = ref.watch(communityManageProvider).tiers;
    return Padding(
      padding: EdgeInsets.only(
        left: KolabingSpacing.md,
        right: KolabingSpacing.md,
        top: KolabingSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KolabingSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.member.memberName ?? l10n.rosterMemberFallback,
              style: KolabingTextStyles.bodyLarge
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () {
                Navigator.of(context).pop();
                // Pass an optimistic CreatorProfile so the public-profile header
                // shows the real name + avatar instantly (no "Unknown" flash) and
                // so PublicProfileScreen can branch to the member (attendee)
                // layout before the network fetch returns. The member is an
                // attendee, not a business/community.
                context.push(
                  '/profile/${widget.member.profileId}',
                  extra: CreatorProfile(
                    id: widget.member.profileId,
                    userType: 'attendee',
                    displayNameValue: widget.member.memberName,
                    avatarUrl: widget.member.memberAvatarUrl,
                  ),
                );
              },
              icon: const Icon(LucideIcons.user, size: 16),
              label: Text(l10n.rosterViewProfile),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Tier
          Text(l10n.rosterTierLabel,
              style: KolabingTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: KolabingSpacing.xs),
          tiersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString(),
                style: KolabingTextStyles.bodySmall
                    .copyWith(color: context.colors.error)),
            data: (tiers) => DropdownButtonFormField<String?>(
              initialValue:
                  tiers.any((t) => t.id == _tierId) ? _tierId : null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: <DropdownMenuItem<String?>>[
                DropdownMenuItem(value: null, child: Text(l10n.rosterNoTier)),
                ...tiers.map((CommunityTier t) =>
                    DropdownMenuItem(value: t.id, child: Text(t.name))),
              ],
              onChanged: (v) => setState(() => _tierId = v),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Admin capability (orthogonal to tier)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rosterCanManageTitle),
            subtitle: Text(l10n.rosterCanManageSubtitle),
            value: _canManage,
            activeThumbColor: context.colors.primary,
            onChanged: (v) => setState(() => _canManage = v),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Status
          Text(l10n.rosterStatusLabel,
              style: KolabingTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: KolabingSpacing.xs),
          DropdownButtonFormField<MembershipStatus>(
            initialValue: _status,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: MembershipStatus.values
                .where((s) => s != MembershipStatus.removed)
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s.displayName)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(LucideIcons.userMinus, size: 18),
                  label: Text(l10n.rosterRemove),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.onSurface))
                      : Text(l10n.rosterSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
