import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
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
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Make sure everything looks correct before publishing',
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Main review card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KolabingSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: KolabingRadius.borderRadiusLg,
              border: Border.all(color: context.colors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------
                // Title & Description (tap -> step 2)
                // -------------------------------------------------------
                _buildTappableSection(
                  context,
                  ref: ref,
                  step: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kolab.title.isEmpty ? 'Untitled Kolab' : kolab.title,
                        style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: context.colors.onSurface),
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      Text(
                        kolab.description.isEmpty
                            ? 'No description provided'
                            : kolab.description,
                        style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant, height: 1.5),
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
                  context,
                  ref: ref,
                  step: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel(context, 'Looking for'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.needs.isEmpty)
                        Text(
                          'No needs selected',
                          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.textTertiary),
                        )
                      else
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xs,
                          children: kolab.needs
                              .map((need) => _buildChip(context, need.displayName))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Offering in return -> step 2
                // -------------------------------------------------------
                _buildTappableSection(
                  context,
                  ref: ref,
                  step: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel(context, 'Offering'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.offersInReturn.isEmpty)
                        Text(
                          'No deliverables selected',
                          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.textTertiary),
                        )
                      else
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xs,
                          children: kolab.offersInReturn
                              .map((d) => _buildChip(context, d.displayName))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const Divider(height: KolabingSpacing.lg),

                // -------------------------------------------------------
                // Community info -> step 1
                // -------------------------------------------------------
                _buildTappableSection(
                  context,
                  ref: ref,
                  step: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel(context, 'Community'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.communityTypes.isNotEmpty) ...[
                        Wrap(
                          spacing: KolabingSpacing.xs,
                          runSpacing: KolabingSpacing.xs,
                          children: kolab.communityTypeLabels
                              .map((label) => _buildChip(context, label))
                              .toList(),
                        ),
                        const SizedBox(height: KolabingSpacing.xs),
                      ],
                      _buildReviewInfoRow(
                        context,
                        LucideIcons.users,
                        'Community size: ${kolab.communitySize ?? '--'}',
                      ),
                      const SizedBox(height: KolabingSpacing.xxs),
                      _buildReviewInfoRow(
                        context,
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
                  context,
                  ref: ref,
                  step: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel(context, 'Location'),
                      const SizedBox(height: KolabingSpacing.xs),
                      _buildReviewInfoRow(
                        context,
                        LucideIcons.mapPin,
                        kolab.preferredCity.isNotEmpty
                            ? kolab.preferredCity
                            : 'No city selected',
                      ),
                      if (kolab.area != null && kolab.area!.isNotEmpty) ...[
                        const SizedBox(height: KolabingSpacing.xxs),
                        _buildReviewInfoRow(
                        context,
                          LucideIcons.navigation,
                          kolab.area!,
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
                  context,
                  ref: ref,
                  step: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewLabel(context, 'Availability'),
                      const SizedBox(height: KolabingSpacing.xs),
                      if (kolab.availabilityMode != null) ...[
                        _buildReviewInfoRow(
                        context,
                          _availabilityModeIcon(kolab.availabilityMode!),
                          kolab.availabilityMode!.displayName,
                        ),
                        const SizedBox(height: KolabingSpacing.xxs),
                        if (kolab.availabilityMode ==
                            AvailabilityMode.recurring) ...[
                          _buildReviewInfoRow(
                        context,
                            LucideIcons.calendar,
                            'Every ${kolab.recurringDays.isNotEmpty ? kolab.recurringDays.map((d) => _dayNames[d - 1]).join(', ') : '--'}'
                            '${kolab.selectedTime != null ? ' at ${kolab.selectedTime!.format(context)}' : ''}',
                          ),
                        ] else ...[
                          _buildReviewInfoRow(
                        context,
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
                          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.textTertiary),
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
              style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.textTertiary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildTappableSection(
    BuildContext context, {
    required WidgetRef ref,
    required int step,
    required Widget child,
  }) => InkWell(
    onTap: () => ref.read(kolabFormProvider.notifier).goToStep(step),
    borderRadius: KolabingRadius.borderRadiusSm,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          const SizedBox(width: KolabingSpacing.xs),
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.pencil,
              size: 16,
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildReviewLabel(BuildContext context, String label) => Text(
    label.toUpperCase(),
    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textTertiary, letterSpacing: 0.8),
  );

  Widget _buildReviewInfoRow(BuildContext context, IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
      const SizedBox(width: KolabingSpacing.xs),
      Expanded(
        child: Text(
          label,
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ),
    ],
  );

  Widget _buildChip(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.xs,
      vertical: KolabingSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: context.colors.softYellow,
      borderRadius: KolabingRadius.borderRadiusSm,
      border: Border.all(color: context.colors.softYellowBorder),
    ),
    child: Text(
      label,
      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.onSurface),
    ),
  );

  IconData _availabilityModeIcon(AvailabilityMode mode) {
    switch (mode) {
      case AvailabilityMode.oneTime:
        return LucideIcons.calendarCheck;
      case AvailabilityMode.recurring:
        return LucideIcons.repeat;
    }
  }
}
