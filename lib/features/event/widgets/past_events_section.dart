import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import 'add_event_modal.dart';
import 'event_card.dart';

/// Section widget displaying past events on profile screens.
///
/// When [profileId] is null, shows the current user's events with add/edit
/// capabilities. When [profileId] is provided, shows that user's events in
/// read-only mode (no ADD button).
class PastEventsSection extends ConsumerWidget {
  const PastEventsSection({this.profileId, super.key});

  /// If set, loads events for this profile (read-only public view).
  /// If null, uses the current user's events provider with editing.
  final String? profileId;

  bool get _isReadOnly => profileId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Public profile → use family provider
    if (_isReadOnly) {
      return _buildPublicView(context, ref, isDark);
    }

    // Own profile → use global notifier provider
    final state = ref.watch(eventsProvider);
    return _buildContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, ref, state.events, isDark),
          const SizedBox(height: KolabingSpacing.md),
          _buildOwnContent(context, ref, state, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Public profile view (read-only, family provider)
  // ---------------------------------------------------------------------------

  Widget _buildPublicView(BuildContext context, WidgetRef ref, bool isDark) {
    final asyncEvents = ref.watch(profileEventsProvider(profileId!));

    return asyncEvents.when(
      loading: () => _buildContainer(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, ref, const [], isDark),
            const SizedBox(height: KolabingSpacing.md),
            _buildLoadingState(isDark),
          ],
        ),
      ),
      error: (error, _) => _buildContainer(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, ref, const [], isDark),
            const SizedBox(height: KolabingSpacing.md),
            _buildErrorState(context, ref, error.toString(), isDark),
          ],
        ),
      ),
      data: (events) {
        // Hide section entirely if public profile has no events
        if (events.isEmpty) return const SizedBox.shrink();

        return _buildContainer(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, ref, events, isDark),
              const SizedBox(height: KolabingSpacing.md),
              _buildEventsListFromEvents(context, events),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Shared container
  // ---------------------------------------------------------------------------

  Widget _buildContainer({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, List<Event> events, bool isDark) {
    return Row(
      children: [
        Icon(
          LucideIcons.calendar,
          size: 20,
          color: context.colors.primary,
        ),
        const SizedBox(width: KolabingSpacing.xs),
        Text(
          AppLocalizations.of(context).pastEventsTitle,
          style: KolabingTextStyles.titleMedium.copyWith(
            color:
                isDark ? context.colors.textOnDark : context.colors.onSurface,
          ),
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(width: KolabingSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
            child: Text(
              '${events.length}',
              style: KolabingTextStyles.labelSmall.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        // Only show ADD button on own profile
        if (!_isReadOnly)
          TextButton.icon(
            onPressed: () => _showAddEventModal(context, ref),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(AppLocalizations.of(context).pastEventsAddButton),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Own profile content (with full state handling)
  // ---------------------------------------------------------------------------

  Widget _buildOwnContent(
      BuildContext context, WidgetRef ref, EventsState state, bool isDark) {
    if (state.isLoading) {
      return _buildLoadingState(isDark);
    }

    if (state.error != null && state.events.isEmpty) {
      return _buildErrorState(context, ref, state.error!, isDark);
    }

    if (state.events.isEmpty) {
      return _buildEmptyState(context, ref, isDark);
    }

    return _buildEventsListFromEvents(context, state.events);
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState(bool isDark) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: KolabingSpacing.sm),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: isDark
              ? context.colors.darkSurface
              : context.colors.surfaceVariant,
          highlightColor:
              isDark ? context.colors.darkBorder : context.colors.surface,
          child: Container(
            width: 180,
            decoration: BoxDecoration(
              color: isDark ? context.colors.darkSurface : Colors.white,
              borderRadius: KolabingRadius.borderRadiusLg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 32,
            color: context.colors.error,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            AppLocalizations.of(context).pastEventsLoadError,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          TextButton(
            onPressed: () {
              if (_isReadOnly) {
                ref.invalidate(profileEventsProvider(profileId!));
              } else {
                ref.read(eventsProvider.notifier).refresh();
              }
            },
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? context.colors.darkBorder
                  : context.colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.calendarX,
              size: 28,
              color: isDark
                  ? context.colors.textOnDark.withValues(alpha: 0.6)
                  : context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            AppLocalizations.of(context).pastEventsEmptyTitle,
            style: KolabingTextStyles.titleSmall.copyWith(
              color: isDark
                  ? context.colors.textOnDark
                  : context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            AppLocalizations.of(context).pastEventsEmptySubtitle,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.md),
          TextButton.icon(
            onPressed: () => _showAddEventModal(context, ref),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              AppLocalizations.of(context).pastEventsEmptyAddButton,
              style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsListFromEvents(BuildContext context, List<Event> events) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: KolabingSpacing.sm),
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            onTap: () => context.push(
              KolabingRoutes.buildEventDetailPath(
                event.id,
                isReadOnly: _isReadOnly,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddEventModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEventModal(),
    );
  }
}
