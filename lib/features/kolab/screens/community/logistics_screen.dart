import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../widgets/kolabing_input.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/time_picker.dart';
import '../../../onboarding/models/place_suggestion.dart';
// Only the Places autocomplete provider is needed here. Hide the names that
// also exist in opportunity_provider (e.g. citiesProvider) to avoid an
// ambiguous import; the city dropdown keeps using opportunity_provider's.
import '../../../onboarding/providers/onboarding_provider.dart'
    show placeSuggestionsProvider;
import '../../../opportunity/models/opportunity.dart';
import '../../../opportunity/providers/opportunity_provider.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Community step 3: "AVAILABILITY" + "LOCATION"
///
/// Lets the user select availability mode (one-time or recurring),
/// dates/times, city, and optional area.
class LogisticsScreen extends ConsumerStatefulWidget {
  const LogisticsScreen({super.key});

  @override
  ConsumerState<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends ConsumerState<LogisticsScreen> {
  final _areaController = TextEditingController();
  final _areaFocusNode = FocusNode();

  /// Live query text driving the neighbourhood/area Places autocomplete.
  /// Kept separate from the persisted `kolab.area` so suggestions only show
  /// while the user is actively typing a new search.
  String _areaQuery = '';

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
    // Hide the suggestion list once the field loses focus so a confirmed
    // selection (or manual entry) stays put without a dangling dropdown.
    _areaFocusNode.addListener(() {
      if (!_areaFocusNode.hasFocus && _areaQuery.isNotEmpty) {
        setState(() => _areaQuery = '');
      }
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
    _areaFocusNode.dispose();
    super.dispose();
  }

  /// Persist a Places suggestion as the preferred neighbourhood/area.
  ///
  /// We store the place title (e.g. "Shoreditch") rather than the full
  /// formatted address so the area reads naturally alongside the city.
  void _selectAreaSuggestion(PlaceSuggestion place) {
    final label = place.title.trim().isNotEmpty
        ? place.title.trim()
        : place.formattedAddress.trim();
    _areaController.text = label;
    ref
        .read(kolabFormProvider.notifier)
        .updateArea(label.isEmpty ? null : label);
    setState(() => _areaQuery = '');
    _areaFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          _buildSectionHeader(l10n.logisticsAvailabilityHeader),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            l10n.logisticsAvailabilitySubtitle,
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
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
          _buildSectionHeader(l10n.logisticsLocationHeader),
          const SizedBox(height: KolabingSpacing.md),

          // City dropdown
          _buildLabel(l10n.logisticsPreferredCityLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          if (state.fieldErrors['preferred_city'] != null) ...[
            _buildFieldError(state.fieldErrors['preferred_city']!),
            const SizedBox(height: KolabingSpacing.xxs),
          ],
          citiesAsync.when(
            loading: () => LinearProgressIndicator(
              color: context.colors.primary,
              backgroundColor: context.colors.darkBorder,
            ),
            error: (e, _) => Text(
              l10n.logisticsCitiesLoadError(e.toString()),
              style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.error),
            ),
            data: (cities) => DropdownButtonFormField<String>(
              initialValue: kolab.preferredCity.isNotEmpty
                  ? kolab.preferredCity
                  : null,
              decoration: _inputDecoration(hint: l10n.logisticsSelectCityHint),
              items: cities
                  .map(
                    (city) => DropdownMenuItem(
                      value: city.name,
                      child: Text(city.name),
                    ),
                  )
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

          // Preferred Neighbourhood / Area (optional).
          //
          // Backed by the same Google Places autocomplete used in business
          // venue onboarding (placeSuggestionsProvider) so the area is a real
          // place lookup rather than free text. The city field above is kept.
          _buildLabel(l10n.logisticsPreferredAreaLabel),
          const SizedBox(height: KolabingSpacing.xxs),
          KolabingInput(
            controller: _areaController,
            focusNode: _areaFocusNode,
            onChanged: (value) {
              setState(() => _areaQuery = value);
              // Mirror manual edits into the form so typing without selecting a
              // suggestion still persists the area.
              ref
                  .read(kolabFormProvider.notifier)
                  .updateArea(value.trim().isEmpty ? null : value.trim());
            },
            hint: l10n.logisticsPreferredAreaHint,
            prefix: Icon(
              LucideIcons.mapPin,
              size: 18,
              color: context.colors.textTertiary,
            ),
          ),
          _buildAreaSuggestions(),
        ],
      ),
    );
  }

  /// Renders Places autocomplete results beneath the area field while the user
  /// is typing a search of at least two characters.
  Widget _buildAreaSuggestions() {
    final query = _areaQuery.trim();
    if (query.length < 2) {
      return const SizedBox.shrink();
    }

    final suggestions = ref.watch(placeSuggestionsProvider(query));

    return suggestions.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(top: KolabingSpacing.xxs),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: KolabingRadius.borderRadiusSm,
            border: Border.all(color: context.colors.darkBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i != 0)
                  Divider(height: 1, color: context.colors.darkBorder),
                ListTile(
                  dense: true,
                  leading: Icon(
                    LucideIcons.mapPin,
                    size: 18,
                    color: context.colors.textTertiary,
                  ),
                  title: Text(
                    items[i].title,
                    style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                  ),
                  subtitle: Text(
                    items[i].formattedAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
                  ),
                  onTap: () => _selectAreaSuggestion(items[i]),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: KolabingSpacing.xs),
        child: LinearProgressIndicator(
          color: context.colors.primary,
          backgroundColor: context.colors.darkBorder,
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Availability mode-specific fields
  // ---------------------------------------------------------------------------

  List<Widget> _buildAvailabilityFields(Kolab kolab, KolabFormState formState) {
    switch (kolab.availabilityMode!) {
      case AvailabilityMode.oneTime:
        return _buildOneTimeFields(kolab, formState);
      case AvailabilityMode.recurring:
        return _buildRecurringFields(kolab, formState);
    }
  }

  List<Widget> _buildOneTimeFields(Kolab kolab, KolabFormState formState) => [
    Row(
      children: [
        Expanded(
          child: _buildDatePicker(
            label: AppLocalizations.of(context).logisticsAvailableFromLabel,
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
            label: AppLocalizations.of(context).logisticsAvailableUntilLabel,
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
      label: AppLocalizations.of(context).logisticsTimeLabel,
      value: kolab.selectedTime,
      error: formState.fieldErrors['selected_time'],
      onChanged: (time) =>
          ref.read(kolabFormProvider.notifier).updateSelectedTime(time),
    ),
  ];

  List<Widget> _buildRecurringFields(Kolab kolab, KolabFormState formState) => [
    _buildLabel(AppLocalizations.of(context).logisticsDayOfWeekLabel),
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
                      ? context.colors.softYellow
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.darkBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _dayNames[i].substring(0, 3),
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant),
                ),
              ),
            ),
          ),
        );
      }),
    ),
    const SizedBox(height: KolabingSpacing.sm),
    _buildTimePicker(
      label: AppLocalizations.of(context).logisticsTimeLabel,
      value: kolab.selectedTime,
      error: formState.fieldErrors['selected_time'],
      onChanged: (time) =>
          ref.read(kolabFormProvider.notifier).updateSelectedTime(time),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Reusable sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.softYellow : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.darkBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected
                ? context.colors.primary
                : context.colors.textTertiary,
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            title,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: KolabingTextStyles.labelSmall.copyWith(fontSize: 10, color: context.colors.textTertiary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );

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
            final firstDate = DateUtils.dateOnly(minDate ?? DateTime.now());
            final lastDate = DateUtils.dateOnly(
              DateTime.now().add(const Duration(days: 365 * 2)),
            );
            final normalizedDisplayDate = DateUtils.dateOnly(displayDate);
            final initialDate = normalizedDisplayDate.isBefore(firstDate)
                ? firstDate
                : normalizedDisplayDate.isAfter(lastDate)
                ? lastDate
                : normalizedDisplayDate;

            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: context.colors.primary,
                    onPrimary: context.colors.onPrimary,
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
              color: context.colors.surface,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color: error != null
                    ? context.colors.error
                    : context.colors.darkBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    value != null
                        ? dateFormat.format(value)
                        : AppLocalizations.of(context).logisticsSelectDate,
                    style: KolabingTextStyles.bodySmall.copyWith(color: value != null
                          ? context.colors.onSurface
                          : context.colors.textTertiary),
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
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
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
  }) => Column(
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
            color: context.colors.surface,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(
              color: error != null
                  ? context.colors.error
                  : context.colors.darkBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 18,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                value != null
                    ? value.format(context)
                    : AppLocalizations.of(context).logisticsSelectTime,
                style: KolabingTextStyles.bodySmall.copyWith(color: value != null
                      ? context.colors.onSurface
                      : context.colors.textTertiary),
              ),
            ],
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(
          error,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
        ),
      ],
    ],
  );

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: context.colors.textTertiary),
    filled: true,
    fillColor: context.colors.surface,
    border: OutlineInputBorder(
      borderRadius: KolabingRadius.borderRadiusSm,
      borderSide: BorderSide(color: context.colors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: KolabingRadius.borderRadiusSm,
      borderSide: BorderSide(color: context.colors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: KolabingRadius.borderRadiusSm,
      borderSide: BorderSide(color: context.colors.primary, width: 2),
    ),
  );

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
  );

  Widget _buildLabel(String label) => Text(
    label,
    style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
  );

  Widget _buildFieldError(String error) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: context.colors.errorBg,
      borderRadius: KolabingRadius.borderRadiusSm,
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, size: 14, color: context.colors.error),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error),
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
    }
  }
}
