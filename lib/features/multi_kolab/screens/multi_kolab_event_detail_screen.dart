import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../auth/models/auth_response.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import '../providers/multi_kolab_providers.dart';
import '../providers/multi_kolab_repository_provider.dart';
import '../repositories/api_multi_kolab_repository.dart';
import '../widgets/multi_kolab_application_form.dart';
import '../widgets/multi_kolab_labels.dart';

/// Event detail + applicant flow: view roles, apply to an open + eligible
/// one via a short pitch form, then RSVP (HTTPS-only) if the organizer set a
/// link. On acceptance elsewhere, the existing child-Kolab/Collaboration
/// detail and chat screens are what the applicant lands in — this screen
/// never re-implements them.
class MultiKolabEventDetailScreen extends ConsumerStatefulWidget {
  const MultiKolabEventDetailScreen({
    required this.eventId,
    super.key,
    this.focusedRoleId,
  });

  final String eventId;

  /// The role the viewer tapped in Explore. It is highlighted and scrolled
  /// to on first load; the parent event's context and its OTHER roles stay
  /// rendered below so the viewer sees the whole event, not just one role.
  final String? focusedRoleId;

  @override
  ConsumerState<MultiKolabEventDetailScreen> createState() =>
      _MultiKolabEventDetailScreenState();
}

class _MultiKolabEventDetailScreenState
    extends ConsumerState<MultiKolabEventDetailScreen> {
  bool _hasScrolledToFocusedRole = false;

  /// Stable key for the focused role card, so the first build after the
  /// event loads can bring it into view.
  final GlobalKey _focusedRoleKey = GlobalKey();

  String get eventId => widget.eventId;
  String? get focusedRoleId => widget.focusedRoleId;

  void _scrollToFocusedRoleOnce() {
    if (_hasScrolledToFocusedRole || focusedRoleId == null) return;
    _hasScrolledToFocusedRole = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusedRoleKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
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
          _scrollToFocusedRoleOnce();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(multiKolabEventDetailProvider(eventId));
              await ref.read(multiKolabEventDetailProvider(eventId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              children: [
                MultiKolabStatusChip.event(event.status, l10n),
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
                ...event.roles.map((role) {
                  final isFocused =
                      focusedRoleId != null && role.id == focusedRoleId;
                  return Padding(
                    key: Key('multi-kolab-role-card-${role.id}'),
                    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
                    child: _RoleCard(
                      key: isFocused ? _focusedRoleKey : null,
                      role: role,
                      eventId: eventId,
                      // Per ROLE, not per event: applying to the run-club role
                      // must not remove Apply from the coffee role.
                      hasViewerApplied:
                          event.viewerApplication?.multiKolabRoleId == role.id,
                      isFocused: isFocused,
                    ),
                  );
                }),
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
                application.status.label(l10n),
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
    super.key,
    this.isFocused = false,
  });

  final MultiKolabRole role;
  final String eventId;
  final bool hasViewerApplied;

  /// The role the viewer arrived from in Explore — emphasised, but the
  /// event's other roles remain fully visible.
  final bool isFocused;

  /// "2 spots open · Businesses and communities" while there is room; once a
  /// role is full the spot count says nothing useful (the status badge
  /// already reads FILLED), so only the eligibility remains.
  String _metaLine(AppLocalizations l10n) {
    final eligibility = role.eligibleAccountType.label(l10n);
    final remaining = role.isOpen ? role.positionsRemaining : 0;
    if (remaining <= 0) return eligibility;
    return '${l10n.multiKolabRoleSpotsOpen(remaining)} · $eligibility';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    // A filled/closed role, or one the viewer already applied to, can never
    // be applied to again.
    final canApply =
        role.isOpen && role.positionsRemaining > 0 && !hasViewerApplied;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: isFocused ? colors.primary : colors.hairline,
          width: isFocused ? 2 : 1,
        ),
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
              MultiKolabStatusChip.role(role.status, l10n),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xxxs),
          // Hierarchy, in order of what an applicant actually decides on:
          // (1) is there room for me and am I the right kind of account,
          // (2) how much this role matters to the organizer. The raw
          // "N open · M filled" split and the wire value in "Open to:
          // community" are both gone — remaining availability answers the
          // first question on its own, and the eligibility copy is the same
          // product wording the role editor offers.
          Semantics(
            key: Key('multi-kolab-role-meta-${role.id}'),
            label: _metaLine(l10n),
            excludeSemantics: true,
            child: Text(
              _metaLine(l10n),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxxs),
          Text(
            role.required_
                ? l10n.multiKolabRoleRequiredLabel
                : l10n.multiKolabRoleOptionalLabel,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.muted),
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
              key: Key('multi-kolab-role-apply-${role.id}'),
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
