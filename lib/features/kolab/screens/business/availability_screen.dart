import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../../widgets/time_picker.dart';
import '../../../opportunity/models/opportunity.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 5 (venue / product flows): "AVAILABILITY"
///
/// Same pattern as the community logistics screen but WITHOUT a location
/// section. Offers two availability modes: One Time and Recurring.
/// Conditional sub-fields: date range picker, time picker, day selector.
///
/// This is a plain widget -- the parent provides Scaffold, AppBar, step
/// indicator, and action bar.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
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
    final today = DateUtils.dateOnly(DateTime.now());
    final firstAllowedDate = today;
    final initialStart =
        kolab.availabilityStart != null &&
            !DateUtils.dateOnly(
              kolab.availabilityStart!,
            ).isBefore(firstAllowedDate)
        ? kolab.availabilityStart!
        : firstAllowedDate;
    final initialEnd =
        kolab.availabilityEnd != null &&
            !DateUtils.dateOnly(kolab.availabilityEnd!).isBefore(initialStart)
        ? kolab.availabilityEnd!
        : initialStart.add(const Duration(days: 30));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstAllowedDate,
      lastDate: firstAllowedDate.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: context.colors.primary,
            onPrimary: context.colors.onPrimary,
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
    final initial = kolab.selectedTime ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await KolabingTimePicker.show(context, initialTime: initial);
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
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // -- Error
        if (errors.containsKey('availability_mode'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['availability_mode']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
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
          _buildDateRangeSection(kolab, notifier, errors),
          const SizedBox(height: KolabingSpacing.md),
          _buildTimeSection(kolab, notifier),
        ],

        if (kolab.availabilityMode == AvailabilityMode.recurring) ...[
          _buildDaySelector(kolab, notifier),
          const SizedBox(height: KolabingSpacing.md),
          _buildTimeSection(kolab, notifier),
          const SizedBox(height: KolabingSpacing.md),
          _buildDateRangeSection(kolab, notifier, errors),
        ],

        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-section builders
  // ---------------------------------------------------------------------------

  Widget _buildDateRangeSection(
    Kolab kolab,
    KolabFormNotifier notifier,
    Map<String, String> errors,
  ) {
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
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: TextEditingController(text: hasRange ? rangeText : ''),
          readOnly: true,
          hint: hasRange ? null : rangeText,
          onTap: () => _pickDateRange(notifier, kolab),
          suffix: Icon(
            LucideIcons.calendar,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (errors['availability_start'] != null)
          Padding(
            padding: const EdgeInsets.only(top: KolabingSpacing.xs),
            child: Text(
              errors['availability_start']!,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
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
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        KolabingInput(
          controller: TextEditingController(text: hasTime ? timeText : ''),
          readOnly: true,
          hint: hasTime ? null : timeText,
          onTap: () => _pickTime(notifier, kolab),
          suffix: Icon(
            LucideIcons.clock,
            size: 18,
            color: context.colors.onSurfaceVariant,
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
        style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
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
                    ? context.colors.primary
                    : context.colors.surface,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.darkBorder,
                ),
              ),
              child: Center(
                child: Text(
                  _dayLabels[index],
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected
                        ? context.colors.onPrimary
                        : context.colors.onSurface),
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
        color: isSelected ? context.colors.softYellow : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.darkBorder,
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
              color: isSelected ? context.colors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.darkBorder,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Icon(
                    LucideIcons.check,
                    size: 14,
                    color: context.colors.onPrimary,
                  )
                : null,
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Icon
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? context.colors.onSurface
                : context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
