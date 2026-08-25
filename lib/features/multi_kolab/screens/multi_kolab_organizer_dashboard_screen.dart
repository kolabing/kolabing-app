import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_segmented_control.dart';
import '../../../widgets/kolabing_top_bar.dart';
import '../../../widgets/navigation/kolabing_fab.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event_summary.dart';
import '../providers/multi_kolab_providers.dart';
import '../widgets/multi_kolab_entitlement_gate.dart';
import '../widgets/multi_kolab_organizer_event_card.dart';

/// Client-side grouping of the organizer's events.
///
/// `GET /multi-kolab-events/me` takes no `status` query parameter, so
/// filtering server-side would mean inventing an API. The endpoint already
/// returns the organizer's own events (a small, bounded set), so the filter
/// is applied over the fetched list.
enum MultiKolabOrganizerFilter {
  all,
  drafts,
  recruiting,
  confirmed,
  finished;

  bool matches(MultiKolabEventSummary event) => switch (this) {
    MultiKolabOrganizerFilter.all => true,
    MultiKolabOrganizerFilter.drafts =>
      event.status == MultiKolabEventStatus.draft,
    MultiKolabOrganizerFilter.recruiting =>
      event.status == MultiKolabEventStatus.recruiting,
    MultiKolabOrganizerFilter.confirmed =>
      event.status == MultiKolabEventStatus.confirmed,
    MultiKolabOrganizerFilter.finished =>
      event.status == MultiKolabEventStatus.completed ||
          event.status == MultiKolabEventStatus.cancelled ||
          event.status == MultiKolabEventStatus.expired,
  };

  String label(AppLocalizations l10n) => switch (this) {
    MultiKolabOrganizerFilter.all => l10n.multiKolabOrganizerFilterAll,
    MultiKolabOrganizerFilter.drafts => l10n.multiKolabOrganizerFilterDrafts,
    MultiKolabOrganizerFilter.recruiting =>
      l10n.multiKolabOrganizerFilterRecruiting,
    MultiKolabOrganizerFilter.confirmed =>
      l10n.multiKolabOrganizerFilterConfirmed,
    MultiKolabOrganizerFilter.finished =>
      l10n.multiKolabOrganizerFilterFinished,
  };
}

/// The organizer's Multi-Kolab events overview.
///
/// Reached from the My Kolabs "Offers" tab; it is deliberately not a new
/// bottom-nav destination (see the Task 10 design spec §2).
class MultiKolabOrganizerDashboardScreen extends ConsumerStatefulWidget {
  const MultiKolabOrganizerDashboardScreen({super.key});

  @override
  ConsumerState<MultiKolabOrganizerDashboardScreen> createState() =>
      _MultiKolabOrganizerDashboardScreenState();
}

class _MultiKolabOrganizerDashboardScreenState
    extends ConsumerState<MultiKolabOrganizerDashboardScreen> {
  MultiKolabOrganizerFilter _filter = MultiKolabOrganizerFilter.all;

  void _openEvent(String eventId) =>
      context.push(multiKolabOrganizerEventLocation(eventId));

  void _createEvent() =>
      context.push(KolabingRoutes.multiKolabOrganizerEventNew);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final entitlement = ref.watch(multiKolabEntitlementProvider);
    final events = ref.watch(multiKolabMyEventsProvider);

    // Entitlement only gates CREATION. An organizer whose entitlement lapsed
    // must still be able to read and wind down what they already published,
    // so the list is rendered either way; only the create affordances are
    // withheld. The backend is the authority (403 event_creator_required).
    final canCreate = entitlement.value?.hasEventCreatorEntitlement ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: KolabingTopBar(title: l10n.multiKolabOrganizerDashboardTitle),
      // The app's circular FAB, not an extended one: the localized
      // "Create Multi-Kolab event" label makes an extended FAB wider than a
      // 320dp phone, and es/ca are longer still.
      floatingActionButton: canCreate
          ? KolabingFAB(
              key: const Key('multiKolabOrganizerCreateFab'),
              onPressed: _createEvent,
              tooltip: l10n.multiKolabOrganizerCreateCta,
              heroTag: 'multi_kolab_organizer_fab',
            )
          : null,
      body: SafeArea(
        child: events.when(
          loading: () => const _DashboardSkeleton(),
          error: (_, _) => _DashboardError(
            onRetry: () => ref.invalidate(multiKolabMyEventsProvider),
          ),
          data: (all) {
            if (all.isEmpty) {
              return canCreate
                  ? _DashboardEmpty(onCreate: _createEvent)
                  // No request-access destination is passed: Event Creator
                  // is granted manually by a maintainer (entitlement
                  // `source = maintainer`) and there is no self-serve flow
                  // in the app or the API. Routing this at the Business
                  // subscription paywall would be exactly the
                  // subscription/entitlement conflation this feature must
                  // never make, and a dead CTA would be worse than none.
                  : const MultiKolabEntitlementGate();
            }

            final filtered = all.where(_filter.matches).toList(growable: false);

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(multiKolabMyEventsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.sm,
                  KolabingSpacing.md,
                  // Clears the extended FAB.
                  KolabingSpacing.xxxl + KolabingSpacing.md,
                ),
                children: [
                  // Scrollable rather than five equal shares of the row: at
                  // 320dp "RECRUITING"/"RECLUTANT"/"FINALITZATS" have to
                  // shrink below legibility to fit an equal-width segment.
                  KolabingSegmentedControl<MultiKolabOrganizerFilter>(
                    key: const Key('multiKolabOrganizerFilter'),
                    scrollable: true,
                    segments: [
                      for (final f in MultiKolabOrganizerFilter.values)
                        (f, f.label(l10n).toUpperCase()),
                    ],
                    selectedValue: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  if (filtered.isEmpty)
                    _FilterEmpty(
                      onClear: () => setState(
                        () => _filter = MultiKolabOrganizerFilter.all,
                      ),
                    )
                  else
                    for (final event in filtered) ...[
                      MultiKolabOrganizerEventCard(
                        event: event,
                        onManage: () => _openEvent(event.id),
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      key: const Key('multiKolabOrganizerLoading'),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusCard,
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          key: const Key('multiKolabOrganizerError'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.multiKolabExploreErrorBody,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(color: colors.ink),
            ),
            const SizedBox(height: KolabingSpacing.md),
            KolabingButton(
              key: const Key('multiKolabOrganizerRetry'),
              label: l10n.multiKolabOrganizerRetry,
              variant: KolabingButtonVariant.secondary,
              size: KolabingButtonSize.compact,
              width: 200,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          key: const Key('multiKolabOrganizerEmpty'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarPlus, size: 40, color: colors.muted),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.multiKolabOrganizerEmptyTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.sectionHeader.copyWith(
                color: colors.ink,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.multiKolabOrganizerEmptyBody,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: colors.inkBody,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            KolabingButton(
              key: const Key('multiKolabOrganizerEmptyCreateCta'),
              label: l10n.multiKolabOrganizerCreateCta,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
      child: Column(
        key: const Key('multiKolabOrganizerFilterEmpty'),
        children: [
          Text(
            l10n.multiKolabOrganizerFilterEmpty,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: colors.inkBody,
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(l10n.multiKolabOrganizerFilterClear),
          ),
        ],
      ),
    );
  }
}
