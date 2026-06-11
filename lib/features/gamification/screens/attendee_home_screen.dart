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
import '../../../widgets/ui_icon.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../onboarding/models/city.dart';
import '../../onboarding/models/community_type.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/city_list_item.dart';
import '../providers/discovery_provider.dart';
import '../widgets/discovered_event_card.dart';
import '../widgets/stat_card.dart';

/// Attendee home screen: stats summary + a CITY-BASED events feed (NF-19).
///
/// The events section is driven by a city picker (defaulting to the attendee's
/// own city), a `Today` toggle, and a community-type filter sheet
/// (`communityTypesProvider`). The legacy GPS/radius placeholder is gone
/// (FX-21). A persistent "Explore communities" CTA links to discovery (FX-23),
/// and the stat icons use the on-brand UiIcon set (FX-22).
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

  Future<void> _onRefresh() async {
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(KolabingRadius.xl)),
      ),
      builder: (_) => _CityPickerSheet(selectedCityId: state.cityId),
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
      final updated = await ref
          .read(profileServiceProvider)
          .updateProfile({'city_id': cityId});
      await ref.read(authProvider.notifier).syncUser(updated);
    } catch (_) {
      // Non-critical: the city is still applied locally for this session.
    }
  }

  Future<void> _pickType() async {
    final state = ref.read(discoveryProvider);
    final result = await showModalBottomSheet<_TypeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(KolabingRadius.xl)),
      ),
      builder: (_) => _TypeFilterSheet(selectedSlug: state.typeSlug),
    );
    if (result != null) {
      await ref.read(discoveryProvider.notifier).setTypeFilter(
            typeSlug: result.slug,
            typeName: result.name,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final attendeeProfile = user?.attendeeProfile;
    final state = ref.watch(discoveryProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.onSurface;
    final secondaryTextColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: KolabingColors.primary,
        child: CustomScrollView(
          slivers: [
            // Header + Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.attendeeHomeWelcomeBack,
                      style: KolabingTextStyles.bodySmall
                          .copyWith(color: secondaryTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName ?? l10n.attendeeRoleLabel,
                      style: KolabingTextStyles.bodyLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.lg),
                    _buildStatsSection(attendeeProfile),
                    const SizedBox(height: KolabingSpacing.md),
                    _ExploreCommunitiesCta(l10n: l10n),
                  ],
                ),
              ),
            ),

            // Events section header + city picker (FX-21)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.sm,
                  KolabingSpacing.md,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.attendeeHomeEventsTitle,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    _CityPickerButton(
                      cityName: state.cityName,
                      onTap: _pickCity,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            ),

            // Filter chips: date selector (#5) + Type (FX-21)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.sm,
                ),
                child: Row(
                  children: [
                    for (final opt in [
                      (DiscoveryDateRange.today, l10n.attendeeHomeFilterToday),
                      (DiscoveryDateRange.week, l10n.attendeeHomeFilterThisWeek),
                      (
                        DiscoveryDateRange.weekend,
                        l10n.attendeeHomeFilterThisWeekend
                      ),
                      (
                        DiscoveryDateRange.month,
                        l10n.attendeeHomeFilterThisMonth
                      ),
                    ]) ...[
                      _FilterChip(
                        label: opt.$2,
                        selected: state.dateRange == opt.$1,
                        onTap: () => ref
                            .read(discoveryProvider.notifier)
                            // Tapping the active range clears it back to upcoming.
                            .setDateRange(state.dateRange == opt.$1
                                ? DiscoveryDateRange.upcoming
                                : opt.$1),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                    ],
                    _FilterChip(
                      label: state.typeName ?? l10n.attendeeHomeFilterType,
                      selected: state.typeSlug != null,
                      trailingIcon: LucideIcons.chevronDown,
                      onTap: _pickType,
                    ),
                  ],
                ),
              ),
            ),

            // Events feed content
            ..._buildEventsContent(state, l10n),

            const SliverToBoxAdapter(
              child: SizedBox(height: KolabingSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventsContent(DiscoveryState state, AppLocalizations l10n) {
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
                      color: KolabingColors.primary),
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
      return [SliverToBoxAdapter(child: _buildDiscoveryError(state.error!, l10n))];
    }

    // Empty
    if (state.events.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyEvents(l10n))];
    }

    // Event list
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = state.events[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.xs,
              ),
              child: DiscoveredEventCard(
                event: event,
                onTap: () => context.push(
                  KolabingRoutes.buildEventDetailPath(event.id),
                ),
              ),
            );
          },
          childCount: state.events.length,
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

  Widget _buildStatsSection(dynamic attendeeProfile) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: LucideIcons.trophy,
            iconSlug: UiIconSlug.trophy,
            iconColor: KolabingColors.primaryDark,
            label: l10n.attendeeHomeStatPoints,
            value: '${attendeeProfile?.totalPoints ?? 0}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.flame,
            iconSlug: UiIconSlug.flame,
            iconColor: KolabingColors.success,
            label: l10n.attendeeHomeStatChallenges,
            value: '${attendeeProfile?.totalChallengesCompleted ?? 0}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.calendar,
            iconSlug: UiIconSlug.calendar,
            iconColor: KolabingColors.info,
            label: l10n.attendeeHomeStatEvents,
            value: '${attendeeProfile?.totalEventsAttended ?? 0}',
          ),
        ),
      ],
    );
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
            style: KolabingTextStyles.bodySmall
                .copyWith(color: KolabingColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: _pickCity,
            icon: const Icon(LucideIcons.mapPin, size: 16),
            label: Text(l10n.attendeeHomeChooseCity),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
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
            style: KolabingTextStyles.bodySmall
                .copyWith(color: KolabingColors.textTertiary),
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
            style: KolabingTextStyles.bodySmall
                .copyWith(color: KolabingColors.onSurfaceVariant),
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

// =============================================================================
// Explore communities CTA (FX-23) — always visible
// =============================================================================

class _ExploreCommunitiesCta extends StatelessWidget {
  const _ExploreCommunitiesCta({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.push(KolabingRoutes.discoverCommunities),
          icon: const Icon(LucideIcons.compass, size: 18),
          label: Text(l10n.attendeeHomeExploreCommunities),
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.onSurface,
            side: const BorderSide(color: KolabingColors.outlineVariant),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KolabingRadius.md),
            ),
          ),
        ),
      );
}

