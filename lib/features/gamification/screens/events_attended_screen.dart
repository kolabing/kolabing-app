import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendee_profile_detail.dart';
import '../providers/attendee_profile_provider.dart';

/// Full, paginated history of the current user's attended events.
///
/// Consumes `GET /me/events-attended` via [eventsAttendedProvider].
class EventsAttendedScreen extends ConsumerStatefulWidget {
  const EventsAttendedScreen({super.key});

  @override
  ConsumerState<EventsAttendedScreen> createState() =>
      _EventsAttendedScreenState();
}

class _EventsAttendedScreenState extends ConsumerState<EventsAttendedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsAttendedProvider.notifier).loadFirstPage();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(eventsAttendedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(eventsAttendedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventsAttendedTitle)),
      body: _buildBody(context, l10n, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    EventsAttendedState state,
  ) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.events.isEmpty) {
      return _ErrorState(
        message: l10n.eventsAttendedError,
        onRetry: () =>
            ref.read(eventsAttendedProvider.notifier).loadFirstPage(),
      );
    }

    if (state.isEmpty) {
      return _EmptyState(message: l10n.eventsAttendedEmpty);
    }

    final itemCount = state.events.length + (state.hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(eventsAttendedProvider.notifier).loadFirstPage(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(KolabingSpacing.md),
        itemCount: itemCount + 1,
        separatorBuilder: (context, index) => index == 0
            ? const SizedBox.shrink()
            : const SizedBox(height: KolabingSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: Text(
                l10n.eventsAttendedTotal(state.total),
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final itemIndex = index - 1;
          if (itemIndex >= state.events.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return AttendedEventTile(event: state.events[itemIndex]);
        },
      ),
    );
  }
}

/// Reusable tile for a single attended event. Used by the full list and the
/// profile preview.
class AttendedEventTile extends StatelessWidget {
  const AttendedEventTile({super.key, required this.event});

  final AttendedEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);

    final date = event.eventDate ?? event.checkedInAt;
    final subtitleParts = <String>[
      if (date != null) dateFormat.format(date),
      if (event.community != null) event.community!.name,
    ];

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KolabingColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KolabingColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.calendarCheck,
                size: 20,
                color: KolabingColors.info,
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventName,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (event.checkedInAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.eventsAttendedCheckedIn(
                      dateFormat.format(event.checkedInAt!),
                    ),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.calendarX,
              size: 48,
              color: KolabingColors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
