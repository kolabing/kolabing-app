import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../enums/intent_type.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 6 (venue / product flows): Review & Publish
///
/// Shows a summary of all entered data, grouped by section. Each section is
/// tappable and navigates back to the corresponding step via
/// `notifier.goToStep(stepIndex)`.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final notifier = ref.read(kolabFormProvider.notifier);
    final isVenue = formState.intentType == IntentType.venuePromotion;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          'REVIEW & PUBLISH',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Tap any section below to edit',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textTertiary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // -- Step 0: Venue or Product details
        if (isVenue)
          _ReviewSection(
            title: 'Campaign & Venue',
            icon: LucideIcons.building2,
            onTap: () => notifier.goToStep(0),
            rows: [
              _ReviewRow(
                'Title',
                kolab.title.isNotEmpty ? kolab.title : '-',
              ),
              _ReviewRow('Venue', kolab.venueName ?? '-'),
              _ReviewRow(
                'Type',
                kolab.venueType?.displayName ?? '-',
              ),
              _ReviewRow(
                'Description',
                kolab.description.isNotEmpty ? kolab.description : '-',
              ),
              _ReviewRow(
                'Capacity',
                kolab.capacity?.toString() ?? '-',
              ),
              _ReviewRow('Address', kolab.venueAddress ?? '-'),
              _ReviewRow(
                'City',
                kolab.preferredCity.isNotEmpty
                    ? kolab.preferredCity
                    : '-',
              ),
            ],
          )
        else
          _ReviewSection(
            title: 'Product Details',
            // ignore: deprecated_member_use
            icon: LucideIcons.package,
            onTap: () => notifier.goToStep(0),
            rows: [
              _ReviewRow(
                'Title',
                kolab.title.isNotEmpty ? kolab.title : '-',
              ),
              _ReviewRow('Name', kolab.productName ?? '-'),
              _ReviewRow(
                'Type',
                kolab.productType?.displayName ?? '-',
              ),
              _ReviewRow(
                'Description',
                kolab.description.isNotEmpty ? kolab.description : '-',
              ),
              _ReviewRow(
                'City',
                kolab.preferredCity.isNotEmpty
                    ? kolab.preferredCity
                    : '-',
              ),
            ],
          ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Step 1: Media
        _ReviewSection(
          title: 'Media',
          icon: LucideIcons.image,
          onTap: () => notifier.goToStep(1),
          rows: [
            _ReviewRow(
              'Photos',
              '${kolab.media.where((m) => m.type == 'photo').length} photo(s)',
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Step 2: Offering
        _ReviewSection(
          title: 'Offering',
          icon: LucideIcons.gift,
          onTap: () => notifier.goToStep(2),
          rows: [
            _ReviewRow(
              'Items',
              kolab.offering.isNotEmpty
                  ? _formatOfferingList(kolab.offering)
                  : '-',
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Step 3: Ideal Community
        _ReviewSection(
          title: 'Ideal Community',
          icon: LucideIcons.users,
          onTap: () => notifier.goToStep(3),
          rows: [
            _ReviewRow(
              'Types',
              kolab.seekingCommunities.isNotEmpty
                  ? kolab.seekingCommunities.join(', ')
                  : '-',
            ),
            _ReviewRow(
              'Min Size',
              kolab.minCommunitySize != null
                  ? kolab.minCommunitySize.toString()
                  : 'Not set',
            ),
            _ReviewRow(
              'Expects',
              kolab.expects.isNotEmpty
                  ? kolab.expects.map((e) => e.displayName).join(', ')
                  : '-',
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Step 4: Past Events
        _ReviewSection(
          title: 'Past Collaborations',
          icon: LucideIcons.history,
          onTap: () => notifier.goToStep(4),
          rows: [
            _ReviewRow(
              'Events',
              kolab.pastEvents.isNotEmpty
                  ? '${kolab.pastEvents.length} event(s)'
                  : 'None',
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Step 5: Availability
        _ReviewSection(
          title: 'Availability',
          icon: LucideIcons.calendar,
          onTap: () => notifier.goToStep(5),
          rows: [
            _ReviewRow(
              'Mode',
              kolab.availabilityMode?.displayName ?? '-',
            ),
            if (kolab.availabilityStart != null &&
                kolab.availabilityEnd != null)
              _ReviewRow(
                'Dates',
                '${DateFormat('MMM d').format(kolab.availabilityStart!)} - ${DateFormat('MMM d, yyyy').format(kolab.availabilityEnd!)}',
              ),
            if (kolab.selectedTime != null)
              _ReviewRow(
                'Time',
                '${kolab.selectedTime!.hour.toString().padLeft(2, '0')}:${kolab.selectedTime!.minute.toString().padLeft(2, '0')}',
              ),
            if (kolab.recurringDays.isNotEmpty)
              _ReviewRow(
                'Days',
                _formatDays(kolab.recurringDays),
              ),
          ],
        ),

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Formatters
  // ---------------------------------------------------------------------------

  static String _formatOfferingList(List<String> items) {
    const labels = <String, String>{
      'venue': 'Venue',
      'food_drink': 'Food & Drink',
      'discount': 'Discount',
      'products': 'Products / Samples',
      'social_media': 'Social Media Exposure',
      'content_creation': 'Content Creation',
      'sponsorship': 'Sponsorship',
      'other': 'Other',
    };
    return items.map((i) => labels[i] ?? i).join(', ');
  }

  static String _formatDays(List<int> days) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days
        .where((d) => d >= 1 && d <= 7)
        .map((d) => names[d - 1])
        .join(', ');
  }
}

// =============================================================================
// Review Section Card
// =============================================================================

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<_ReviewRow> rows;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: KolabingColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: KolabingColors.textSecondary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: KolabingColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.sm),

            // Rows
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: KolabingSpacing.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          row.label,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.value,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.textPrimary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
}

// =============================================================================
// Simple label-value row data class
// =============================================================================

class _ReviewRow {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;
}
