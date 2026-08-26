import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_top_bar.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import '../providers/multi_kolab_organizer_actions.dart';
import '../providers/multi_kolab_providers.dart';
import '../widgets/multi_kolab_error_copy.dart';
import '../widgets/multi_kolab_labels.dart';

/// Organizer review of one role's applications.
///
/// Grouping is by role because the API has no cross-role application
/// listing (contract §7) — that is the data model, not a UI decision.
///
/// What is shown per application is exactly what
/// `MultiKolabRoleApplicationResource` returns: applicant profile id +
/// account type, pitch, availability, status, applied date, and (once
/// accepted) the child Kolab id. The resource deliberately does **not**
/// nest the applicant's profile, so richer profile/social-proof context is
/// reached by deep-linking into the existing public profile screen rather
/// than by inventing fields. `withdrawal_reason` is never serialized by the
/// backend (contract §12) and is therefore never displayed.
class MultiKolabApplicantReviewScreen extends ConsumerWidget {
  const MultiKolabApplicantReviewScreen({
    required this.eventId,
    required this.roleId,
    super.key,
  });

  /// The parent event. Carried in the route so this screen can read the
  /// already-cached event detail for the role's capacity and value
  /// exchange (needed by the acceptance sheet) instead of issuing another
  /// request per card.
  final String eventId;
  final String roleId;

