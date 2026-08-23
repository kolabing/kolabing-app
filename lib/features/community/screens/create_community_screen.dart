import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/community.dart';
import '../providers/community_providers.dart';
import '../services/community_service.dart';

/// Minimal create-community form (the leader's first community is free).
///
/// Pops `true` on success so the caller can refresh. If the backend returns
/// `community_limit_reached`, shows the Community Premium upsell (NF-7) instead
/// of an error — creating a 2nd community is a paid feature, not a failure.
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CommunityType _type = CommunityType.other;
  CommunityJoinPolicy _joinPolicy = CommunityJoinPolicy.open;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(communityServiceProvider)
          .createCommunity(
            name: _nameController.text.trim(),
            type: _type,
            joinPolicy: _joinPolicy,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on CommunityException catch (e) {
      if (!mounted) return;
      if (e.isCommunityLimitReached) {
        _showPremiumUpsell();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showPremiumUpsell() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.createCommunityPremiumTitle),
        content: Text(l10n.createCommunityPremiumBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonGotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(l10n.createCommunityTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          children: [
            Text(
              l10n.createCommunityNameLabel,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.createCommunityNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.createCommunityNameRequired
                  : null,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              l10n.createCommunityTypeLabel,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            DropdownButtonFormField<CommunityType>(
              initialValue: _type,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: CommunityType.values
                  .map(
                    (t) =>
                        DropdownMenuItem(value: t, child: Text(t.displayName)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              l10n.createCommunityWhoCanJoin,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            SegmentedButton<CommunityJoinPolicy>(
              segments: [
                ButtonSegment(
                  value: CommunityJoinPolicy.open,
                  label: Text(l10n.createCommunityJoinAnyone),
                ),
                ButtonSegment(
                  value: CommunityJoinPolicy.inviteOnly,
                  label: Text(l10n.createCommunityJoinInviteOnly),
                ),
              ],
              selected: {_joinPolicy},
              onSelectionChanged: (s) => setState(() => _joinPolicy = s.first),
            ),
            const SizedBox(height: KolabingSpacing.xl),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.onSurface,
                      ),
                    )
                  : Text(l10n.createCommunitySubmit),
            ),
          ],
        ),
      ),
    );
  }
}
