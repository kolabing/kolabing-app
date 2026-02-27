import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';

/// Detail screen for viewing a single event
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Event? _getEvent(EventsState state) {
    try {
      return state.events.firstWhere((e) => e.id == widget.eventId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleDelete(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(eventsProvider.notifier).deleteEvent(event.id);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted'),
            backgroundColor: KolabingColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);
    final event = _getEvent(state);

    if (event == null) {
      return Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.arrowLeft),
            color: KolabingColors.textPrimary,
          ),
        ),
        body: Center(
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
                'Event not found',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          _buildSliverAppBar(event),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    event.name,
                    style: KolabingTextStyles.headlineMedium.copyWith(
                      color: KolabingColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.lg),

                  // Info Cards
                  _buildInfoCard(event),

                  const SizedBox(height: KolabingSpacing.lg),

                  // Photo Gallery
                  if (event.photos.length > 1) ...[
                    Text(
                      'Photos',
                      style: KolabingTextStyles.titleMedium.copyWith(
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    _buildPhotoGrid(event),
                  ],

                  const SizedBox(height: KolabingSpacing.xl),

                  // Delete Button
                  OutlinedButton.icon(
                    onPressed: () => _handleDelete(event),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: const Text('DELETE EVENT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KolabingColors.error,
                      side: const BorderSide(color: KolabingColors.error),
                      padding: const EdgeInsets.symmetric(
                        vertical: KolabingSpacing.sm,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: KolabingSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Event event) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: KolabingColors.surface,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Photo Carousel
            PageView.builder(
              controller: _pageController,
              itemCount: event.photos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = event.photos[index];
                return Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: KolabingColors.surfaceVariant,
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Page Indicator
            if (event.photos.length > 1)
              Positioned(
                bottom: KolabingSpacing.md,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    event.photos.length,
                    (index) => Container(
                      width: _currentPhotoIndex == index ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _currentPhotoIndex == index
                            ? KolabingColors.primary
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Event event) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Partner
          _buildInfoRow(
            icon: LucideIcons.users,
            label: 'Collaborated with',
            child: Row(
              children: [
                // Partner avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KolabingColors.border,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: event.partner.profilePhoto != null
                        ? Image.network(
                            event.partner.profilePhoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPartnerPlaceholder(event.partner.name),
                          )
                        : _buildPartnerPlaceholder(event.partner.name),
                  ),
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.partner.name,
                        style: KolabingTextStyles.titleSmall.copyWith(
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KolabingSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: event.partner.type == PartnerType.business
                              ? KolabingColors.softYellow
                              : KolabingColors.info.withValues(alpha: 0.1),
                          borderRadius: KolabingRadius.borderRadiusSm,
                        ),
                        child: Text(
                          event.partner.type.name.toUpperCase(),
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: event.partner.type == PartnerType.business
                                ? KolabingColors.accentOrangeText
                                : KolabingColors.info,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: KolabingSpacing.lg, color: KolabingColors.border),

          // Date
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: 'Event Date',
            value: event.formattedDate,
          ),

          const Divider(height: KolabingSpacing.lg, color: KolabingColors.border),

          // Attendees
          _buildInfoRow(
            icon: LucideIcons.userCheck,
            label: 'Attendees',
            value: '${event.attendeeCount} people',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: KolabingColors.primary.withValues(alpha: 0.1),
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
          child: Icon(
            icon,
            size: 20,
            color: KolabingColors.primary,
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: KolabingTextStyles.labelSmall.copyWith(
                  color: KolabingColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              if (child != null)
                child
              else if (value != null)
                Text(
                  value,
                  style: KolabingTextStyles.titleSmall.copyWith(
                    color: KolabingColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerPlaceholder(String name) => Container(
        color: KolabingColors.primary,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(
              color: KolabingColors.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

  Widget _buildPhotoGrid(Event event) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: KolabingSpacing.xs,
        crossAxisSpacing: KolabingSpacing.xs,
        childAspectRatio: 1,
      ),
      itemCount: event.photos.length,
      itemBuilder: (context, index) {
        final photo = event.photos[index];
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(
                color: _currentPhotoIndex == index
                    ? KolabingColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: KolabingRadius.borderRadiusSm,
              child: Image.network(
                photo.thumbnailUrl ?? photo.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: KolabingColors.surfaceVariant,
                  child: const Icon(
                    LucideIcons.image,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
