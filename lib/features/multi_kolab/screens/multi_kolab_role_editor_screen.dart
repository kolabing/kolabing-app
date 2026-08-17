import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_input.dart';
import '../../../widgets/kolabing_segmented_control.dart';
import '../../../widgets/kolabing_top_bar.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_role.dart';
import '../providers/multi_kolab_organizer_actions.dart';
import '../providers/multi_kolab_providers.dart';
import '../widgets/multi_kolab_error_copy.dart';
import '../widgets/multi_kolab_labels.dart';

/// Add or edit one partner role.
///
/// A role is intentionally *just* a title + eligibility + capacity + value
/// exchange: the API contract has **no partner-type/category column on a
/// role** (§4). "Run club partner", "venue partner" and "open to any brand"
/// are all expressed through the title plus `eligible_account_type`, which
/// is exactly how the Explore card already renders them. Inventing a
/// category field here would be a schema change, not a UI choice.
class MultiKolabRoleEditorScreen extends ConsumerStatefulWidget {
  const MultiKolabRoleEditorScreen({
    required this.eventId,
    super.key,
    this.roleId,
  });

  final String eventId;

  /// Null when adding a new role.
  final String? roleId;

  bool get isEditing => roleId != null;

  @override
  ConsumerState<MultiKolabRoleEditorScreen> createState() =>
      _MultiKolabRoleEditorScreenState();
}

