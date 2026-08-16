import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../../widgets/kolabing_button.dart';
import '../../auth/models/auth_response.dart';
import '../models/multi_kolab_creator_summary.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import '../providers/multi_kolab_providers.dart';
import '../providers/multi_kolab_repository_provider.dart';
import '../repositories/api_multi_kolab_repository.dart';
import '../widgets/multi_kolab_application_form.dart';
import '../widgets/multi_kolab_role_progress.dart';

/// Event detail + applicant flow: view roles, apply to an open + eligible
/// one via a short pitch form, then RSVP (HTTPS-only) if the organizer set a
/// link. On acceptance elsewhere, the existing child-Kolab/Collaboration
/// detail and chat screens are what the applicant lands in — this screen
/// never re-implements them.
class MultiKolabEventDetailScreen extends ConsumerWidget {
  const MultiKolabEventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final asyncEvent = ref.watch(multiKolabEventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.multiKolabEventDetailTitle)),
      body: asyncEvent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: l10n.multiKolabExploreErrorBody,
          onRetry: () => ref.invalidate(multiKolabEventDetailProvider(eventId)),
        ),
        data: (event) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(multiKolabEventDetailProvider(eventId));
              await ref.read(multiKolabEventDetailProvider(eventId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              children: [
                KolabStatusBadge(status: event.status.toApiValue()),
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  event.title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: colors.onSurface),
                ),
                if (event.eventDate != null) ...[
                  const SizedBox(height: KolabingSpacing.xxxs),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: KolabingSpacing.xxxs),
                      Text(
                        DateFormat.yMMMd().format(event.eventDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.sm),
                  Text(
                    event.description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                  ),
                ],
                if (event.rsvpUrl != null &&
                    event.rsvpUrl!.startsWith('https://')) ...[
                  const SizedBox(height: KolabingSpacing.md),
                  KolabingButton(
                    label: l10n.multiKolabRsvpButtonLabel,
                    variant: KolabingButtonVariant.secondary,
                    onPressed: () => launchUrl(Uri.parse(event.rsvpUrl!)),
                  ),
                ],
                const SizedBox(height: KolabingSpacing.lg),
                Text(
                  l10n.multiKolabEventDetailRolesHeading,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                if (event.viewerApplication != null)
                  _ViewerApplicationBanner(
                    application: event.viewerApplication!,
                  ),
                ...event.roles.map(
                  (role) => Padding(
                    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
                    child: _RoleCard(
                      role: role,
                      eventId: eventId,
                      hasViewerApplied: event.hasViewerApplied,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ViewerApplicationBanner extends StatelessWidget {
  const _ViewerApplicationBanner({required this.application});

  final MultiKolabRoleApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              l10n.multiKolabAlreadyAppliedLabel(
                application.status.toApiValue(),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  const _RoleCard({
    required this.role,
    required this.eventId,
    required this.hasViewerApplied,
  });

  final MultiKolabRole role;
  final String eventId;
  final bool hasViewerApplied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final canApply = role.isOpen && !hasViewerApplied;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: colors.onSurface),
                ),
              ),
              KolabStatusBadge(status: role.status.toApiValue()),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xxxs),
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xxxs,
            children: [
              MultiKolabRoleProgress(
                counts: MultiKolabRoleCounts(
                  total: role.positionsNeeded,
                  open: role.positionsRemaining,
                  filled: role.positionsFilled,
                ),
              ),
              Text(
                role.required_
                    ? l10n.multiKolabRoleRequiredLabel
                    : l10n.multiKolabRoleOptionalLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                l10n.multiKolabRoleEligibilityLabel(
                  role.eligibleAccountType.toApiValue(),
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (role.need != null && role.need!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              role.need!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurface),
            ),
          ],
          if (canApply) ...[
            const SizedBox(height: KolabingSpacing.sm),
            KolabingButton(
              label: l10n.multiKolabEventDetailApplyButton,
              size: KolabingButtonSize.compact,
              onPressed: () => _openApplySheet(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _openApplySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: KolabingSpacing.md,
          right: KolabingSpacing.md,
          top: KolabingSpacing.md,
          bottom:
              MediaQuery.of(sheetContext).viewInsets.bottom +
              KolabingSpacing.md,
        ),
        child: _ApplySheetBody(role: role, eventId: eventId),
      ),
    );
  }
}

class _ApplySheetBody extends ConsumerStatefulWidget {
  const _ApplySheetBody({required this.role, required this.eventId});

  final MultiKolabRole role;
  final String eventId;

  @override
  ConsumerState<_ApplySheetBody> createState() => _ApplySheetBodyState();
}

class _ApplySheetBodyState extends ConsumerState<_ApplySheetBody> {
  bool _isSubmitting = false;

  Future<void> _submit(CreateMultiKolabApplicationInput input) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);
    try {
      await ref.read(multiKolabRepositoryProvider).apply(widget.role.id, input);
      ref.invalidate(multiKolabEventDetailProvider(widget.eventId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.multiKolabApplyFormSuccess)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final code = e.error.stableCode;
      final message = switch (code) {
        'role_ineligible' => l10n.multiKolabApplyFormErrorIneligible,
        'event_not_recruiting' =>
          l10n.multiKolabApplyFormErrorEventNotRecruiting,
        'role_not_open' => l10n.multiKolabApplyFormErrorRoleNotOpen,
        'duplicate_application' => l10n.multiKolabApplyFormErrorDuplicate,
        _ => l10n.multiKolabApplyFormErrorGeneric,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.multiKolabApplyFormTitle(widget.role.title),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          MultiKolabApplicationForm(
            isSubmitting: _isSubmitting,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, color: context.colors.error),
            const SizedBox(height: KolabingSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: KolabingSpacing.sm),
            KolabingButton(label: l10n.commonRetry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
