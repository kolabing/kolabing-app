import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/multi_kolab_event.dart';
import '../providers/multi_kolab_providers.dart';
import '../widgets/multi_kolab_explore_card.dart';

/// Standalone browse screen for recruiting Multi-Kolab Events. Reachable
/// from a lightweight entry point on the main Explore screen (see
/// `explore_screen.dart`'s `_MultiKolabEventsBanner`) — deliberately a
/// separate screen rather than interleaved into the ordinary Kolab swipe
/// deck, so the existing deck/gesture/bookmark logic is completely
/// untouched by this feature (see the Task 9 completion notes for why).
class MultiKolabExploreScreen extends ConsumerWidget {
  const MultiKolabExploreScreen({super.key});

  static const MultiKolabExploreFilter _filter = MultiKolabExploreFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final asyncEvents = ref.watch(multiKolabExploreProvider(_filter));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.multiKolabExploreTitle)),
      body: asyncEvents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.alertCircle, color: colors.error),
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  l10n.multiKolabExploreErrorBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KolabingSpacing.sm),
                KolabingButton(
                  label: l10n.commonRetry,
                  onPressed: () =>
                      ref.invalidate(multiKolabExploreProvider(_filter)),
                ),
              ],
            ),
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(KolabingSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendarDays,
                      color: colors.onSurfaceVariant,
                      size: 40,
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Text(
                      l10n.multiKolabExploreEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: KolabingSpacing.xxxs),
                    Text(
                      l10n.multiKolabExploreEmptyBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(multiKolabExploreProvider(_filter));
              await ref.read(multiKolabExploreProvider(_filter).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              itemCount: events.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: KolabingSpacing.sm),
              itemBuilder: (context, index) {
                final event = events[index];
                return MultiKolabExploreCard(
                  event: event,
                  onTap: () => context.push(
                    KolabingRoutes.multiKolabEventDetail.replaceFirst(
                      ':id',
                      event.id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
