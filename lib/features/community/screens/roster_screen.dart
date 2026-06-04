import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
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
    final async = ref.watch(communityMembersProvider(communityId));
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'Invite member',
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
                    .copyWith(color: KolabingColors.onSurfaceVariant)),
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return _EmptyRoster(onInvite: () => _invite(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                bumpCommunityRefresh(ref),
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
      backgroundColor: KolabingColors.surface,
      builder: (_) =>
          _MemberEditSheet(communityId: communityId, member: member),
    );
    if (changed ?? false) {
      bumpCommunityRefresh(ref);
    }
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Invite member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a member by the email on their Kolabing account.',
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim().toLowerCase()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    if (!email.contains('@') || !email.contains('.')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid email address')));
      }
      return;
    }
    try {
      await ref
          .read(communityServiceProvider)
          .addMember(communityId, email: email);
      bumpCommunityRefresh(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Member added')));
      }
    } on CommunityException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.isProfileNotFound
                ? 'No Kolabing account found for that email'
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
    return Material(
      color: KolabingColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KolabingColors.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: KolabingColors.surfaceContainerHigh,
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
                    Text(member.memberName ?? 'Member',
                        style: KolabingTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    if (!member.isActive)
                      Text(member.status.displayName,
                          style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: KolabingColors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (member.canManage)
                const Icon(LucideIcons.shield,
                    size: 16, color: KolabingColors.onSurfaceVariant),
              const SizedBox(width: KolabingSpacing.xs),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: KolabingColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onInvite});
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.users,
                  size: 32, color: KolabingColors.onSurfaceVariant),
              const SizedBox(height: KolabingSpacing.md),
              Text('No members yet',
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: KolabingSpacing.lg),
              FilledButton.icon(
                onPressed: onInvite,
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Invite a member'),
                style: FilledButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
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
      bumpCommunityRefresh(ref);
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
            'Remove ${widget.member.memberName ?? 'this member'} from the community?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(communityServiceProvider)
          .removeMember(widget.communityId, widget.member.id);
      bumpCommunityRefresh(ref);
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
    final tiersAsync = ref.watch(communityTiersProvider(widget.communityId));
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
          Text(widget.member.memberName ?? 'Member',
              style: KolabingTextStyles.bodyLarge
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: KolabingSpacing.lg),

          // Tier
          Text('Tier',
              style: KolabingTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: KolabingSpacing.xs),
          tiersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString(),
                style: KolabingTextStyles.bodySmall
                    .copyWith(color: KolabingColors.error)),
            data: (tiers) => DropdownButtonFormField<String?>(
              initialValue:
                  tiers.any((t) => t.id == _tierId) ? _tierId : null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem(value: null, child: Text('No tier')),
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
            title: const Text('Can manage this community'),
            subtitle: const Text('Admin capability — independent of tier'),
            value: _canManage,
            activeThumbColor: KolabingColors.primary,
            onChanged: (v) => setState(() => _canManage = v),
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Status
          Text('Status',
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
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KolabingColors.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KolabingColors.onSurface))
                      : const Text('SAVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
