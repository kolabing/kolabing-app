import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
            _locationError = l10n.eventDiscoveryPermissionDenied;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = l10n.eventDiscoveryPermissionDeniedForever;
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = l10n.eventDiscoveryServicesDisabled;
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
        _locationError = l10n.eventDiscoveryLocationFailed(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).eventDiscoveryTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.colors.primary),
            const SizedBox(height: KolabingSpacing.md),
            Text(AppLocalizations.of(context).eventDiscoveryGettingLocation),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return _buildLocationError();
    }

    if (state.isLoading && state.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.colors.primary),
            const SizedBox(height: KolabingSpacing.md),
            Text(AppLocalizations.of(context).eventDiscoverySearching),
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
      color: context.colors.primary,
      child: CustomScrollView(
        slivers: [
          // Radius info
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(KolabingSpacing.md),
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: context.colors.info,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).eventDiscoveryRadiusInfo(state.radiusKm.toStringAsFixed(0)),
                      style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.info),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).eventDiscoveryFoundCount(state.events.length),
                    style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.info),
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
                      ? CircularProgressIndicator(
                          color: context.colors.primary,
                        )
                      : TextButton.icon(
                          onPressed: () {
                            ref.read(discoveryProvider.notifier).loadMore();
                          },
                          icon: const Icon(LucideIcons.chevronDown),
                          label: Text(AppLocalizations.of(context).eventDiscoveryLoadMore),
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
              color: context.colors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              AppLocalizations.of(context).eventDiscoveryLocationRequired,
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              _locationError!,
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            ElevatedButton.icon(
              onPressed: _initLocation,
              icon: const Icon(LucideIcons.refreshCw),
              label: Text(AppLocalizations.of(context).commonTryAgain),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: Text(AppLocalizations.of(context).eventDiscoveryOpenSettings),
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
              color: context.colors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              AppLocalizations.of(context).eventDiscoveryEmptyTitle,
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              AppLocalizations.of(context).eventDiscoveryEmptyBody,
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _showRadiusFilter(context),
              icon: const Icon(LucideIcons.sliders),
              label: Text(AppLocalizations.of(context).eventDiscoveryAdjustRadius),
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
              color: context.colors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).eventDiscoveryErrorTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: () {
                ref.read(discoveryProvider.notifier).refresh();
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(AppLocalizations.of(context).commonTryAgain),
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
                color: context.colors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).eventDiscoverySearchRadius,
            style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: context.colors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).eventDiscoveryRadiusKm(_radius.toStringAsFixed(0)),
            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 36, fontWeight: FontWeight.w700, color: context.colors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: context.colors.primary,
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
                AppLocalizations.of(context).eventDiscoveryRadiusKm('1'),
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
              ),
              Text(
                AppLocalizations.of(context).eventDiscoveryRadiusKm('50'),
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onRadiusChanged(_radius),
              child: Text(AppLocalizations.of(context).eventDiscoveryApply),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
        ],
      ),
    );
  }
}
