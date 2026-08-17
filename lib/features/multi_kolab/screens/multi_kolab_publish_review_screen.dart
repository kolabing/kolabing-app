import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_top_bar.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event.dart';
import '../providers/multi_kolab_organizer_actions.dart';
import '../providers/multi_kolab_providers.dart';
import '../widgets/multi_kolab_entitlement_gate.dart';
import '../widgets/multi_kolab_error_copy.dart';
import '../widgets/multi_kolab_labels.dart';

/// Compact pre-publish review.
///
/// The "Still needed" list is **advisory**: the backend's publish validation
/// is the final authority (contract §5), so a client-side check never
/// silently blocks a publish the server would have accepted. The only thing
/// the client refuses outright is publishing with zero roles, because that
/// is guaranteed to fail and the message would be identical.
class MultiKolabPublishReviewScreen extends ConsumerStatefulWidget {
  const MultiKolabPublishReviewScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<MultiKolabPublishReviewScreen> createState() =>
      _MultiKolabPublishReviewScreenState();
}

class _MultiKolabPublishReviewScreenState
    extends ConsumerState<MultiKolabPublishReviewScreen> {
  final _scrollController = ScrollController();
  final _eventSectionKey = GlobalKey();
  final _rolesSectionKey = GlobalKey();

  /// Field-keyed publish errors returned by the backend, so each one can be
  /// rendered against the section it belongs to instead of in one blob.
  Map<String, List<String>> _publishErrors = const {};
  bool _entitlementBlocked = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _stillNeeded(MultiKolabEvent event, AppLocalizations l10n) {
    return [
      if (event.roles.isEmpty) l10n.multiKolabReviewMissingRoles,
      if (event.eventDate == null &&
          event.dateRangeStart == null &&
          event.dateRangeEnd == null)
        l10n.multiKolabReviewMissingDate,
      if (event.city == null || event.city!.trim().isEmpty)
        l10n.multiKolabReviewMissingCity,
    ];
  }

  void _scrollToFirstFailingSection() {
    final target = _publishErrors.keys.any((k) => k == 'roles')
        ? _rolesSectionKey
        : _eventSectionKey;
    final targetContext = target.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      alignment: 0.05,
    );
  }

  Future<void> _publish(MultiKolabEvent event) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _publishErrors = const {};
      _entitlementBlocked = false;
    });

    final published = await ref
        .read(multiKolabOrganizerActionsProvider.notifier)
        .publish(event.id);

    if (!mounted) return;

    if (published == null) {
      final code = ref.read(multiKolabOrganizerActionsProvider).lastErrorCode;
      if (code == 'event_creator_required') {
        // The draft is untouched; only the gate copy is shown inline.
        setState(() => _entitlementBlocked = true);
        return;
      }
      setState(() {
        _publishErrors = {
          'event': [multiKolabErrorCopy(code, l10n)],
        };
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToFirstFailingSection(),
      );
      return;
    }

    await _showSuccess(l10n);
    if (mounted) context.pop();
  }

  Future<void> _showSuccess(AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('multiKolabPublishSuccessDialog'),
        title: Text(l10n.multiKolabPublishSuccessTitle),
        content: Text(l10n.multiKolabPublishSuccessBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.multiKolabPublishSuccessCta),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final asyncEvent = ref.watch(multiKolabEventDetailProvider(widget.eventId));
    final actionState = ref.watch(multiKolabOrganizerActionsProvider);
    final publishing = actionState.isBusy('publish', widget.eventId);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: KolabingTopBar(title: l10n.multiKolabReviewTitle),
      body: SafeArea(
        child: asyncEvent.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              Center(child: Text(l10n.multiKolabExploreErrorBody)),
          data: (event) {
            final missing = _stillNeeded(event, l10n);
            final canPublish = event.roles.isNotEmpty && !publishing;

            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(KolabingSpacing.md),
              children: [
                if (_entitlementBlocked)
                  const Padding(
                    padding: EdgeInsets.only(bottom: KolabingSpacing.md),
                    child: MultiKolabEntitlementGate(),
                  ),
                if (missing.isNotEmpty)
                  _MissingBlock(
                    key: const Key('multiKolabReviewMissingBlock'),
                    items: missing,
                  ),
                const SizedBox(height: KolabingSpacing.md),
                _Section(
                  sectionKey: _eventSectionKey,
                  title: l10n.multiKolabReviewEventSection,
                  errors: _publishErrors.entries
                      .where((e) => e.key != 'roles')
                      .expand((e) => e.value)
                      .toList(growable: false),
                  child: _EventSummary(event: event),
                ),
                const SizedBox(height: KolabingSpacing.md),
                _Section(
                  sectionKey: _rolesSectionKey,
                  title: l10n.multiKolabReviewRolesSection,
                  errors: _publishErrors['roles'] ?? const [],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final role in event.roles)
                        Padding(
                          key: Key('multiKolabReviewRole_${role.id}'),
                          padding: const EdgeInsets.only(
                            bottom: KolabingSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      role.title,
                                      style: KolabingTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.ink,
                                          ),
                                    ),
                                  ),
                                  MultiKolabStatusChip.role(role.status, l10n),
                                ],
                              ),
                              Text(
                                '${role.eligibleAccountType.label(l10n)} · '
                                '${l10n.multiKolabRolePartnersConfirmed(role.positionsFilled, role.positionsNeeded)}',
                                style: KolabingTextStyles.bodySmall.copyWith(
                                  color: colors.inkBody,
                                ),
                              ),
                              if (role.compensationType != null)
                                Text(
                                  role.compensationType!.label(l10n),
                                  style: KolabingTextStyles.bodySmall.copyWith(
                                    color: colors.inkBody,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: KolabingSpacing.lg),
                KolabingButton(
                  key: const Key('multiKolabPublishCta'),
                  label: l10n.multiKolabPublishCta,
                  isLoading: publishing,
                  isDisabled: !canPublish,
                  onPressed: canPublish ? () => _publish(event) : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EventSummary extends StatelessWidget {
  const _EventSummary({required this.event});

  final MultiKolabEvent event;

  String? _dateLabel() {
    if (event.dateMode == MultiKolabDateMode.range) {
      final start = event.dateRangeStart;
      final end = event.dateRangeEnd;
      if (start == null && end == null) return null;
      final f = DateFormat.yMMMd();
      return '${start == null ? '?' : f.format(start)} – '
          '${end == null ? '?' : f.format(end)}';
    }
    return event.eventDate == null
        ? null
        : DateFormat.yMMMd().format(event.eventDate!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final date = _dateLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: KolabingTextStyles.titleMedium.copyWith(color: colors.ink),
        ),
        if (event.description != null && event.description!.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            event.description!,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: colors.inkBody,
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.xs),
        Wrap(
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xxs,
          children: [
            if (event.city != null && event.city!.isNotEmpty)
              _Pill(icon: LucideIcons.mapPin, text: event.city!),
            if (date != null) _Pill(icon: LucideIcons.calendar, text: date),
            _Pill(
              icon: event.venueNeeded ? LucideIcons.search : LucideIcons.check,
              text: event.venueNeeded
                  ? l10n.multiKolabReviewVenueNeeded
                  : l10n.multiKolabReviewVenueSecured,
            ),
            _Pill(
              icon: LucideIcons.users,
              text: event.eligibleAccountType.label(l10n),
            ),
            if (event.rsvpUrl != null && event.rsvpUrl!.isNotEmpty)
              _Pill(icon: LucideIcons.link, text: event.rsvpUrl!),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.inkBody),
          const SizedBox(width: KolabingSpacing.xxs),
          Flexible(
            child: Text(
              text,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.inkBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingBlock extends StatelessWidget {
  const _MissingBlock({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: colors.pendingBg,
        borderRadius: KolabingRadius.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.multiKolabReviewMissingTitle,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.pendingText,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          for (final item in items)
            Text(
              '• $item',
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.pendingText,
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.sectionKey,
    required this.title,
    required this.child,
    required this.errors,
  });

  final GlobalKey sectionKey;
  final String title;
  final Widget child;
  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: KolabingRadius.borderRadiusCard,
        border: Border.all(
          color: errors.isEmpty ? colors.hairline : colors.errorText,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: KolabingTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.inkBody,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          child,
          for (final error in errors) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.errorText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