  static const _order = [
    MultiKolabRoleApplicationStatus.pending,
    MultiKolabRoleApplicationStatus.shortlisted,
    MultiKolabRoleApplicationStatus.accepted,
    MultiKolabRoleApplicationStatus.declined,
    MultiKolabRoleApplicationStatus.withdrawn,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final asyncApplications = ref.watch(
      multiKolabRoleApplicationsProvider(roleId),
    );
    // Watched (not just read) so the role's capacity re-renders after an
    // acceptance invalidates the event detail.
    ref.watch(multiKolabEventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: KolabingTopBar(title: l10n.multiKolabApplicantsTitle),
      body: SafeArea(
        child: asyncApplications.when(
          loading: () => const Center(
            key: Key('multiKolabApplicantsLoading'),
            child: CircularProgressIndicator(),
          ),
          error: (_, _) => Center(
            key: const Key('multiKolabApplicantsError'),
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
                      multiKolabRoleApplicationsProvider(roleId),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (applications) {
            if (applications.isEmpty) {
              return _Empty(key: const Key('multiKolabApplicantsEmpty'));
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(multiKolabRoleApplicationsProvider(roleId)),
              child: ListView(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                children: [
                  for (final status in _order)
                    ..._sectionFor(context, ref, status, applications),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sectionFor(
    BuildContext context,
    WidgetRef ref,
    MultiKolabRoleApplicationStatus status,
    List<MultiKolabRoleApplication> all,
  ) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final rows = all.where((a) => a.status == status).toList(growable: false);
    // Declined and withdrawn sections stay visible when populated rather
    // than silently removing rows the organizer acted on.
    if (rows.isEmpty) return const [];

    return [
      Padding(
        key: Key('multiKolabApplicantsSection_${status.toApiValue()}'),
        padding: const EdgeInsets.only(
          top: KolabingSpacing.sm,
          bottom: KolabingSpacing.xs,
        ),
        child: Text(
          l10n.multiKolabApplicantsSectionLabel(
            status.label(l10n),
            rows.length,
          ),
          style: KolabingTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.inkBody,
          ),
        ),
      ),
      for (final application in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
          child: _ApplicationCard(
            eventId: eventId,
            roleId: roleId,
            application: application,
          ),
        ),
    ];
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 36, color: colors.muted),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.multiKolabApplicantsEmptyTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.sectionHeader.copyWith(
                color: colors.ink,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.multiKolabApplicantsEmptyBody,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: colors.inkBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({
    required this.eventId,
    required this.roleId,
    required this.application,
  });

  final String eventId;
  final String roleId;
  final MultiKolabRoleApplication application;

  /// The role this application belongs to, read from the already-watched
  /// event detail. Null only while that detail is still loading, in which
  /// case the acceptance sheet falls back to generic capacity copy rather
  /// than blocking the organizer.
  MultiKolabRole? _roleFrom(WidgetRef ref) {
    final event = ref.read(multiKolabEventDetailProvider(eventId)).value;
    if (event == null) return null;
    for (final role in event.roles) {
      if (role.id == roleId) return role;
    }
    return null;
  }

  Future<void> _shortlist(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .shortlist(roleId, application.id);
    if (!context.mounted) return;
    if (result == null) _showError(context, ref, l10n);
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('multiKolabDeclineDialog'),
        title: Text(l10n.multiKolabDeclineConfirmTitle),
        content: Text(
          l10n.multiKolabDeclineConfirmBody(
            _roleFrom(ref)?.title ?? l10n.multiKolabApplicantsTitle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.multiKolabDismissCta),
          ),
          TextButton(
            key: const Key('multiKolabDeclineConfirmCta'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.multiKolabDeclineCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .decline(roleId, application.id);
    if (!context.mounted) return;
    if (result == null) _showError(context, ref, l10n);
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final role = _roleFrom(ref);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _AcceptConfirmSheet(application: application, role: role),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .accept(
          eventId: eventId,
          roleId: roleId,
          applicationId: application.id,
        );

    if (!context.mounted) return;

    if (result == null) {
      _showError(context, ref, l10n);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('multiKolabAcceptSuccessDialog'),
        title: Text(l10n.multiKolabAcceptSuccessTitle),
        content: Text(l10n.multiKolabAcceptSuccessBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.multiKolabDismissCta),
          ),
          TextButton(
            key: const Key('multiKolabAcceptSuccessOpenCta'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Hands off to the EXISTING collaboration / Kolab screens —
              // this feature never builds a second collaboration system.
              final collaborationId = result.collaborationId;
              if (collaborationId != null && collaborationId.isNotEmpty) {
                context.push('/collaboration/$collaborationId');
              } else if (result.kolabId.isNotEmpty) {
                context.push('/opportunity/${result.kolabId}');
              }
            },
            child: Text(
              result.collaborationId != null
                  ? l10n.multiKolabOpenCollaborationCta
                  : l10n.multiKolabOpenKolabCta,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final code = ref.read(multiKolabOrganizerActionsProvider).lastErrorCode;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(multiKolabErrorCopy(code, l10n))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final actionState = ref.watch(multiKolabOrganizerActionsProvider);
    final busy =
        actionState.isBusy('shortlist', application.id) ||
        actionState.isBusy('decline', application.id) ||
        actionState.isBusy('accept', application.id);

    final status = application.status;
    final canShortlist =
        status == MultiKolabRoleApplicationStatus.pending && !busy;
    final canDecline =
        (status == MultiKolabRoleApplicationStatus.pending ||
            status == MultiKolabRoleApplicationStatus.shortlisted) &&
        !busy;
    final canAccept = canDecline;

    return Container(
      key: Key('multiKolabApplication_${application.id}'),
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
                  application.applicantProfileType == 'business'
                      ? l10n.multiKolabApplicantBusinessLabel
                      : l10n.multiKolabApplicantCommunityLabel,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
              MultiKolabStatusChip.application(status, l10n),
            ],
          ),
          if (application.createdAt != null) ...[
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              DateFormat.yMMMd().format(application.createdAt!),
              style: KolabingTextStyles.bodySmall.copyWith(color: colors.muted),
            ),
          ],
          if (application.pitch != null && application.pitch!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _Labelled(
              label: l10n.multiKolabApplicantPitchLabel,
              value: application.pitch!,
            ),
          ],
          if (application.availability != null &&
              application.availability!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _Labelled(
              label: l10n.multiKolabApplicantAvailabilityLabel,
              value: application.availability!,
            ),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xxs,
            children: [
              TextButton.icon(
                key: Key('multiKolabViewProfile_${application.id}'),
                onPressed: () => context.push(
                  KolabingRoutes.publicProfile.replaceFirst(
                    ':id',
                    application.applicantProfileId,
                  ),
                ),
                icon: const Icon(LucideIcons.user, size: 14),
                label: Text(l10n.multiKolabApplicantViewProfileCta),
              ),
              if (canShortlist)
                TextButton(
                  key: Key('multiKolabShortlist_${application.id}'),
                  onPressed: () => _shortlist(context, ref),
                  child: Text(l10n.multiKolabShortlistCta),
                ),
              if (canDecline)
                TextButton(
                  key: Key('multiKolabDecline_${application.id}'),
                  onPressed: () => _decline(context, ref),
                  child: Text(l10n.multiKolabDeclineCta),
                ),
              if (canAccept)
                KolabingButton(
                  key: Key('multiKolabAccept_${application.id}'),
                  label: l10n.multiKolabAcceptCta,
                  size: KolabingButtonSize.small,
                  width: 120,
                  onPressed: () => _accept(context, ref),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(KolabingSpacing.xs),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          if (application.isAccepted &&
              application.kolabId != null &&
              application.kolabId!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            TextButton.icon(
              key: Key('multiKolabChildKolab_${application.id}'),
              onPressed: () =>
                  context.push('/opportunity/${application.kolabId}'),
              icon: const Icon(LucideIcons.link2, size: 14),
              label: Text(l10n.multiKolabApplicantChildKolabLabel),
            ),
          ],
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: KolabingTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.muted,
          ),
        ),
        Text(
          value,
          style: KolabingTextStyles.bodySmall.copyWith(color: colors.ink),
        ),
      ],
    );
  }
}

/// Everything the organizer needs before an irreversible acceptance:
/// who, which role, the capacity left afterwards, the agreed exchange, and
/// an explicit statement that a Kolab + collaboration will be created.
class _AcceptConfirmSheet extends StatelessWidget {
  const _AcceptConfirmSheet({required this.application, required this.role});

  final MultiKolabRoleApplication application;
  final MultiKolabRole? role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final needed = role?.positionsNeeded ?? 1;
    final remaining = ((role?.positionsRemaining ?? 1) - 1).clamp(0, needed);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          key: const Key('multiKolabAcceptConfirmSheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.multiKolabAcceptConfirmTitle,
              style: KolabingTextStyles.sectionHeader.copyWith(
                color: colors.ink,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              application.applicantProfileType == 'business'
                  ? l10n.multiKolabApplicantBusinessLabel
                  : l10n.multiKolabApplicantCommunityLabel,
              style: KolabingTextStyles.bodyMedium.copyWith(color: colors.ink),
            ),
            if (role != null) ...[
              Text(
                l10n.multiKolabAcceptConfirmRole(role!.title),
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: colors.inkBody,
                ),
              ),
              Text(
                l10n.multiKolabAcceptConfirmCapacity(remaining, needed),
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: colors.inkBody,
                ),
              ),
              if (role!.need != null || role!.receive != null) ...[
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  l10n.multiKolabAcceptConfirmExchange.toUpperCase(),
                  style: KolabingTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.muted,
                  ),
                ),
                if (role!.need != null)
                  Text(
                    role!.need!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: colors.ink,
                    ),
                  ),
                if (role!.receive != null)
                  Text(
                    role!.receive!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: colors.ink,
                    ),
                  ),
                if (role!.compensationType != null)
                  Text(
                    role!.compensationType!.label(l10n),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: colors.inkBody,
                    ),
                  ),
              ],
            ],
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.multiKolabAcceptConfirmCreatesKolab,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.inkBody,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            KolabingButton(
              key: const Key('multiKolabAcceptConfirmCta'),
              label: l10n.multiKolabAcceptCta,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            KolabingButton(
              label: l10n.multiKolabDismissCta,
              variant: KolabingButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
