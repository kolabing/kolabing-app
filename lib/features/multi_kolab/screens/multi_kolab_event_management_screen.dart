import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_input.dart';
import '../../../widgets/kolabing_segmented_control.dart';
import '../../../widgets/kolabing_top_bar.dart';
import '../models/multi_kolab_dashboard.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import '../models/multi_kolab_spot_counts.dart';
import '../providers/multi_kolab_organizer_actions.dart';
import '../providers/multi_kolab_providers.dart';
import '../widgets/multi_kolab_error_copy.dart';
import '../widgets/multi_kolab_labels.dart';

enum _ManagementTab {
  overview,
  roles,
  applicants;

  static _ManagementTab parse(String? raw) => switch (raw) {
    'roles' => _ManagementTab.roles,
    'applicants' => _ManagementTab.applicants,
    _ => _ManagementTab.overview,
  };

  String label(AppLocalizations l10n) => switch (this) {
    _ManagementTab.overview => l10n.multiKolabManageTabOverview,
    _ManagementTab.roles => l10n.multiKolabManageTabRoles,
    _ManagementTab.applicants => l10n.multiKolabManageTabApplicants,
  };
}

/// One event's organizer cockpit: status, role-fill progress, application
/// totals, the roles themselves, the Kolabs already created, and whichever
/// lifecycle actions the current status permits.
///
/// Deliberately phone-shaped: three light sections, not a dense admin table.
class MultiKolabEventManagementScreen extends ConsumerStatefulWidget {
  const MultiKolabEventManagementScreen({
    required this.eventId,
    super.key,
    this.initialTab,
  });

  final String eventId;
  final String? initialTab;

  @override
  ConsumerState<MultiKolabEventManagementScreen> createState() =>
      _MultiKolabEventManagementScreenState();
}

