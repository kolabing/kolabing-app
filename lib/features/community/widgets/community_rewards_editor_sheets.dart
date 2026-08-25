import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/community_rewards.dart';
import '../providers/community_rewards_providers.dart';
import '../services/community_rewards_service.dart';
import '../services/community_service.dart';

/// Bottom-sheet editors for the LEADER side of the community Rewards tab:
/// Goal, Reward, and Badge. Each creates or edits via
/// [CommunityRewardsService] and reloads the admin lists on success.
///
/// Opened from `community_detail_screen.dart`'s Rewards tab. All POST/PUT/DELETE
/// surface a [CommunityException] message inline; the backend ships in parallel
/// so a not-deployed route just shows that message rather than crashing.

Future<void> showGoalEditor(
  BuildContext context, {
  required String communityId,
  CommunityGoal? goal,
}) => _showSheet(
  context,
  (_) => _GoalEditorSheet(communityId: communityId, goal: goal),
);

Future<void> showRewardEditor(
  BuildContext context, {
  required String communityId,
  CommunityReward? reward,
}) => _showSheet(
  context,
  (_) => _RewardEditorSheet(communityId: communityId, reward: reward),
);

Future<void> showBadgeEditor(
  BuildContext context, {
  required String communityId,
  CommunityBadge? badge,
}) => _showSheet(
  context,
  (_) => _BadgeEditorSheet(communityId: communityId, badge: badge),
);

Future<void> _showSheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: builder,
    );

// -----------------------------------------------------------------------------
// Shared scaffolding
// -----------------------------------------------------------------------------

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: KolabingSpacing.md,
        right: KolabingSpacing.md,
        top: KolabingSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KolabingSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _label(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(
    top: KolabingSpacing.md,
    bottom: KolabingSpacing.xs,
  ),
  child: Text(
    text,
    style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
  ),
);

Widget _saveButton(
  BuildContext context, {
  required bool busy,
  required String label,
  required VoidCallback? onPressed,
}) => Padding(
  padding: const EdgeInsets.only(top: KolabingSpacing.lg),
  child: FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: context.colors.primary,
      foregroundColor: context.colors.onPrimary,
      minimumSize: const Size.fromHeight(52),
    ),
    child: busy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.onSurface,
            ),
          )
        : Text(label),
  ),
);

// -----------------------------------------------------------------------------
// Goal editor
// -----------------------------------------------------------------------------

class _GoalEditorSheet extends ConsumerStatefulWidget {
  const _GoalEditorSheet({required this.communityId, this.goal});

  final String communityId;
  final CommunityGoal? goal;

