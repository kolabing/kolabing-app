import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
import '../services/community_service.dart';

/// Create or edit a single [CommunityTier].
///
/// Pass [tier] to edit an existing rung, or leave null to create one. Pops
/// `true` on a successful save/delete so the caller can refresh the tier list.
/// Permissions (content/chat/perks) are stored on the model but not edited
/// here yet — that UI lands with the gating phase.
class TierEditorScreen extends ConsumerStatefulWidget {
  const TierEditorScreen({super.key, required this.communityId, this.tier});

  final String communityId;
  final CommunityTier? tier;

  bool get isEditing => tier != null;

  @override
  ConsumerState<TierEditorScreen> createState() => _TierEditorScreenState();
}

class _TierEditorScreenState extends ConsumerState<TierEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _rankController;
  late final TextEditingController _thresholdController;
  late TierAssignmentRule _rule;
  String? _color;
  bool _busy = false;

  /// Preset swatches (hex). Null color falls back to the theme primary.
  static const _swatches = [
    '#FFE28C',
    '#7AE7A3',
    '#E14D76',
    '#6C8CFF',
    '#B388FF',
    '#FF9F45',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tier;
    _nameController = TextEditingController(text: t?.name ?? '');
    _rankController = TextEditingController(text: (t?.rank ?? 1).toString());
    _thresholdController = TextEditingController(
      text: t?.threshold?.toString() ?? '',
    );
    _rule = t?.assignmentRule ?? TierAssignmentRule.manual;
    _color = t?.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rankController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final service = ref.read(communityServiceProvider);
    final name = _nameController.text.trim();
    final rank = int.tryParse(_rankController.text.trim()) ?? 1;
    final threshold = _rule.isAutomatic
        ? int.tryParse(_thresholdController.text.trim())
        : null;
    try {
      if (widget.isEditing) {
        await service.updateTier(
          widget.tier!.id,
          name: name,
          rank: rank,
          assignmentRule: _rule,
          color: _color,
          threshold: threshold,
        );
      } else {
        await service.createTier(
          widget.communityId,
          name: name,
          rank: rank,
          assignmentRule: _rule,
          color: _color,
          threshold: threshold,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.tierEditorDeleteTitle),
        content: Text(l10n.tierEditorDeleteBody(widget.tier!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.tierEditorDelete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(communityServiceProvider).deleteTier(widget.tier!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.tierEditorEditTitle : l10n.tierEditorNewTitle,
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.tierEditorDeleteTooltip,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          children: [
            _label(l10n.tierEditorNameLabel),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.tierEditorNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.tierEditorNameRequired
                  : null,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            _label(l10n.tierEditorRankLabel),
            TextFormField(
              controller: _rankController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                // Backend requires rank >= 1 (StoreCommunityTierRequest).
                if (n == null || n < 1) return l10n.tierEditorRankRequired;
                return null;
              },
            ),
            const SizedBox(height: KolabingSpacing.lg),
            _label(l10n.tierEditorColourLabel),
            const SizedBox(height: KolabingSpacing.xs),
            Wrap(
              spacing: KolabingSpacing.sm,
              children: [for (final hex in _swatches) _swatch(hex)],
            ),
            const SizedBox(height: KolabingSpacing.lg),
            _label(l10n.tierEditorRuleLabel),
            const SizedBox(height: KolabingSpacing.xs),
            DropdownButtonFormField<TierAssignmentRule>(
              initialValue: _rule,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: TierAssignmentRule.values
                  .map(
                    (r) =>
                        DropdownMenuItem(value: r, child: Text(r.displayName)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _rule = v ?? _rule),
            ),
            if (_rule.isAutomatic) ...[
              const SizedBox(height: KolabingSpacing.md),
              _label(l10n.tierEditorThresholdLabel(_rule.thresholdUnit)),
              TextFormField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixText: _rule.thresholdUnit,
                ),
                validator: (v) => (int.tryParse(v ?? '') == null)
                    ? l10n.tierEditorThresholdRequired(_rule.thresholdUnit)
                    : null,
              ),
            ],
            const SizedBox(height: KolabingSpacing.xl),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: _busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.onSurface,
                      ),
                    )
                  : Text(
                      widget.isEditing
                          ? l10n.tierEditorSave
                          : l10n.tierEditorCreate,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
    child: Text(
      text,
      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _swatch(String hex) {
    final selected = _color == hex;
    Color c;
    try {
      c = Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      c = context.colors.primary;
    }
    return GestureDetector(
      onTap: () => setState(() => _color = selected ? null : hex),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? context.colors.onSurface
                : context.colors.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: context.colors.onSurface)
            : null,
      ),
    );
  }
}
