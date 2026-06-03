import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../widgets/discovered_event_card.dart';
import '../widgets/stat_card.dart';

/// Attendee home screen showing stats summary + location-based events feed
class AttendeeHomeScreen extends ConsumerStatefulWidget {
  const AttendeeHomeScreen({super.key});

  @override
  ConsumerState<AttendeeHomeScreen> createState() => _AttendeeHomeScreenState();
}

class _AttendeeHomeScreenState extends ConsumerState<AttendeeHomeScreen> {
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = AppLocalizations.of(context).attendeeHomeLocationDenied;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              AppLocalizations.of(context).attendeeHomeLocationDeniedForever;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = AppLocalizations.of(context).attendeeHomeLocationServicesDisabled;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await ref.read(discoveryProvider.notifier).setLocationAndDiscover(
            position.latitude,
            position.longitude,
          );

      setState(() {
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = AppLocalizations.of(context).attendeeHomeLocationError(e.toString());
      });
    }
  }

  Future<void> _onRefresh() async {
    if (ref.read(discoveryProvider).hasLocation) {
      await ref.read(discoveryProvider.notifier).refresh();
    } else {
      await _initLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final attendeeProfile = user?.attendeeProfile;
    final discoveryState = ref.watch(discoveryProvider);

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
                    // Greeting row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.attendeeHomeWelcomeBack,
                              style: KolabingTextStyles.bodySmall.copyWith(color: secondaryTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.displayName ?? l10n.attendeeRoleLabel,
                              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: KolabingSpacing.lg),

                    // Stats grid
                    _buildStatsSection(attendeeProfile),
                  ],
                ),
              ),
            ),

            // Events section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.attendeeHomeNearbyEvents,
                      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: secondaryTextColor, letterSpacing: 1.2),
                    ),
                    if (discoveryState.hasLocation)
                      GestureDetector(
                        onTap: () => _showRadiusFilter(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.sliders,
                              size: 14,
                              color: KolabingColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.attendeeHomeRadiusKm(discoveryState.radiusKm.toStringAsFixed(0)),
                              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: KolabingColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Events feed content
            ..._buildEventsContent(discoveryState),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: KolabingSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventsContent(DiscoveryState state) {
    // Location loading
    if (_isLoadingLocation) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: KolabingColors.primary),
                  const SizedBox(height: KolabingSpacing.md),
                  Text(AppLocalizations.of(context).attendeeHomeGettingLocation),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Location error
    if (_locationError != null) {
      return [
        SliverToBoxAdapter(child: _buildLocationError()),
      ];
    }

    // Discovery loading (no events yet)
    if (state.isLoading && state.events.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: KolabingColors.primary),
                  const SizedBox(height: KolabingSpacing.md),
                  Text(AppLocalizations.of(context).attendeeHomeSearchingEvents),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Discovery error
    if (state.error != null && state.events.isEmpty) {
      return [
        SliverToBoxAdapter(child: _buildDiscoveryError(state.error!)),
      ];
    }

    // No events found
    if (state.events.isEmpty) {
      return [
        SliverToBoxAdapter(child: _buildEmptyEvents()),
      ];
    }

    // Events list
    return [
      // Radius info bar
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: KolabingColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 16,
                color: KolabingColors.info,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).attendeeHomeShowingWithinRadius(state.radiusKm.toStringAsFixed(0)),
                  style: KolabingTextStyles.captionSecondary.copyWith(color: KolabingColors.info),
                ),
              ),
              Text(
                AppLocalizations.of(context).attendeeHomeEventsFound(state.events.length),
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: KolabingColors.info),
              ),
            ],
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: KolabingSpacing.sm)),

      // Event cards
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

      // Load more
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
                      onPressed: () {
                        ref.read(discoveryProvider.notifier).loadMore();
                      },
                      icon: const Icon(LucideIcons.chevronDown, size: 16),
                      label: Text(AppLocalizations.of(context).attendeeHomeLoadMore),
                      style: TextButton.styleFrom(
                        foregroundColor: KolabingColors.primary,
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
            icon: LucideIcons.star,
            iconColor: KolabingColors.primary,
            label: l10n.attendeeHomeStatPoints,
            value: '${attendeeProfile?.totalPoints ?? 0}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.target,
            iconColor: KolabingColors.success,
            label: l10n.attendeeHomeStatChallenges,
            value: '${attendeeProfile?.totalChallengesCompleted ?? 0}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.calendar,
            iconColor: KolabingColors.info,
            label: l10n.attendeeHomeStatEvents,
            value: '${attendeeProfile?.totalEventsAttended ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildLocationError() {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        children: [
          Icon(
            LucideIcons.mapPinOff,
            size: 64,
            color: KolabingColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).attendeeHomeLocationRequired,
            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            _locationError!,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: _initLocation,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(AppLocalizations.of(context).attendeeHomeTryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: Text(AppLocalizations.of(context).attendeeHomeOpenSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEvents() {
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
            AppLocalizations.of(context).attendeeHomeNoEventsNearby,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            AppLocalizations.of(context).attendeeHomeNoEventsNearbyHint,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _showRadiusFilter(context),
            icon: const Icon(LucideIcons.sliders, size: 16),
            label: Text(AppLocalizations.of(context).attendeeHomeAdjustRadius),
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.primary,
              side: const BorderSide(color: KolabingColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryError(String error) {
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
            AppLocalizations.of(context).attendeeHomeFailedToLoadEvents,
            style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.md),
          TextButton.icon(
            onPressed: _initLocation,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(AppLocalizations.of(context).attendeeHomeTryAgain),
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusFilter(BuildContext context) {
    final currentRadius = ref.read(discoveryProvider).radiusKm;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RadiusFilterSheet(
        currentRadius: currentRadius,
        onRadiusChanged: (radius) {
          ref.read(discoveryProvider.notifier).updateRadius(radius);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _RadiusFilterSheet extends StatefulWidget {
  const _RadiusFilterSheet({
    required this.currentRadius,
    required this.onRadiusChanged,
  });

  final double currentRadius;
  final ValueChanged<double> onRadiusChanged;

  @override
  State<_RadiusFilterSheet> createState() => _RadiusFilterSheetState();
}

class _RadiusFilterSheetState extends State<_RadiusFilterSheet> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.currentRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).attendeeHomeSearchRadius,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).attendeeHomeRadiusKm(_radius.toStringAsFixed(0)),
            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 36, fontWeight: FontWeight.w700, color: KolabingColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: KolabingColors.primary,
            onChanged: (value) {
              setState(() {
                _radius = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).attendeeHomeRadiusKm('1'),
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.textTertiary),
              ),
              Text(
                AppLocalizations.of(context).attendeeHomeRadiusKm('50'),
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onRadiusChanged(_radius),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context).attendeeHomeApply),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],
      ),
    );
  }
}