  @override
  ConsumerState<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<_GoalEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _target;
  late final TextEditingController _rewardPoints;
  late GoalEarnType _earnType;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _title = TextEditingController(text: g?.title ?? '');
    _target = TextEditingController(text: g?.target.toString() ?? '');
    _rewardPoints = TextEditingController(
      text: g?.rewardPoints.toString() ?? '',
    );
    _earnType = g?.earnType ?? GoalEarnType.eventCheckIns;
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _rewardPoints.dispose();
    super.dispose();
  }

  String _earnTypeLabel(AppLocalizations l10n, GoalEarnType t) {
    switch (t) {
      case GoalEarnType.eventCheckIns:
        return l10n.communityGoalEarnTypeEventCheckIns;
      case GoalEarnType.challenge:
        return l10n.communityGoalEarnTypeChallenge;
      case GoalEarnType.daysInCommunity:
        return l10n.communityGoalEarnTypeDaysInCommunity;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final svc = ref.read(communityRewardsServiceProvider);
    final goal = CommunityGoal(
      id: widget.goal?.id ?? '',
      title: _title.text.trim(),
      earnType: _earnType,
      target: int.tryParse(_target.text.trim()) ?? 0,
      rewardPoints: int.tryParse(_rewardPoints.text.trim()) ?? 0,
      challengeId: widget.goal?.challengeId,
    );
    try {
      if (widget.goal != null) {
        await svc.updateGoal(widget.goal!.id, goal);
      } else {
        await svc.createGoal(widget.communityId, goal);
      }
      ref
          .read(communityRewardsAdminProvider(widget.communityId).notifier)
          .reloadGoals();
      if (mounted) Navigator.of(context).pop();
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
    return Form(
      key: _formKey,
      child: _SheetShell(
        title: widget.goal != null
            ? l10n.communityGoalEditorEditTitle
            : l10n.communityGoalEditorNewTitle,
        children: [
          _label(context, l10n.communityGoalTitleLabel),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.communityGoalTitleRequired
                : null,
          ),
          _label(context, l10n.communityGoalEarnTypeLabel),
          DropdownButtonFormField<GoalEarnType>(
            initialValue: _earnType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: GoalEarnType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(_earnTypeLabel(l10n, t)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _earnType = v ?? _earnType),
          ),
          _label(context, l10n.communityGoalTargetLabel),
          TextFormField(
            controller: _target,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1) return l10n.communityGoalTargetRequired;
              return null;
            },
          ),
          _label(context, l10n.communityGoalRewardPointsLabel),
          TextFormField(
            controller: _rewardPoints,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (int.tryParse(v ?? '') == null)
                ? l10n.communityGoalRewardPointsRequired
                : null,
          ),
          _saveButton(
            context,
            busy: _busy,
            label: l10n.rosterSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reward editor
// -----------------------------------------------------------------------------

class _RewardEditorSheet extends ConsumerStatefulWidget {
  const _RewardEditorSheet({required this.communityId, this.reward});

  final String communityId;
  final CommunityReward? reward;

  @override
  ConsumerState<_RewardEditorSheet> createState() => _RewardEditorSheetState();
}

class _RewardEditorSheetState extends ConsumerState<_RewardEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reward;
    _title = TextEditingController(text: r?.title ?? '');
    _description = TextEditingController(text: r?.description ?? '');
    _cost = TextEditingController(text: r?.costPoints.toString() ?? '');
    _stock = TextEditingController(text: r?.stock?.toString() ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _cost.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final svc = ref.read(communityRewardsServiceProvider);
    final desc = _description.text.trim();
    final stockText = _stock.text.trim();
    final reward = CommunityReward(
      id: widget.reward?.id ?? '',
      title: _title.text.trim(),
      description: desc.isEmpty ? null : desc,
      costPoints: int.tryParse(_cost.text.trim()) ?? 0,
      stock: stockText.isEmpty ? null : int.tryParse(stockText),
    );
    try {
      if (widget.reward != null) {
        await svc.updateReward(widget.reward!.id, reward);
      } else {
        await svc.createReward(widget.communityId, reward);
      }
      ref
          .read(communityRewardsAdminProvider(widget.communityId).notifier)
          .reloadRewards();
      if (mounted) Navigator.of(context).pop();
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
    return Form(
      key: _formKey,
      child: _SheetShell(
        title: widget.reward != null
            ? l10n.communityRewardEditorEditTitle
            : l10n.communityRewardEditorNewTitle,
        children: [
          _label(context, l10n.communityRewardTitleLabel),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.communityRewardTitleRequired
                : null,
          ),
          _label(context, l10n.communityRewardDescriptionLabel),
          TextFormField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          _label(context, l10n.communityRewardCostLabel),
          TextFormField(
            controller: _cost,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (int.tryParse(v ?? '') == null)
                ? l10n.communityRewardCostRequired
                : null,
          ),
          _label(context, l10n.communityRewardStockLabel),
          TextFormField(
            controller: _stock,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          _saveButton(
            context,
            busy: _busy,
            label: l10n.rosterSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Badge editor
// -----------------------------------------------------------------------------

class _BadgeEditorSheet extends ConsumerStatefulWidget {
  const _BadgeEditorSheet({required this.communityId, this.badge});

  final String communityId;
  final CommunityBadge? badge;

  @override
  ConsumerState<_BadgeEditorSheet> createState() => _BadgeEditorSheetState();
}

class _BadgeEditorSheetState extends ConsumerState<_BadgeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _value;
  late BadgeCriteriaType _criteria;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final b = widget.badge;
    _title = TextEditingController(text: b?.title ?? '');
    _value = TextEditingController(text: b?.criteriaValue.toString() ?? '');
    _criteria = b?.criteriaType ?? BadgeCriteriaType.pointsThreshold;
  }

  @override
  void dispose() {
    _title.dispose();
    _value.dispose();
    super.dispose();
  }

  String _criteriaLabel(AppLocalizations l10n, BadgeCriteriaType t) {
    switch (t) {
      case BadgeCriteriaType.pointsThreshold:
        return l10n.communityBadgeCriteriaPointsThreshold;
      case BadgeCriteriaType.eventCheckIns:
        return l10n.communityBadgeCriteriaEventCheckIns;
      case BadgeCriteriaType.daysInCommunity:
        return l10n.communityBadgeCriteriaDaysInCommunity;
      case BadgeCriteriaType.challengesCompleted:
        return l10n.communityBadgeCriteriaChallengesCompleted;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final svc = ref.read(communityRewardsServiceProvider);
    final badge = CommunityBadge(
      id: widget.badge?.id ?? '',
      title: _title.text.trim(),
      icon: widget.badge?.icon,
      criteriaType: _criteria,
      criteriaValue: int.tryParse(_value.text.trim()) ?? 0,
      challengeIds: widget.badge?.challengeIds ?? const [],
    );
    try {
      if (widget.badge != null) {
        await svc.updateBadge(widget.badge!.id, badge);
      } else {
        await svc.createBadge(widget.communityId, badge);
      }
      ref
          .read(communityRewardsAdminProvider(widget.communityId).notifier)
          .reloadBadges();
      if (mounted) Navigator.of(context).pop();
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
    final showChallenges = _criteria == BadgeCriteriaType.challengesCompleted;
    return Form(
      key: _formKey,
      child: _SheetShell(
        title: widget.badge != null
            ? l10n.communityBadgeEditorEditTitle
            : l10n.communityBadgeEditorNewTitle,
        children: [
          _label(context, l10n.communityBadgeTitleLabel),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.communityBadgeTitleRequired
                : null,
          ),
          _label(context, l10n.communityBadgeCriteriaLabel),
          DropdownButtonFormField<BadgeCriteriaType>(
            initialValue: _criteria,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: BadgeCriteriaType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(_criteriaLabel(l10n, t)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _criteria = v ?? _criteria),
          ),
          _label(context, l10n.communityBadgeValueLabel),
          TextFormField(
            controller: _value,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (int.tryParse(v ?? '') == null)
                ? l10n.communityBadgeValueRequired
                : null,
          ),
          // Challenge picker for the challenges_completed criteria. Challenges
          // are not community-scoped in the current backend, so this self-gates
          // to a hint until a community-challenges source exists.
          if (showChallenges) ...[
            _label(context, l10n.communityBadgeChallengesLabel),
            Text(
              l10n.communityBadgeChallengesEmpty,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          _saveButton(
            context,
            busy: _busy,
            label: l10n.rosterSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
