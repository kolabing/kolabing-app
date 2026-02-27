import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../providers/discovery_provider.dart';
import '../widgets/discovered_event_card.dart';

/// Screen for discovering nearby events via GPS
class EventDiscoveryScreen extends ConsumerStatefulWidget {
  const EventDiscoveryScreen({super.key});

  @override
  ConsumerState<EventDiscoveryScreen> createState() =>
      _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends ConsumerState<EventDiscoveryScreen> {
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
      // Check location permission
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

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Update discovery with location
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

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Events',
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (discoveryState.hasLocation)
            IconButton(
              icon: const Icon(LucideIcons.sliders),
              onPressed: () => _showRadiusFilter(context),
            ),
        ],
      ),
      body: _buildBody(discoveryState),
    );
  }

  Widget _buildBody(DiscoveryState state) {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: KolabingColors.primary),
            SizedBox(height: KolabingSpacing.md),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return _buildLocationError();
    }

    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: KolabingColors.primary),
            SizedBox(height: KolabingSpacing.md),
            Text('Searching for events...'),
          ],
        ),
      );
    }

    if (state.error != null && state.events.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.events.isEmpty) {
      return _buildEmptyState();
    }

    return _buildEventsList(state);
  }

  Widget _buildEventsList(DiscoveryState state) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(discoveryProvider.notifier).refresh();
      },
      color: KolabingColors.primary,
      child: CustomScrollView(
        slivers: [
          // Radius info
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(KolabingSpacing.md),
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: KolabingColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: KolabingColors.info,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Text(
                      'Showing events within ${state.radiusKm.toStringAsFixed(0)} km',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: KolabingColors.info,
                      ),
                    ),
                  ),
                  Text(
                    '${state.events.length} found',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Events list
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
                    onTap: () => _openEvent(event.id),
                  ),
                );
              },
              childCount: state.events.length,
            ),
          ),

          // Load more button
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
                          icon: const Icon(LucideIcons.chevronDown),
                          label: const Text('Load More'),
                          style: TextButton.styleFrom(
                            foregroundColor: KolabingColors.primary,
                          ),
                        ),
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: KolabingSpacing.xl),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              icon: const Icon(LucideIcons.refreshCw),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 80,
              color: KolabingColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              'No Events Nearby',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              'Try increasing the search radius\nor check back later for new events.',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _showRadiusFilter(context),
              icon: const Icon(LucideIcons.sliders),
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
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              'Failed to discover events',
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
              onPressed: () {
                ref.read(discoveryProvider.notifier).refresh();
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: KolabingColors.primary,
              ),
            ),
          ],
        ),
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

  void _openEvent(String eventId) {
    context.push('/attendee/events/$eventId');
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
