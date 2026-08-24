import 'dart:async';

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
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../community/providers/community_follow_provider.dart';
import '../../event/widgets/event_timeline.dart';
import '../../onboarding/models/city.dart';
import '../providers/discovery_provider.dart';
import '../providers/my_events_provider.dart';
import '../widgets/attendee_feed_filters.dart';
import '../widgets/attendee_feed_sections.dart';

/// The attendee feed: what you are going to, who you follow, what is on.
///
/// Rebuilt in #161 along Luma's lines. Three sections, in order of how much the
/// reader already cares about what each one holds:
///
///   1. **Your events** — the sign-ups the old page knew nothing about, so the
///      one thing the attendee opened the app to check was the one thing it
///      could not tell them.
///   2. **Communities you follow** — the other half of the follow, which until
///      now was recorded and then read by exactly one filter.
///   3. **What's on** — city discovery, grouped under date headers.
///
/// What left the page: three stat cards duplicating the profile's own numbers,
/// a "Welcome back" block, and the three fields the old event card carried that
/// were noise or wrong — a distance badge that read "0 m" on every row because
/// city discovery sends no coordinates, a partner-type badge that read
/// "Community" on all of them, and the legacy showcase `attendee_count`.
class AttendeeHomeScreen extends ConsumerStatefulWidget {
  const AttendeeHomeScreen({super.key});

  @override
  ConsumerState<AttendeeHomeScreen> createState() => _AttendeeHomeScreenState();
}

