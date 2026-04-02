import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../widgets/time_picker.dart';
import '../../../opportunity/models/opportunity.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 5 (venue / product flows): "AVAILABILITY"
///
/// Same pattern as the community logistics screen but WITHOUT a location
/// section. Offers three availability modes: One Time, Recurring, Flexible.
/// Conditional sub-fields: date range picker, time picker, day selector.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  Future<void> _pickDateRange(KolabFormNotifier notifier, Kolab kolab) async {
    final now = DateTime.now();
    final initialStart = kolab.availabilityStart ?? now;
    final initialEnd =
        kolab.availabilityEnd ?? now.add(const Duration(days: 30));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd,
      ),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: KolabingColors.primary,
                  onPrimary: KolabingColors.onPrimary,
                ),
          ),
          child: child!,
        ),
    );

    if (picked != null) {
      notifier
        ..updateAvailabilityStart(picked.start)
        ..updateAvailabilityEnd(picked.end);
    }
  }

  Future<void> _pickTime(KolabFormNotifier notifier, Kolab kolab) async {
    final initial =
        kolab.selectedTime ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await KolabingTimePicker.show(
      context,
      initialTime: initial,
    );
    if (picked != null) {
      notifier.updateSelectedTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        // -- Section header
        Text(
          'AVAILABILITY',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Error
        if (errors.containsKey('availability_mode'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['availability_mode']!,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.error,
              ),
            ),
          ),

        // -- Mode cards
        ...AvailabilityMode.values.map((mode) {
          final isSelected = kolab.availabilityMode == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: _ModeCard(
              title: mode.displayName,
              subtitle: mode.description,
              icon: _iconForMode(mode),
              isSelected: isSelected,
              onTap: () => notifier.updateAvailabilityMode(mode),
            ),
          );
        }),
        const SizedBox(height: KolabingSpacing.md),

        // -- Conditional sub-fields
        if (kolab.availabilityMode == AvailabilityMode.oneTime) ...[
          _buildDateRangeSection(kolab, notifier),
          const SizedBox(height: KolabingSpacing.md),
          _buildTimeSection(kolab, notifier),
        ],

        if (kolab.availabilityMode == AvailabilityMode.recurring) ...[
          _buildDaySelector(kolab, notifier),
          const SizedBox(height: KolabingSpacing.md),
          _buildTimeSection(kolab, notifier),
          const SizedBox(height: KolabingSpacing.md),
          _buildDateRangeSection(kolab, notifier),
        ],

        if (kolab.availabilityMode == AvailabilityMode.flexible)
          Padding(
            padding: const EdgeInsets.only(top: KolabingSpacing.xs),
            child: Container(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: KolabingColors.softYellow,
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 20,
                    color: KolabingColors.textSecondary,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Text(
                      'Communities will propose a time and you can accept or suggest an alternative.',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: KolabingColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-section builders
  // ---------------------------------------------------------------------------

  Widget _buildDateRangeSection(Kolab kolab, KolabFormNotifier notifier) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasRange =
        kolab.availabilityStart != null && kolab.availabilityEnd != null;
    final rangeText = hasRange
        ? '${dateFormat.format(kolab.availabilityStart!)} - ${dateFormat.format(kolab.availabilityEnd!)}'
        : 'Select date range';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE RANGE',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        GestureDetector(
          onTap: () => _pickDateRange(notifier, kolab),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(color: KolabingColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rangeText,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: hasRange
                          ? KolabingColors.textPrimary
                          : KolabingColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: KolabingColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(Kolab kolab, KolabFormNotifier notifier) {
    final hasTime = kolab.selectedTime != null;
    final timeText = hasTime
        ? '${kolab.selectedTime!.hour.toString().padLeft(2, '0')}:${kolab.selectedTime!.minute.toString().padLeft(2, '0')}'
        : 'Select time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERRED TIME',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        GestureDetector(
          onTap: () => _pickTime(notifier, kolab),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(color: KolabingColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    timeText,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: hasTime
                          ? KolabingColors.textPrimary
                          : KolabingColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.clock,
                  size: 18,
                  color: KolabingColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(Kolab kolab, KolabFormNotifier notifier) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECURRING DAYS',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = index + 1; // 1=Monday .. 7=Sunday
            final isSelected = kolab.recurringDays.contains(day);
            return GestureDetector(
              onTap: () => notifier.toggleRecurringDay(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.surface,
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected
                        ? KolabingColors.primary
                        : KolabingColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    _dayLabels[index],
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );

  IconData _iconForMode(AvailabilityMode mode) {
    switch (mode) {
      case AvailabilityMode.oneTime:
        return LucideIcons.calendarCheck;
      case AvailabilityMode.recurring:
        return LucideIcons.repeat;
      case AvailabilityMode.flexible:
        return LucideIcons.clock;
    }
  }
}

// =============================================================================
// Mode Card
// =============================================================================

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color:
              isSelected ? KolabingColors.softYellow : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color:
                isSelected ? KolabingColors.primary : KolabingColors.border,
          ),
        ),
        child: Row(
          children: [
            // Radio-like indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? KolabingColors.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: KolabingColors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Icon
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? KolabingColors.textPrimary
                  : KolabingColors.textSecondary,
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