class _MultiKolabRoleEditorScreenState
    extends ConsumerState<MultiKolabRoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _need = TextEditingController();
  final _receive = TextEditingController();
  final _requirements = TextEditingController();
  final _details = TextEditingController();

  MultiKolabEligibleAccountType _eligibility =
      MultiKolabEligibleAccountType.either;
  MultiKolabCompensationType? _compensation;
  int _positionsNeeded = 1;
  bool _required = true;

  /// Already-confirmed partners for this role. The backend rejects an edit
  /// that would leave `positions_filled > positions_needed`, so the stepper
  /// is clamped at this value rather than letting the organizer submit
  /// something that can only fail.
  int _positionsFilled = 0;
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in [_title, _need, _receive, _requirements, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _minPositions => _positionsFilled < 1 ? 1 : _positionsFilled;

  void _seedFrom(MultiKolabRole role) {
    if (_seeded) return;
    _seeded = true;
    _title.text = role.title;
    _need.text = role.need ?? '';
    _receive.text = role.receive ?? '';
    _requirements.text = role.requirements ?? '';
    _details.text = role.details ?? '';
    _eligibility = role.eligibleAccountType;
    _compensation = role.compensationType;
    _positionsNeeded = role.positionsNeeded;
    _positionsFilled = role.positionsFilled;
    _required = role.required_;
  }

  String? _nullIfBlank(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final actions = ref.read(multiKolabOrganizerActionsProvider.notifier);
    final result = widget.isEditing
        ? await actions.updateRole(
            widget.eventId,
            widget.roleId!,
            UpdateMultiKolabRoleInput(
              title: _title.text.trim(),
              eligibleAccountType: _eligibility,
              positionsNeeded: _positionsNeeded,
              required_: _required,
              need: _nullIfBlank(_need),
              receive: _nullIfBlank(_receive),
              compensationType: _compensation,
              requirements: _nullIfBlank(_requirements),
              details: _nullIfBlank(_details),
            ),
          )
        : await actions.addRole(
            widget.eventId,
            CreateMultiKolabRoleInput(
              title: _title.text.trim(),
              eligibleAccountType: _eligibility,
              positionsNeeded: _positionsNeeded,
              required_: _required,
              need: _nullIfBlank(_need),
              receive: _nullIfBlank(_receive),
              compensationType: _compensation,
              requirements: _nullIfBlank(_requirements),
              details: _nullIfBlank(_details),
            ),
          );

    if (!mounted) return;

    if (result == null) {
      final code = ref.read(multiKolabOrganizerActionsProvider).lastErrorCode;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(multiKolabErrorCopy(code, l10n))));
      return;
    }

    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final actionState = ref.watch(multiKolabOrganizerActionsProvider);
    final busy = actionState.isBusy('addRole', widget.eventId) ||
        actionState.isBusy('updateRole', widget.roleId ?? '');

    if (widget.isEditing && !_seeded) {
      final asyncEvent = ref.watch(
        multiKolabEventDetailProvider(widget.eventId),
      );
      final event = asyncEvent.value;
      if (event == null) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: KolabingTopBar(title: l10n.multiKolabRoleFormEditTitle),
          body: asyncEvent.hasError
              ? Center(child: Text(l10n.multiKolabExploreErrorBody))
              : const Center(child: CircularProgressIndicator()),
        );
      }
      final role = _roleIn(event);
      if (role == null) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: KolabingTopBar(title: l10n.multiKolabRoleFormEditTitle),
          body: Center(child: Text(l10n.multiKolabExploreErrorBody)),
        );
      }
      _seedFrom(role);
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: KolabingTopBar(
        title: widget.isEditing
            ? l10n.multiKolabRoleFormEditTitle
            : l10n.multiKolabRoleFormCreateTitle,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            children: [
              KolabingInput(
                key: const Key('multiKolabRoleTitleField'),
                controller: _title,
                label: l10n.multiKolabRoleFormTitleLabel,
                hint: l10n.multiKolabRoleFormTitleHint,
                maxLength: 255,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.multiKolabRoleFormTitleRequired
                    : null,
              ),
              const SizedBox(height: KolabingSpacing.md),
              _SectionLabel(l10n.multiKolabEventFormEligibilityLabel),
              KolabingSegmentedControl<MultiKolabEligibleAccountType>(
                key: const Key('multiKolabRoleEligibilityControl'),
                segments: [
                  for (final e in MultiKolabEligibleAccountType.values)
                    (e, e.label(l10n).toUpperCase()),
                ],
                selectedValue: _eligibility,
                onChanged: (e) => setState(() => _eligibility = e),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              // Makes the consequence of the choice explicit: an open role
              // becomes one ordinary offer card in the matching Explore feed.
              Container(
                key: const Key('multiKolabRoleVisibilityExplanation'),
                padding: const EdgeInsets.all(KolabingSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.yellowTint,
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.eye, size: 14, color: colors.ink),
                    const SizedBox(width: KolabingSpacing.xs),
                    Expanded(
                      child: Text(
                        _eligibility.visibilityExplanation(l10n),
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              _SectionLabel(l10n.multiKolabRoleFormPositionsLabel),
              _PositionsStepper(
                value: _positionsNeeded,
                min: _minPositions,
                onChanged: (v) => setState(() => _positionsNeeded = v),
              ),
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                _positionsFilled > 0
                    ? l10n.multiKolabRoleFormPositionsMinConfirmed(
                        _positionsFilled,
                      )
                    : l10n.multiKolabRoleFormPositionsHelper,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: colors.inkBody,
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              SwitchListTile.adaptive(
                key: const Key('multiKolabRoleRequiredSwitch'),
                contentPadding: EdgeInsets.zero,
                value: _required,
                title: Text(
                  l10n.multiKolabRoleFormRequiredLabel,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: colors.ink,
                  ),
                ),
                onChanged: (v) => setState(() => _required = v),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              KolabingInput(
                key: const Key('multiKolabRoleNeedField'),
                controller: _need,
                label: l10n.multiKolabRoleFormNeedLabel,
                maxLines: 3,
                minLines: 2,
                maxLength: 2000,
              ),
              const SizedBox(height: KolabingSpacing.md),
              KolabingInput(
                key: const Key('multiKolabRoleReceiveField'),
                controller: _receive,
                label: l10n.multiKolabRoleFormReceiveLabel,
                maxLines: 3,
                minLines: 2,
                maxLength: 2000,
              ),
              const SizedBox(height: KolabingSpacing.md),
              _SectionLabel(l10n.multiKolabRoleFormCompensationLabel),
              Wrap(
                spacing: KolabingSpacing.xs,
                runSpacing: KolabingSpacing.xs,
                children: [
                  for (final type in MultiKolabCompensationType.values)
                    ChoiceChip(
                      key: Key('multiKolabCompensation_${type.toApiValue()}'),
                      label: Text(type.label(l10n)),
                      selected: _compensation == type,
                      onSelected: (selected) => setState(
                        () => _compensation = selected ? type : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.md),
              KolabingInput(
                key: const Key('multiKolabRoleRequirementsField'),
                controller: _requirements,
                label: l10n.multiKolabRoleFormRequirementsLabel,
                maxLines: 3,
                minLines: 2,
                maxLength: 2000,
              ),
              const SizedBox(height: KolabingSpacing.md),
              KolabingInput(
                key: const Key('multiKolabRoleDetailsField'),
                controller: _details,
                label: l10n.multiKolabRoleFormDetailsLabel,
                maxLines: 3,
                minLines: 2,
                maxLength: 2000,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              KolabingButton(
                key: const Key('multiKolabRoleSaveCta'),
                label: l10n.multiKolabRoleFormSave,
                isLoading: busy,
                isDisabled: busy,
                onPressed: busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  MultiKolabRole? _roleIn(MultiKolabEvent event) {
    for (final role in event.roles) {
      if (role.id == widget.roleId) return role;
    }
    return null;
  }
}

AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context);

class _PositionsStepper extends StatelessWidget {
  const _PositionsStepper({
    required this.value,
    required this.min,
    required this.onChanged,
  });

  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canDecrease = value > min;

    return Row(
      children: [
        IconButton(
          key: const Key('multiKolabPositionsDecrease'),
          tooltip: l10nOf(context).multiKolabRoleFormPositionsLabel,
          // Minimum 48x48 tap target.
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          // A disabled button stays rendered (visibly greyed) rather than
          // disappearing, so the control does not jump around.
          onPressed: canDecrease ? () => onChanged(value - 1) : null,
          icon: const Icon(LucideIcons.minus),
        ),
        Container(
          key: const Key('multiKolabPositionsValue'),
          constraints: const BoxConstraints(minWidth: 48),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: KolabingTextStyles.titleMedium.copyWith(color: colors.ink),
          ),
        ),
        IconButton(
          key: const Key('multiKolabPositionsIncrease'),
          tooltip: l10nOf(context).multiKolabRoleFormPositionsLabel,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => onChanged(value + 1),
          icon: const Icon(LucideIcons.plus),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Text(
        text,
        style: KolabingTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.inkBody,
        ),
      ),
    );
  }
}