class _AttendeeHomeScreenState extends ConsumerState<AttendeeHomeScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCity());
  }

  /// Seed the city picker with the attendee's own city (if known) and run the
  /// first query.
  void _initCity() {
    if (_initialized) return;
    final user = ref.read(authProvider).user;
    final cityId = user?.cityId;
    final cityName = user?.cityName;
    if (cityId != null && cityId.isNotEmpty && cityName != null) {
      _initialized = true;
      ref.read(discoveryProvider.notifier).setCityAndDiscover(cityId, cityName);
    }
    // If the attendee has no saved city, the user picks one via the picker; the
    // empty state below invites them to do so.
  }

  /// Pull to refresh reloads all three sections — they are three answers to
  /// "what is happening", and refreshing one while leaving the others stale
  /// would be arbitrary.
  Future<void> _onRefresh() async {
    ref.invalidate(myUpcomingEventsProvider);
    ref.invalidate(followedCommunitiesProvider);
    final state = ref.read(discoveryProvider);
    if (state.canQuery) {
      await ref.read(discoveryProvider.notifier).refresh();
    } else {
      _initialized = false;
      _initCity();
    }
  }

  Future<void> _pickCity() async {
    final state = ref.read(discoveryProvider);
    final result = await showModalBottomSheet<OnboardingCity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KolabingRadius.xl),
        ),
      ),
      builder: (_) => FeedCityPickerSheet(selectedCityId: state.cityId),
    );
    if (result != null) {
      _initialized = true;
      await ref
          .read(discoveryProvider.notifier)
          .setCityAndDiscover(result.id, result.name);
      // (#3) Persist the chosen city to the profile so it is remembered across
      // logins (no more re-asking). Best-effort: never block discovery on it.
      unawaited(_persistCity(result.id));
    }
  }

  /// Save the picked city to the user's profile (`PUT /me/profile {city_id}`)
  /// and reflect the fresh user in auth state. Failures are silent — discovery
  /// already ran with the chosen city.
  Future<void> _persistCity(String cityId) async {
    final user = ref.read(authProvider).user;
    if (user == null || user.cityId == cityId) return;
    try {
      final updated = await ref.read(profileServiceProvider).updateProfile({
        'city_id': cityId,
      });
      await ref.read(authProvider.notifier).syncUser(updated);
    } catch (_) {
      // Non-critical: the city is still applied locally for this session.
    }
  }

  /// Human label for the current [DiscoveryDateRange] (chip + sheet rows).
  String _dateRangeLabel(String range, AppLocalizations l10n) {
    switch (range) {
      case DiscoveryDateRange.today:
        return l10n.attendeeHomeFilterToday;
      case DiscoveryDateRange.week:
        return l10n.attendeeHomeFilterThisWeek;
      case DiscoveryDateRange.weekend:
        return l10n.attendeeHomeFilterThisWeekend;
      case DiscoveryDateRange.month:
        return l10n.attendeeHomeFilterThisMonth;
      case DiscoveryDateRange.upcoming:
      default:
        return l10n.attendeeHomeFilterUpcoming;
    }
  }

  /// Date range selector (#5) — ONE dropdown chip (styled like the city chip).
  Future<void> _pickDateRange() async {
    final state = ref.read(discoveryProvider);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KolabingRadius.xl),
        ),
      ),
      builder: (_) => FeedDateRangeSheet(selected: state.dateRange),
    );
    if (result != null) {
      await ref.read(discoveryProvider.notifier).setDateRange(result);
    }
  }

  Future<void> _pickType() async {
    final state = ref.read(discoveryProvider);
    final result = await showModalBottomSheet<FeedTypeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KolabingRadius.xl),
        ),
      ),
      builder: (_) => FeedTypeFilterSheet(selectedSlug: state.typeSlug),
    );
    if (result != null) {
      await ref
          .read(discoveryProvider.notifier)
          .setTypeFilter(typeSlug: result.slug, typeName: result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final attendeeProfile = user?.attendeeProfile;
    final state = ref.watch(discoveryProvider);
    final l10n = AppLocalizations.of(context);

    const hPad = EdgeInsets.symmetric(horizontal: KolabingSpacing.md);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: KolabingColors.primary,
        child: CustomScrollView(
          slivers: [
            // Points, on one line. Everything else the old header carried is
            // either on the profile already or was never worth the space.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  KolabingSpacing.sm,
                ),
                child: AttendeePointsStrip(
                  points: attendeeProfile?.totalPoints ?? 0,
                  eventsAttended: attendeeProfile?.totalEventsAttended ?? 0,
                  onTap: () => context.push(KolabingRoutes.rewards),
                ),
              ),
            ),

            // 1. Your events.
            const SliverToBoxAdapter(
              child: Padding(padding: hPad, child: YourEventsSection()),
            ),

            // 2. The communities you follow.
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  0,
                ),
                child: FollowedCommunitiesStrip(),
              ),
            ),

            // 3. What's on — the city discovery list.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.lg,
                  KolabingSpacing.md,
                  0,
                ),
                child: FeedSectionHeader(
                  title: l10n.attendeeFeedWhatsOn,
                  // Hidden while Following: the results come from wherever the
                  // followed communities are, and a chip reading "Barcelona"
                  // over events in three cities would be a lie.
                  trailing: state.following
                      ? null
                      : FeedCityChip(
                          cityName: state.cityName,
                          onTap: _pickCity,
                          l10n: l10n,
                        ),
                ),
              ),
            ),

            // Scope: All events / Following (#142). Following is the payoff for
            // the follow — without it the tap has no consequence anywhere.
            SliverToBoxAdapter(
              child: Padding(
                padding: hPad,
                child: FeedScopeToggle(
                  following: state.following,
                  onChanged: (following) => ref
                      .read(discoveryProvider.notifier)
                      .setFollowing(following),
                  l10n: l10n,
                ),
              ),
            ),

            // Filter chips: date dropdown (#5) + Type (FX-21).
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.sm,
                ),
                child: Row(
                  children: [
                    FeedDropdownChip(
                      icon: LucideIcons.calendar,
                      label: _dateRangeLabel(state.dateRange, l10n),
                      onTap: _pickDateRange,
                    ),
                    // No type filter while Following: you already know who you
                    // follow, so narrowing them by category answers nothing.
                    if (!state.following) ...[
                      const SizedBox(width: KolabingSpacing.sm),
                      FeedDropdownChip(
                        icon: LucideIcons.tag,
                        label: state.typeName ?? l10n.attendeeHomeFilterType,
                        onTap: _pickType,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            ..._buildEventsContent(state, l10n),

            const SliverToBoxAdapter(
              child: SizedBox(height: KolabingSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventsContent(
    DiscoveryState state,
    AppLocalizations l10n,
  ) {
    // No city selected yet — invite the user to pick one.
    if (!state.canQuery && !state.isLoading) {
      return [SliverToBoxAdapter(child: _buildPickCityPrompt(l10n))];
    }

    // Loading (first page)
    if (state.isLoading && state.events.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: KolabingColors.primary,
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Text(l10n.attendeeHomeSearchingEvents),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Error
    if (state.error != null && state.events.isEmpty) {
      return [
        SliverToBoxAdapter(child: _buildDiscoveryError(state.error!, l10n)),
      ];
    }

    // Empty
    if (state.events.isEmpty) {
      if (state.following) {
        // Two different problems, two different answers: nobody followed yet vs
        // followed communities with nothing announced. Telling them apart is
        // the difference between a dead end and a next step.
        final followsNobody = ref.read(communityFollowsProvider).isEmpty;
        return [
          SliverToBoxAdapter(
            child: _buildEmptyFollowing(l10n, followsNobody: followsNobody),
          ),
        ];
      }
      return [SliverToBoxAdapter(child: _buildEmptyEvents(l10n))];
    }

    // The list, grouped under date headers — the same timeline the community
    // pages use, so an event looks like an event wherever you meet it.
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
          child: EventTimeline(
            events: state.events,
            // A city-wide list: whose event this is matters more than anything
            // else on the row.
            showHost: true,
            // Discovery only ever returns public events, so a "Public" chip on
            // every row would say nothing.
            showVisibility: false,
            onOpen: (event) =>
                context.push(KolabingRoutes.buildEventDetailPath(event.id)),
          ),
        ),
      ),
      if (state.hasMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Center(
              child: state.isLoading
                  ? const CircularProgressIndicator(
                      color: KolabingColors.primary,
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          ref.read(discoveryProvider.notifier).loadMore(),
                      icon: const Icon(LucideIcons.chevronDown, size: 16),
                      label: Text(l10n.attendeeHomeLoadMore),
                      style: TextButton.styleFrom(
                        foregroundColor: KolabingColors.onSurface,
                      ),
                    ),
            ),
          ),
        ),
    ];
  }

  Widget _buildPickCityPrompt(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        children: [
          Icon(
            LucideIcons.mapPin,
            size: 64,
            color: KolabingColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            l10n.attendeeHomePickCityTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.attendeeHomePickCityHint,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton.icon(
            onPressed: _pickCity,
            icon: const Icon(LucideIcons.mapPin, size: 16),
            label: Text(l10n.attendeeHomeChooseCity),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.onSurface,
              side: const BorderSide(color: KolabingColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KolabingRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEvents(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        children: [
          Icon(
            LucideIcons.calendarOff,
            size: 64,
            color: KolabingColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            l10n.attendeeHomeNoEventsCity,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.attendeeHomeNoEventsCityHint,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton.icon(
            onPressed: _pickCity,
            icon: const Icon(LucideIcons.mapPin, size: 16),
            label: Text(l10n.attendeeHomeChooseCity),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.onSurface,
              side: const BorderSide(color: KolabingColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KolabingRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The Following feed with nothing in it (#142).
  ///
  /// [followsNobody] separates the two reasons, because they need different
  /// answers: someone who follows nobody needs to find a community, and
  /// someone whose communities have announced nothing needs to know it is not
  /// their fault. One empty state for both would be wrong for both.
  Widget _buildEmptyFollowing(
    AppLocalizations l10n, {
    required bool followsNobody,
  }) {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        children: [
          Icon(
            followsNobody ? LucideIcons.compass : LucideIcons.calendarOff,
            size: 64,
            color: KolabingColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            followsNobody
                ? l10n.attendeeHomeNoFollowsTitle
                : l10n.attendeeHomeNoFollowedEventsTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            followsNobody
                ? l10n.attendeeHomeNoFollowsHint
                : l10n.attendeeHomeNoFollowedEventsHint,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => context.push(KolabingRoutes.discoverCommunities),
            icon: const Icon(LucideIcons.compass, size: 16),
            label: Text(
              followsNobody
                  ? l10n.attendeeHomeExploreCommunities
                  : l10n.attendeeHomeFollowMore,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.onSurface,
              side: const BorderSide(color: KolabingColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KolabingRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryError(String error, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: KolabingColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            l10n.attendeeHomeFailedToLoadEvents,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.md),
          TextButton.icon(
            onPressed: () => ref.read(discoveryProvider.notifier).refresh(),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(l10n.attendeeHomeTryAgain),
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
