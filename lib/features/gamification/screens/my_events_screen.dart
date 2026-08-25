import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../event/widgets/event_timeline.dart';
import '../providers/my_events_provider.dart';

/// Everything the attendee has signed up for that has not happened yet.
///
/// The feed's "Your events" section shows the next three; this is where the
/// rest live (#161). Same date-grouped timeline as the feed and the community
/// pages — one event row across the whole app.
class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(myUpcomingEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myEventsTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myUpcomingEventsProvider),
        color: context.colors.primary,
        child: events.when(
          data: (list) => list.isEmpty
              ? _Empty(l10n: l10n)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    KolabingSpacing.md,
                    0,
                    KolabingSpacing.md,
                    KolabingSpacing.xl,
                  ),
                  child: EventTimeline(
                    events: list,
                    showHost: true,
                    // Your own sign-ups: access is not in question.
                    showVisibility: false,
                    onOpen: (event) => context.push(
                      KolabingRoutes.buildEventDetailPath(event.id),
                    ),
                  ),
                ),
          loading: () => Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
          error: (error, _) => _Error(message: error.toString(), l10n: l10n),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(KolabingSpacing.xl),
    children: [
      const SizedBox(height: KolabingSpacing.xl),
      Icon(
        LucideIcons.calendarOff,
        size: 64,
        color: context.colors.textTertiary.withValues(alpha: 0.5),
      ),
      const SizedBox(height: KolabingSpacing.md),
      Text(
        l10n.myEventsEmpty,
        textAlign: TextAlign.center,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        l10n.myEventsEmptyHint,
        textAlign: TextAlign.center,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.l10n});

  final String message;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(KolabingSpacing.xl),
    children: [
      const SizedBox(height: KolabingSpacing.xl),
      Icon(
        LucideIcons.alertCircle,
        size: 48,
        color: context.colors.error.withValues(alpha: 0.7),
      ),
      const SizedBox(height: KolabingSpacing.md),
      Text(
        l10n.attendeeHomeFailedToLoadEvents,
        textAlign: TextAlign.center,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.onSurface,
        ),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        message,
        textAlign: TextAlign.center,
        style: KolabingTextStyles.bodySmall.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
