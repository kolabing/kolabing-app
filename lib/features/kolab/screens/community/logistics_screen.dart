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
import '../../../opportunity/providers/opportunity_provider.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 3: "AVAILABILITY" + "LOCATION"
///
/// Lets the user select availability mode (one-time, recurring, flexible),
/// dates/times, venue preference, city, and optional area.
class LogisticsScreen extends ConsumerStatefulWidget {
  const LogisticsScreen({super.key});

  @override
  ConsumerState<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends ConsumerState<LogisticsScreen> {
  final _areaController = TextEditingController();

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers();
    });
  }

  void _syncControllers() {
    final kolab = ref.read(kolabFormProvider).kolab;
    final areaText = kolab.area ?? '';
    if (_areaController.text != areaText) {
      _areaController.text = areaText;
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kolabFormProvider);
    final kolab = state.kolab;
    final citiesAsync = ref.watch(citiesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------------
          // AVAILABILITY SECTION
          // ---------------------------------------------------------------
          _buildSectionHeader('AVAILABILITY'),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'When is your community available for this kolab?',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
          ),

          if (state.fieldErrors['availability_mode'] != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildFieldError(state.fieldErrors['availability_mode']!),
          ],

          const SizedBox(height: KolabingSpacing.md),

          // 3 availability mode cards
          Row(
            children: AvailabilityMode.values.map((mode) {
              final isSelected = kolab.availabilityMode == mode;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: mode != AvailabilityMode.values.last
                        ? KolabingSpacing.xs
                        : 0,
                  ),
                  child: _buildSelectionCard(
                    icon: _availabilityModeIcon(mode),
                    title: mode.displayName,
                    description: mode.description,
                    isSelected: isSelected,
                    onTap: () => ref
                        .read(kolabFormProvider.notifier)
                        .updateAvailabilityMode(mode),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Mode-specific fields
          if (kolab.availabilityMode != null)
            ..._buildAvailabilityFields(kolab, state),

          const SizedBox(height: KolabingSpacing.lg),

          // ---------------------------------------------------------------
          // LOCATION SECTION
          // ---------------------------------------------------------------
          _buildSectionHeader('LOCATION'),
          const SizedBox(height: KolabingSpacing.md),

          // Venue preference cards
          _buildLabel('Venue Preference'),
          const SizedBox(height: KolabingSpacing.xs),
          Row(
            children: VenuePreference.values.map((pref) {
              final isSelected = kolab.venuePreference == pref;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: pref != VenuePreference.values.last
                        ? KolabingSpacing.xs
                        : 0,
                  ),
                  child: _buildSelectionCard(
                    icon: _venuePreferenceIcon(pref),
                    title: pref.displayName,
                    description: pref.description,
                    isSelected: isSelected,
                    onTap: () => ref
                        .read(kolabFormProvider.notifier)
                        .updateVenuePreference(pref),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // City dropdown
          _buildLabel('Preferred City'),
          const SizedBox(height: KolabingSpacing.xxs),
          if (state.fieldErrors['preferred_city'] != null) ...[
            _buildFieldError(state.fieldErrors['preferred_city']!),
            const SizedBox(height: KolabingSpacing.xxs),
          ],
          citiesAsync.when(
            loading: () => const LinearProgressIndicator(
              color: KolabingColors.primary,
              backgroundColor: KolabingColors.border,
            ),
            error: (e, _) => Text(
              'Error loading cities: $e',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.error,
              ),
            ),
            data: (cities) => DropdownButtonFormField<String>(
              value: kolab.preferredCity.isNotEmpty
                  ? kolab.preferredCity
                  : null,
              decoration: _inputDecoration(hint: 'Select city'),
              items: cities
                  .map((city) => DropdownMenuItem(
                        value: city.name,
                        child: Text(city.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(kolabFormProvider.notifier)
                      .updatePreferredCity(value);
                }
              },
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Preferred Area (optional)
          _buildLabel('Preferred Area (optional)'),
          const SizedBox(height: KolabingSpacing.xxs),
          TextFormField(
            controller: _areaController,
            onChanged: (value) => ref
                .read(kolabFormProvider.notifier)
                .updateArea(value.isEmpty ? null : value),
            style: GoogleFonts.openSans(
              fontSize: 15,
              color: KolabingColors.textPrimary,
            ),
            decoration: _inputDecoration(
              hint: 'e.g., Shoreditch, Kreuzberg',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Availability mode-specific fields
  // ---------------------------------------------------------------------------

  List<Widget> _buildAvailabilityFields(
    Kolab kolab,
    KolabFormState formState,
  ) {
    switch (kolab.availabilityMode!) {
      case AvailabilityMode.oneTime:
        return _buildOneTimeFields(kolab, formState);
      case AvailabilityMode.recurring:
        return _buildRecurringFields(kolab, formState);
      case AvailabilityMode.flexible:
        return _buildFlexibleFields(kolab, formState);
    }
  }

  List<Widget> _buildOneTimeFields(Kolab kolab, KolabFormState formState) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildDatePicker(
              label: 'Available From',
              value: kolab.availabilityStart,
              error: formState.fieldErrors['availability_start'],
              onChanged: (date) => ref
                  .read(kolabFormProvider.notifier)
                  .updateAvailabilityStart(date),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: _buildDatePicker(
              label: 'Available Until',
              value: kolab.availabilityEnd,
              error: formState.fieldErrors['availability_end'],
              minDate: kolab.availabilityStart,
              onChanged: (date) => ref
                  .read(kolabFormProvider.notifier)
                  .updateAvailabilityEnd(date),
            ),
          ),
        ],
      ),
      const SizedBox(height: KolabingSpacing.sm),
      _buildTimePicker(
        label: 'Time',
        value: kolab.selectedTime,
        error: formState.fieldErrors['selected_time'],
        onChanged: (time) =>
            ref.read(kolabFormProvider.notifier).updateSelectedTime(time),
      ),
    ];
  }

  List<Widget> _buildRecurringFields(Kolab kolab, KolabFormState formState) {
    return [
      _buildLabel('Day of Week'),
      const SizedBox(height: KolabingSpacing.xxs),
      if (formState.fieldErrors['recurring_day'] != null) ...[
        _buildFieldError(formState.fieldErrors['recurring_day']!),
        const SizedBox(height: KolabingSpacing.xxs),
      ],
      Row(
        children: List.generate(7, (i) {
          final dayIndex = i + 1;
          final isSelected = kolab.recurringDays.contains(dayIndex);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
              child: GestureDetector(
                onTap: () => ref
                    .read(kolabFormProvider.notifier)
                    .toggleRecurringDay(dayIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KolabingColors.softYellow
                        : KolabingColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? KolabingColors.primary
                          : KolabingColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _dayNames[i].substring(0, 3),
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? KolabingColors.textPrimary
                          : KolabingColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: KolabingSpacing.sm),
      _buildTimePicker(
        label: 'Time',
        value: kolab.selectedTime,
        error: formState.fieldErrors['selected_time'],
        onChanged: (time) =>
            ref.read(kolabFormProvider.notifier).updateSelectedTime(time),
      ),
    ];
  }

  List<Widget> _buildFlexibleFields(Kolab kolab, KolabFormState formState) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildDatePicker(
              label: 'Available From',
              value: kolab.availabilityStart,
              error: formState.fieldErrors['availability_start'],
              onChanged: (date) => ref
                  .read(kolabFormProvider.notifier)
                  .updateAvailabilityStart(date),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: _buildDatePicker(
              label: 'Available Until',
              value: kolab.availabilityEnd,
              error: formState.fieldErrors['availability_end'],
              minDate: kolab.availabilityStart,
              onChanged: (date) => ref
                  .read(kolabFormProvider.notifier)
                  .updateAvailabilityEnd(date),
            ),
          ),
        ],
      ),
      const SizedBox(height: KolabingSpacing.sm),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow.withValues(alpha: 0.5),
          borderRadius: KolabingRadius.borderRadiusMd,
          border:
              Border.all(color: KolabingColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.clock,
              size: 16,
              color: KolabingColors.textSecondary,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              'Time: Flexible -- no fixed time',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        'Businesses will propose a specific date and time within this window.',
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: KolabingColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Reusable sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? KolabingColors.softYellow
              : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected ? KolabingColors.primary : KolabingColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? KolabingColors.primary
                  : KolabingColors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              title,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: GoogleFonts.openSans(
                fontSize: 10,
                color: KolabingColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    String? error,
    DateTime? minDate,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final displayDate = value ?? DateTime.now().add(const Duration(days: 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: KolabingSpacing.xxs),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: displayDate,
              firstDate: minDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: KolabingColors.primary,
                    onPrimary: KolabingColors.onPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color:
                    error != null ? KolabingColors.error : KolabingColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    value != null
                        ? dateFormat.format(value)
                        : 'Select date',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: value != null
                          ? KolabingColors.textPrimary
                          : KolabingColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay?> onChanged,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: KolabingSpacing.xxs),
        GestureDetector(
          onTap: () async {
            final picked = await KolabingTimePicker.show(
              context,
              initialTime: value ?? const TimeOfDay(hour: 10, minute: 0),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color:
                    error != null ? KolabingColors.error : KolabingColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 18,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  value != null ? value.format(context) : 'Select time',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: value != null
                        ? KolabingColors.textPrimary
                        : KolabingColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.error,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(
        color: KolabingColors.textTertiary,
      ),
      filled: true,
      fillColor: KolabingColors.surface,
      border: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide: const BorderSide(color: KolabingColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusSm,
        borderSide:
            const BorderSide(color: KolabingColors.primary, width: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: GoogleFonts.rubik(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: KolabingColors.textSecondary,
          letterSpacing: 1.0,
        ),
      );

  Widget _buildLabel(String label) => Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KolabingColors.textPrimary,
        ),
      );

  Widget _buildFieldError(String error) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.errorBg,
          borderRadius: KolabingRadius.borderRadiusSm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 14,
              color: KolabingColors.error,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                error,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.error,
                ),
              ),
            ),
          ],
        ),
      );

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

  IconData _venuePreferenceIcon(VenuePreference pref) {
    switch (pref) {
      case VenuePreference.businessProvides:
        return LucideIcons.store;
      case VenuePreference.communityProvides:
        return LucideIcons.users;
      case VenuePreference.noVenue:
        return LucideIcons.globe;
    }
  }
}
