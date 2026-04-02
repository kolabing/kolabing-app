import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../opportunity/models/opportunity.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 5: Review & Publish
///
/// Shows a full summary of the kolab data. Each section is tappable and
/// navigates back to the corresponding step for editing.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;
    final dateFormat = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'REVIEW & PUBLISH',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Make sure everything looks correct before publishing',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Main review card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KolabingSpacing.md),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusLg,
              border: Border.all(color: KolabingColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------
                // Title & Description (tap -> step 2)
                // -------------------------------------------------------
                _buildTappableSection(
                  ref: ref,
                  step: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kolab.title.isEmpty
                            ? 'Untitled Kolab'
                            : kolab.title,
                        style: GoogleFonts.rubik(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      Text(
                        kolab.description.isEmpty
                            ? 'No description provided'
                            : kolab.description,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Looking for (needs) -> step 0
                // -------------------------------------------------------
                _buildTappableSection(
                  ref: ref,
                  step: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel('Looking for'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.needs.isEmpty)
                        Text(
                          'No needs selected',
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.textTertiary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xs,
                          children: kolab.needs.map((need) {
                            return _buildChip(need.displayName);
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Offering in return -> step 2
                // -------------------------------------------------------
                _buildTappableSection(
                  ref: ref,
                  step: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel('Offering'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.offersInReturn.isEmpty)
                        Text(
                          'No deliverables selected',
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.textTertiary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xs,
                          children: kolab.offersInReturn.map((d) {
                            return _buildChip(d.displayName);
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Community info -> step 1
                // -------------------------------------------------------
                _buildTappableSection(
                  ref: ref,
                  step: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel('Community'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.communityTypes.isNotEmpty) ...[
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xs,
                          children: kolab.communityTypes
                              .map(_buildChip)
                              .toList(),
                        ),
                        const SizedBox(height: KolabingSpacing.xs),
                      ],
                      _buildReviewInfoRow(
                        LucideIcons.users,
                        'Community size: ${kolab.communitySize ?? '--'}',
                      ),
                      const SizedBox(height: KolabingSpacing.xxs),
                      _buildReviewInfoRow(
                        LucideIcons.userCheck,
                        'Expected attendees: ${kolab.typicalAttendance ?? '--'}',
                      ),
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Location -> step 3
                // -------------------------------------------------------
                _buildTappableSection(
                  ref: ref,
                  step: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel('Location'),
                      const SizedBox(height: KolabingSpacing.xs),
                      _buildReviewInfoRow(
                        LucideIcons.mapPin,
                        kolab.preferredCity.isNotEmpty
                            ? kolab.preferredCity
                            : 'No city selected',
                      ),
                      if (kolab.area != null &&
                          kolab.area!.isNotEmpty) ...[
                        const SizedBox(height: KolabingSpacing.xxs),
                        _buildReviewInfoRow(
                          LucideIcons.navigation,
                          kolab.area!,
                        ),
                      ],
                      if (kolab.venuePreference != null) ...[
                        const SizedBox(height: KolabingSpacing.xxs),
                        _buildReviewInfoRow(
                          LucideIcons.building2,
                          kolab.venuePreference!.displayName,
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Availability -> step 3
                // -------------------------------------------------------
                _buildTappableSection(
                  ref: ref,
                  step: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel('Availability'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.availabilityMode != null) ...[
                        _buildReviewInfoRow(
                          _availabilityModeIcon(kolab.availabilityMode!),
                          kolab.availabilityMode!.displayName,
                        ),
                        const SizedBox(height: KolabingSpacing.xxs),
                        if (kolab.availabilityMode ==
                            AvailabilityMode.recurring) ...[
                          _buildReviewInfoRow(
                            LucideIcons.calendar,
                            'Every ${kolab.recurringDays.isNotEmpty ? kolab.recurringDays.map((d) => _dayNames[d - 1]).join(', ') : '--'}'
                            '${kolab.selectedTime != null ? ' at ${kolab.selectedTime!.format(context)}' : ''}',
                          ),
                        ] else ...[
                          _buildReviewInfoRow(
                            LucideIcons.calendar,
                            '${kolab.availabilityStart != null ? dateFormat.format(kolab.availabilityStart!) : '--'}'
                            ' -- '
                            '${kolab.availabilityEnd != null ? dateFormat.format(kolab.availabilityEnd!) : '--'}'
                            '${kolab.availabilityMode == AvailabilityMode.oneTime && kolab.selectedTime != null ? ' at ${kolab.selectedTime!.format(context)}' : ''}',
                          ),
                        ],
                      ] else
                        Text(
                          'Not set',
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Hint text
          Center(
            child: Text(
              'Tap any section above to edit',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildTappableSection({
    required WidgetRef ref,
    required int step,
    required Widget child,
  }) {
    return InkWell(
      onTap: () => ref.read(kolabFormProvider.notifier).goToStep(step),
      borderRadius: KolabingRadius.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            const SizedBox(width: KolabingSpacing.xs),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                LucideIcons.pencil,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewLabel(String label) => Text(
        label.toUpperCase(),
        style: GoogleFonts.rubik(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: KolabingColors.textTertiary,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildReviewInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KolabingColors.textSecondary),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.softYellow,
        borderRadius: KolabingRadius.borderRadiusSm,
        border: Border.all(
          color: KolabingColors.softYellowBorder,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: KolabingColors.textPrimary,
        ),
      ),
    );
  }

  IconData _availabilityModeIcon(AvailabilityMode mode) {
    switch (mode) {
      case AvailabilityMode.oneTime:
        return LucideIcons.calendarCheck;
      case AvailabilityMode.recurring:
        return LucideIcons.repeat;
      case AvailabilityMode.flexible:
        return LucideIcons.calendarRange;
    }
  }
}