class _MultiKolabEventManagementScreenState
    extends ConsumerState<MultiKolabEventManagementScreen> {
  late _ManagementTab _tab = _ManagementTab.parse(widget.initialTab);

  void _showError(String? code) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(multiKolabErrorCopy(code, l10n))));
  }

  Future<bool> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    Key? dialogKey,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: dialogKey,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.multiKolabDismissCta),
          ),
          TextButton(
            key: const Key('multiKolabDialogConfirmCta'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmEvent() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirmDialog(
      dialogKey: const Key('multiKolabConfirmEventDialog'),
      title: l10n.multiKolabConfirmEventTitle,
      body: l10n.multiKolabConfirmEventBody,
      confirmLabel: l10n.multiKolabConfirmGenericCta,
    )) {
      return;
    }
    final result = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .confirm(widget.eventId);
    if (!mounted || result != null) return;
    _showError(ref.read(multiKolabOrganizerActionsProvider).lastErrorCode);
  }

  Future<void> _completeEvent() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirmDialog(
      dialogKey: const Key('multiKolabCompleteEventDialog'),
      title: l10n.multiKolabCompleteEventTitle,
      body: l10n.multiKolabCompleteEventBody,
      confirmLabel: l10n.multiKolabConfirmGenericCta,
    )) {
      return;
    }
    final result = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .complete(widget.eventId);
    if (!mounted || result != null) return;
    _showError(ref.read(multiKolabOrganizerActionsProvider).lastErrorCode);
  }

  Future<void> _cancelEvent() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _CancelReasonDialog(),
    );
    if (reason == null || !mounted) return;

    final ok = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .cancel(widget.eventId, reason);
    if (!mounted || ok) return;
    _showError(ref.read(multiKolabOrganizerActionsProvider).lastErrorCode);
  }

  Future<void> _toggleRole(MultiKolabRole role) async {
    final l10n = AppLocalizations.of(context);
    final reopening = role.status == MultiKolabRoleStatus.closed;

    if (!reopening &&
        !await _confirmDialog(
          dialogKey: const Key('multiKolabCloseRoleDialog'),
          title: l10n.multiKolabRoleCloseConfirmTitle,
          body: l10n.multiKolabRoleCloseConfirmBody,
          confirmLabel: l10n.multiKolabRoleCloseCta,
        )) {
      return;
    }

    final result = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .setRoleStatus(
          widget.eventId,
          role.id,
          reopening ? MultiKolabRoleStatus.open : MultiKolabRoleStatus.closed,
        );
    if (!mounted || result != null) return;
    _showError(ref.read(multiKolabOrganizerActionsProvider).lastErrorCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final asyncEvent = ref.watch(multiKolabEventDetailProvider(widget.eventId));
    final asyncDashboard = ref.watch(
      multiKolabDashboardProvider(widget.eventId),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: KolabingTopBar(title: l10n.multiKolabManageTitle),
      body: SafeArea(
        child: asyncEvent.when(
          loading: () => const Center(
            key: Key('multiKolabManageLoading'),
            child: CircularProgressIndicator(),
          ),
          error: (_, _) => Center(
            key: const Key('multiKolabManageError'),
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.multiKolabExploreErrorBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  KolabingButton(
                    label: l10n.multiKolabOrganizerRetry,
                    variant: KolabingButtonVariant.secondary,
                    size: KolabingButtonSize.compact,
                    width: 200,
                    onPressed: () => ref.invalidate(
                      multiKolabEventDetailProvider(widget.eventId),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (event) => RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(multiKolabEventDetailProvider(widget.eventId))
                ..invalidate(multiKolabDashboardProvider(widget.eventId));
            },
            child: ListView(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: KolabingTextStyles.titleMedium.copyWith(
                          color: colors.ink,
                        ),
                      ),
                    ),
                    MultiKolabStatusChip.event(event.status, l10n),
                  ],
                ),
                const SizedBox(height: KolabingSpacing.sm),
                KolabingSegmentedControl<_ManagementTab>(
                  key: const Key('multiKolabManageTabs'),
                  segments: [
                    for (final t in _ManagementTab.values)
                      (t, t.label(l10n).toUpperCase()),
                  ],
                  selectedValue: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: KolabingSpacing.md),
                ...switch (_tab) {
                  _ManagementTab.overview => _overview(
                    event,
                    asyncDashboard.value,
                    l10n,
                    colors,
                  ),
                  _ManagementTab.roles => _roles(
                    event,
                    asyncDashboard.value,
                    l10n,
                  ),
                  _ManagementTab.applicants => _applicants(
                    event,
                    asyncDashboard.value,
                    l10n,
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- tabs ----------------------------------------------------------------

  List<Widget> _overview(
    MultiKolabEvent event,
    MultiKolabDashboard? dashboard,
    AppLocalizations l10n,
    KolabingColorTokens colors,
  ) {
    final counts = _aggregate(dashboard);
    // Derived from the roles, not from `role_counts`: the latter counts role
    // rows, so a single role recruiting three partners used to render as
    // "0 of 1 roles filled".
    final spots = MultiKolabSpotCounts.fromRoles(event.roles);

    return [
      Text(
        key: const Key('multiKolabManagePartnerSpots'),
        l10n.multiKolabPartnerSpotsFilled(spots.filled, spots.total),
        style: KolabingTextStyles.bodyMedium.copyWith(color: colors.ink),
      ),
      const SizedBox(height: KolabingSpacing.xxs),
      Text(
        key: const Key('multiKolabManageOpenRoles'),
        l10n.multiKolabOpenRolesCount(spots.openRoles),
        style: KolabingTextStyles.bodySmall.copyWith(color: colors.inkBody),
      ),
      if (dashboard != null) ...[
        const SizedBox(height: KolabingSpacing.sm),
        Wrap(
          key: const Key('multiKolabManageApplicationTotals'),
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xxs,
          children: [
            _CountChip(
              label: l10n.multiKolabApplicationStatusPending,
              count: counts.pending,
              tone: MultiKolabStatusTone.pending,
            ),
            _CountChip(
              label: l10n.multiKolabApplicationStatusShortlisted,
              count: counts.shortlisted,
              tone: MultiKolabStatusTone.active,
            ),
            _CountChip(
              label: l10n.multiKolabApplicationStatusAccepted,
              count: counts.accepted,
              tone: MultiKolabStatusTone.positive,
            ),
            _CountChip(
              label: l10n.multiKolabApplicationStatusDeclined,
              count: counts.declined,
              tone: MultiKolabStatusTone.negative,
            ),
          ],
        ),
      ],
      const SizedBox(height: KolabingSpacing.md),
      _ChildKolabsSection(eventId: widget.eventId, roles: event.roles),
      const SizedBox(height: KolabingSpacing.lg),
      ..._lifecycleActions(event, l10n),
    ];
  }

  List<Widget> _roles(
    MultiKolabEvent event,
    MultiKolabDashboard? dashboard,
    AppLocalizations l10n,
  ) {
    final actionState = ref.watch(multiKolabOrganizerActionsProvider);
    final editable = !event.status.isTerminal;

    if (event.roles.isEmpty) {
      return [
        _EmptyBlock(
          key: const Key('multiKolabRolesEmpty'),
          title: l10n.multiKolabRoleFormEmptyTitle,
          body: l10n.multiKolabRoleFormEmptyBody,
        ),
        const SizedBox(height: KolabingSpacing.md),
        if (editable)
          KolabingButton(
            key: const Key('multiKolabAddRoleCta'),
            label: l10n.multiKolabRoleFormAddCta,
            onPressed: () =>
                context.push(multiKolabOrganizerRoleLocation(widget.eventId)),
          ),
      ];
    }

    return [
      for (final role in event.roles) ...[
        _RoleCard(
          role: role,
          counts: dashboard?.roles
              .where((r) => r.roleId == role.id)
              .firstOrNull
              ?.applicationCounts,
          busy: actionState.isBusy('roleStatus', role.id),
          editable: editable,
          onEdit: () => context.push(
            multiKolabOrganizerRoleLocation(widget.eventId, roleId: role.id),
          ),
          onToggle: () => _toggleRole(role),
          onApplicants: () => context.push(
            multiKolabOrganizerRoleApplicationsLocation(
              eventId: widget.eventId,
              roleId: role.id,
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
      ],
      if (editable)
        KolabingButton(
          key: const Key('multiKolabAddRoleCta'),
          label: l10n.multiKolabRoleFormAddCta,
          variant: KolabingButtonVariant.secondary,
          onPressed: () =>
              context.push(multiKolabOrganizerRoleLocation(widget.eventId)),
        ),
    ];
  }

  List<Widget> _applicants(
    MultiKolabEvent event,
    MultiKolabDashboard? dashboard,
    AppLocalizations l10n,
  ) {
    if (event.roles.isEmpty) {
      return [
        _EmptyBlock(
          key: const Key('multiKolabApplicantsTabEmpty'),
          title: l10n.multiKolabApplicantsEmptyTitle,
          body: l10n.multiKolabApplicantsEmptyBody,
        ),
      ];
    }

    // The API has no cross-role application listing, so the applicants tab
    // IS the role list — each row opens that role's applications.
    return [
      for (final role in event.roles)
        ListTile(
          key: Key('multiKolabApplicantsRoleRow_${role.id}'),
          contentPadding: EdgeInsets.zero,
          title: Text(role.title),
          subtitle: Text(
            l10n.multiKolabRolePartnersConfirmed(
              role.positionsFilled,
              role.positionsNeeded,
            ),
          ),
          trailing: _PendingBadge(
            count:
                dashboard?.roles
                    .where((r) => r.roleId == role.id)
                    .firstOrNull
                    ?.applicationCounts
                    .pending ??
                0,
          ),
          onTap: () => context.push(
            multiKolabOrganizerRoleApplicationsLocation(
              eventId: widget.eventId,
              roleId: role.id,
            ),
          ),
        ),
    ];
  }

  // --- lifecycle -----------------------------------------------------------

  /// Only transitions the backend actually permits from the current status
  /// (contract §5) are rendered. Everything else is absent, not disabled,
  /// so the organizer is never offered an action that can only 422.
  List<Widget> _lifecycleActions(MultiKolabEvent event, AppLocalizations l10n) {
    final actionState = ref.watch(multiKolabOrganizerActionsProvider);
    final widgets = <Widget>[];

    void add(Widget w) {
      widgets
        ..add(w)
        ..add(const SizedBox(height: KolabingSpacing.xs));
    }

    switch (event.status) {
      case MultiKolabEventStatus.draft:
        add(
          KolabingButton(
            key: const Key('multiKolabManageEditCta'),
            label: l10n.multiKolabManageEditCta,
            variant: KolabingButtonVariant.secondary,
            onPressed: () =>
                context.push(multiKolabOrganizerEventEditLocation(event.id)),
          ),
        );
        add(
          KolabingButton(
            key: const Key('multiKolabManageReviewCta'),
            label: l10n.multiKolabManageReviewCta,
            onPressed: () =>
                context.push(multiKolabOrganizerEventReviewLocation(event.id)),
          ),
        );
      case MultiKolabEventStatus.recruiting:
        add(
          KolabingButton(
            key: const Key('multiKolabManageEditCta'),
            label: l10n.multiKolabManageEditCta,
            variant: KolabingButtonVariant.secondary,
            onPressed: () =>
                context.push(multiKolabOrganizerEventEditLocation(event.id)),
          ),
        );
        add(
          KolabingButton(
            key: const Key('multiKolabConfirmEventCta'),
            label: l10n.multiKolabConfirmEventCta,
            isLoading: actionState.isBusy('confirm', event.id),
            isDisabled: actionState.isBusy('confirm', event.id),
            onPressed: _confirmEvent,
          ),
        );
      case MultiKolabEventStatus.confirmed:
        add(
          KolabingButton(
            key: const Key('multiKolabCompleteEventCta'),
            label: l10n.multiKolabCompleteEventCta,
            isLoading: actionState.isBusy('complete', event.id),
            isDisabled: actionState.isBusy('complete', event.id),
            onPressed: _completeEvent,
          ),
        );
      case MultiKolabEventStatus.completed:
      case MultiKolabEventStatus.cancelled:
      case MultiKolabEventStatus.expired:
        // Terminal — read-only.
        return const [];
    }

    add(
      KolabingButton(
        key: const Key('multiKolabCancelEventCta'),
        label: l10n.multiKolabCancelEventCta,
        variant: KolabingButtonVariant.secondary,
        isLoading: actionState.isBusy('cancel', event.id),
        isDisabled: actionState.isBusy('cancel', event.id),
        onPressed: _cancelEvent,
      ),
    );

    return widgets;
  }

  ({int pending, int shortlisted, int accepted, int declined}) _aggregate(
    MultiKolabDashboard? dashboard,
  ) {
    var pending = 0, shortlisted = 0, accepted = 0, declined = 0;
    for (final role in dashboard?.roles ?? const <MultiKolabDashboardRole>[]) {
      pending += role.applicationCounts.pending;
      shortlisted += role.applicationCounts.shortlisted;
      accepted += role.applicationCounts.accepted;
      declined += role.applicationCounts.declined;
    }
    return (
      pending: pending,
      shortlisted: shortlisted,
      accepted: accepted,
      declined: declined,
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.counts,
    required this.busy,
    required this.editable,
    required this.onEdit,
    required this.onToggle,
    required this.onApplicants,
  });

  final MultiKolabRole role;
  final MultiKolabApplicationCounts? counts;
  final bool busy;
  final bool editable;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onApplicants;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Container(
      key: Key('multiKolabRoleCard_${role.id}'),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: KolabingRadius.borderRadiusCard,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role.title,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
              MultiKolabStatusChip.role(role.status, l10n),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            role.eligibleAccountType.label(l10n),
            style: KolabingTextStyles.bodySmall.copyWith(color: colors.inkBody),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Semantics(
            label: l10n.multiKolabRolePartnersConfirmed(
              role.positionsFilled,
              role.positionsNeeded,
            ),
            excludeSemantics: true,
            child: Text(
              key: Key('multiKolabRoleFill_${role.id}'),
              l10n.multiKolabRolePartnersConfirmed(
                role.positionsFilled,
                role.positionsNeeded,
              ),
              style: KolabingTextStyles.bodySmall.copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Wrap(
            spacing: KolabingSpacing.xs,
            children: [
              TextButton(
                key: Key('multiKolabRoleApplicants_${role.id}'),
                onPressed: onApplicants,
                child: Text(
                  counts == null
                      ? l10n.multiKolabManageTabApplicants
                      : l10n.multiKolabApplicantsSectionLabel(
                          l10n.multiKolabManageTabApplicants,
                          counts!.pending,
                        ),
                ),
              ),
              if (editable)
                TextButton(
                  key: Key('multiKolabRoleEdit_${role.id}'),
                  onPressed: onEdit,
                  child: Text(l10n.multiKolabRoleFormEditTitle),
                ),
              if (editable)
                TextButton(
                  key: Key('multiKolabRoleToggle_${role.id}'),
                  onPressed: busy ? null : onToggle,
                  child: Text(
                    role.status == MultiKolabRoleStatus.closed
                        ? l10n.multiKolabRoleReopenCta
                        : l10n.multiKolabRoleCloseCta,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Every Kolab created by an acceptance on this event, with a hand-off into
/// the existing Kolab detail screen. This feature never renders its own
/// collaboration UI.
class _ChildKolabsSection extends ConsumerWidget {
  const _ChildKolabsSection({required this.eventId, required this.roles});

  final String eventId;
  final List<MultiKolabRole> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    // Accepted applications carry the child Kolab id; they are read from
    // each role's application list, which is already cached for any role
    // the organizer has opened.
    final accepted = <String>[];
    for (final role in roles) {
      final applications = ref
          .watch(multiKolabRoleApplicationsProvider(role.id))
          .value;
      for (final a in applications ?? const <MultiKolabRoleApplication>[]) {
        if (a.isAccepted && (a.kolabId?.isNotEmpty ?? false)) {
          accepted.add(a.kolabId!);
        }
      }
    }

    return Column(
      key: const Key('multiKolabChildKolabsSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.multiKolabManageChildKolabsTitle.toUpperCase(),
          style: KolabingTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.inkBody,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        if (accepted.isEmpty)
          Text(
            l10n.multiKolabManageChildKolabsEmpty,
            style: KolabingTextStyles.bodySmall.copyWith(color: colors.inkBody),
          )
        else
          for (final kolabId in accepted)
            TextButton.icon(
              key: Key('multiKolabChildKolabLink_$kolabId'),
              onPressed: () => context.push('/opportunity/$kolabId'),
              icon: const Icon(LucideIcons.link2, size: 14),
              label: Text(l10n.multiKolabOpenKolabCta),
            ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.tone,
  });

  final String label;
  final int count;
  final MultiKolabStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return MultiKolabStatusChip(label: '$label · $count', tone: tone);
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const Icon(LucideIcons.chevronRight, size: 16);
    return MultiKolabStatusChip(
      label: '$count',
      tone: MultiKolabStatusTone.pending,
      semanticPrefix: AppLocalizations.of(
        context,
      ).multiKolabApplicationStatusPending,
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        const SizedBox(height: KolabingSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.sectionHeader.copyWith(color: colors.ink),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyMedium.copyWith(color: colors.inkBody),
        ),
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('multiKolabCancelEventDialog'),
      title: Text(l10n.multiKolabCancelEventTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.multiKolabCancelEventBody),
          const SizedBox(height: KolabingSpacing.sm),
          KolabingInput(
            key: const Key('multiKolabCancelReasonField'),
            controller: _controller,
            label: l10n.multiKolabCancelEventReasonLabel,
            errorText: _error,
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.multiKolabDismissCta),
        ),
        TextButton(
          key: const Key('multiKolabCancelEventConfirmCta'),
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) {
              setState(() => _error = l10n.multiKolabCancelEventReasonRequired);
              return;
            }
            Navigator.of(context).pop(reason);
          },
          child: Text(l10n.multiKolabCancelEventCta),
        ),
      ],
    );
  }
}
