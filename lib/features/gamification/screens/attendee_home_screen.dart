import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
            _locationError = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location permissions are permanently denied. Please enable them in settings.';
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled';
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
        _locationError = 'Failed to get location: $e';
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
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;
    final secondaryTextColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.textSecondary;

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
                              'Welcome back',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.displayName ?? 'Attendee',
                              style: GoogleFonts.rubik(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        if (attendeeProfile?.globalRank != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: KolabingColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.trophy,
                                  size: 16,
                                  color: KolabingColors.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '#${attendeeProfile!.globalRank}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: KolabingColors.onPrimary,
                                  ),
                                ),
                              ],
                            ),
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
                      'NEARBY EVENTS',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: secondaryTextColor,
                      ),
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
                              '${discoveryState.radiusKm.toStringAsFixed(0)} km',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: KolabingColors.primary,
                              ),
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(KolabingSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: KolabingColors.primary),
                  SizedBox(height: KolabingSpacing.md),
                  Text('Getting your location...'),
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
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(KolabingSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: KolabingColors.primary),
                  SizedBox(height: KolabingSpacing.md),
                  Text('Searching for events...'),
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
                  'Showing events within ${state.radiusKm.toStringAsFixed(0)} km',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: KolabingColors.info,
                  ),
                ),
              ),
              Text(
                '${state.events.length} found',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.info,
                ),
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
                onTap: () => context.push('/event/${event.id}'),
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
                      label: const Text('Load More'),
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
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: LucideIcons.star,
            iconColor: KolabingColors.primary,
            label: 'Points',
            value: '${attendeeProfile?.totalPoints ?? 0}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.target,
            iconColor: KolabingColors.success,
            label: 'Challenges',
            value: '${attendeeProfile?.totalChallengesCompleted ?? 0}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.calendar,
            iconColor: KolabingColors.info,
            label: 'Events',
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
            'Location Required',
            style: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            _locationError!,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: _initLocation,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Try Again'),
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
            child: const Text('Open Settings'),
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
            'No Events Nearby',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'Try increasing the search radius\nor check back later for new events.',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _showRadiusFilter(context),
            icon: const Icon(LucideIcons.sliders, size: 16),
            label: const Text('Adjust Radius'),
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
            'Failed to load events',
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.md),
          TextButton.icon(
            onPressed: _initLocation,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Try Again'),
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
                color: KolabingColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            'Search Radius',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            '${_radius.toStringAsFixed(0)} km',
            style: GoogleFonts.rubik(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: KolabingColors.primary,
            ),
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
                '1 km',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.textTertiary,
                ),
              ),
              Text(
                '50 km',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.textTertiary,
                ),
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
              child: const Text('Apply'),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],
      ),
    );
  }
}