// =============================================================================
// City picker button (FX-21) — dark/readable, in the events header corner
// =============================================================================

class _CityPickerButton extends StatelessWidget {
  const _CityPickerButton({
    required this.cityName,
    required this.onTap,
    required this.l10n,
  });

  final String? cityName;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: KolabingColors.surfaceVariant,
            borderRadius: BorderRadius.circular(KolabingRadius.round),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 14,
                color: KolabingColors.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                cityName ?? l10n.attendeeHomeChooseCity,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: KolabingColors.onSurface,
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// Filter chip (FX-21) — readable dark text, not yellow-on-light
// =============================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? KolabingColors.primary : KolabingColors.surfaceVariant;
    final fg = KolabingColors.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(KolabingRadius.round),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 14, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// City picker sheet — reuses citiesProvider + CityListItem
// =============================================================================

class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet({this.selectedCityId});

  final String? selectedCityId;

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = ref.watch(filteredCitiesProvider(_query));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.outlineVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: KolabingTextStyles.bodyMedium
                    .copyWith(color: KolabingColors.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.editProfileCitySearchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: KolabingColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                    vertical: KolabingSpacing.sm,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.editProfileNoCitiesFound,
                        style: KolabingTextStyles.bodySmall
                            .copyWith(color: KolabingColors.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: cities.length,
                    itemBuilder: (_, i) {
                      final city = cities[i];
                      return CityListItem(
                        id: city.id,
                        name: city.name,
                        country: city.country,
                        isSelected: widget.selectedCityId == city.id,
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: KolabingColors.primary),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.editProfileCityLoadError,
                        style: KolabingTextStyles.bodySmall
                            .copyWith(color: KolabingColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      TextButton(
                        onPressed: () => ref.invalidate(citiesProvider),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Community-type filter sheet — slugs ONLY from communityTypesProvider
// =============================================================================

class _TypeSelection {
  const _TypeSelection({this.slug, this.name});
  final String? slug;
  final String? name;
}

class _TypeFilterSheet extends ConsumerWidget {
  const _TypeFilterSheet({this.selectedSlug});

  final String? selectedSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final typesAsync = ref.watch(communityTypesProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.outlineVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Text(
                l10n.attendeeHomeFilterType,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
            ),
            Expanded(
              child: typesAsync.when(
                data: (types) => ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _TypeRow(
                      label: l10n.attendeeHomeFilterTypeAll,
                      selected: selectedSlug == null,
                      onTap: () => Navigator.of(context)
                          .pop(const _TypeSelection()),
                    ),
                    for (final CommunityType t in types)
                      _TypeRow(
                        label: t.name,
                        selected: selectedSlug == t.slug,
                        onTap: () => Navigator.of(context)
                            .pop(_TypeSelection(slug: t.slug, name: t.name)),
                      ),
                  ],
                ),
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: KolabingColors.primary),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.attendeeHomeFailedToLoadEvents,
                        style: KolabingTextStyles.bodySmall
                            .copyWith(color: KolabingColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      TextButton(
                        onPressed: () => ref.invalidate(communityTypesProvider),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: KolabingColors.onSurface,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  LucideIcons.check,
                  size: 18,
                  color: KolabingColors.primaryDark,
                ),
            ],
          ),
        ),
      );
}
