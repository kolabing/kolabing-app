import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
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
      await ref.read(communityServiceProvider).createCommunity(
            name: _nameController.text.trim(),
            type: _type,
            joinPolicy: _joinPolicy,
          );
      bumpCommunityRefresh(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on CommunityException catch (e) {
      if (!mounted) return;
      if (e.isCommunityLimitReached) {
        _showPremiumUpsell();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showPremiumUpsell() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Community Premium'),
        content: const Text(
          'Your free plan includes one community. Running more than one is part '
          'of Community Premium — coming soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(title: const Text('New community')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          children: [
            Text('Name',
                style: KolabingTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: KolabingSpacing.xs),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Kappa Delta — Beta Chi, or City Run Club',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text('Type',
                style: KolabingTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: KolabingSpacing.xs),
            DropdownButtonFormField<CommunityType>(
              initialValue: _type,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: CommunityType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text('Who can join',
                style: KolabingTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: KolabingSpacing.xs),
            SegmentedButton<CommunityJoinPolicy>(
              segments: const [
                ButtonSegment(
                  value: CommunityJoinPolicy.open,
                  label: Text('Anyone'),
                ),
                ButtonSegment(
                  value: CommunityJoinPolicy.inviteOnly,
                  label: Text('Invite only'),
                ),
              ],
              selected: {_joinPolicy},
              onSelectionChanged: (s) =>
                  setState(() => _joinPolicy = s.first),
            ),
            const SizedBox(height: KolabingSpacing.xl),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KolabingColors.onSurface,
                      ),
                    )
                  : const Text('CREATE COMMUNITY'),
            ),
          ],
        ),
      ),
    );
  }
}
