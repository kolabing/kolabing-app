import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolabing_input.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/time_picker.dart';
import '../../auth/models/auth_response.dart';
import '../../opportunity/models/opportunity.dart';
import '../providers/application_provider.dart';

/// Modal bottom sheet for applying to an opportunity
@visibleForTesting
List<DateTime> buildSelectableApplicationDates(
  Opportunity opportunity, {
  DateTime? today,
}) {
  final start = DateUtils.dateOnly(opportunity.availabilityStart);
  final end = DateUtils.dateOnly(opportunity.availabilityEnd);
  final todayDate = DateUtils.dateOnly(today ?? DateTime.now());

  final effectiveStart = end.isBefore(todayDate)
      ? start
      : (start.isBefore(todayDate) ? todayDate : start);

  if (effectiveStart.isAfter(end)) {
    return const <DateTime>[];
  }

  final recurringDays =
      opportunity.availabilityMode == AvailabilityMode.recurring
      ? opportunity.recurringDays.toSet()
      : const <int>{};

  final dates = <DateTime>[];
  var current = effectiveStart;
  while (!current.isAfter(end)) {
    final isAllowed =
        recurringDays.isEmpty || recurringDays.contains(current.weekday);
    if (isAllowed) {
      dates.add(current);
    }
    current = current.add(const Duration(days: 1));
  }
  return dates;
}

class ApplyModal extends ConsumerStatefulWidget {
  const ApplyModal({required this.opportunity, super.key});

  final Opportunity opportunity;

  /// Show the apply modal
  static Future<bool?> show(BuildContext context, Opportunity opportunity) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ApplyModal(opportunity: opportunity),
      );

  @override
  ConsumerState<ApplyModal> createState() => _ApplyModalState();
}

class _ApplyModalState extends ConsumerState<ApplyModal> {
  final _messageController = TextEditingController();
  final _availabilityNotesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _errorMessage;

  // Availability state — dates from opportunity range
  final Set<DateTime> _selectedDates = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String? _availabilityError;

  late final List<DateTime> _availableDates;
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    // Build list of selectable dates from opportunity's availability range
    _availableDates = buildSelectableApplicationDates(widget.opportunity);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _availabilityNotesController.dispose();
    super.dispose();
  }

  /// Build the availability string from selected dates
  String _buildAvailabilityString() {
    if (_selectedDates.isEmpty) return '';

    final sortedDates = _selectedDates.toList()..sort((a, b) => a.compareTo(b));

    final dateStrings = sortedDates
        .map((d) => '${_monthLabels[d.month - 1]} ${d.day}, ${d.year}')
        .join(', ');

    final timePart = '${_formatTime(_startTime)} - ${_formatTime(_endTime)}';
    final notes = _availabilityNotesController.text.trim();

    if (notes.isNotEmpty) {
      return '$dateStrings • $timePart\n$notes';
    }
    return '$dateStrings • $timePart';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _handleSubmit() async {
    // Validate date selection
    setState(() => _availabilityError = null);
    if (_selectedDates.isEmpty) {
      setState(() => _availabilityError =
          AppLocalizations.of(context).applyModalSelectDateError);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final availability = _buildAvailabilityString();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final application = await ref
          .read(myApplicationsProvider.notifier)
          .submitApplication(
            opportunity: widget.opportunity,
            message: _messageController.text.trim(),
            availability: availability,
          );

      if (!mounted) return;

      if (application != null) {
        // Caller is responsible for the success UI (e.g. ApplySuccessSheet) so
        // there's a single, polished celebration moment instead of a snackbar
        // overlapping with the closing modal.
        Navigator.of(context).pop(true);
      }
    } on Object catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isSubmitting = false;
        _errorMessage = _parseError(l10n, error);
      });
    }
  }

  String _parseError(AppLocalizations l10n, Object error) {
    if (error is ApiException) {
      return error.error.allErrorMessages;
    }
    final errorString = error.toString();
    if (errorString.contains('already applied')) {
      return l10n.applyModalAlreadyApplied;
    }
    return l10n.applyModalSubmitError;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header — minimal, just an escape route
          Padding(
            padding: const EdgeInsets.only(right: KolabingSpacing.xs),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: KolabingSpacing.lg),
                  child: Text(
                    AppLocalizations.of(context).applyModalHeader,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.colors.textTertiary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  style: IconButton.styleFrom(
                    foregroundColor: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                KolabingSpacing.lg,
                KolabingSpacing.md,
                KolabingSpacing.lg,
                bottomPadding + KolabingSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(KolabingSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.error.withValues(alpha: 0.1),
                          borderRadius: KolabingRadius.borderRadiusMd,
                          border: Border.all(
                            color: context.colors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: 18,
                              color: context.colors.error,
                            ),
                            const SizedBox(width: KolabingSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: KolabingTextStyles.bodySmall.copyWith(
                                  color: context.colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                    ],

                    // Hero card — creator + opportunity at a glance
                    _buildHeroCard(),
                    const SizedBox(height: KolabingSpacing.md),

                    // Quick facts
                    _buildQuickFacts(),
                    const SizedBox(height: KolabingSpacing.md),

                    // Offer highlight (only when the host configured offers)
                    if (widget.opportunity.businessOffer.hasAnyOffer) ...[
                      _buildOfferHighlight(),
                      const SizedBox(height: KolabingSpacing.md),
                    ],

                    // Tip card
                    _buildTipCard(),
                    const SizedBox(height: KolabingSpacing.lg),

                    // Message field — optional, but encouraged
                    _buildSectionTitle(
                        AppLocalizations.of(context).applyModalMessageTitle,
                        optional: true),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      AppLocalizations.of(context).applyModalMessageHelp,
                      style: KolabingTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: context.colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    KolabingInput(
                      controller: _messageController,
                      maxLength: 1000,
                      maxLines: 5,
                      minLines: 4,
                      hint: AppLocalizations.of(context).applyModalMessageHint,
                      fillColor: context.colors.background,
                    ),

                    const SizedBox(height: KolabingSpacing.lg),

                    // Availability field — date picker constrained to opportunity range
                    _buildSectionTitle(
                        AppLocalizations.of(context).applyModalSelectDatesTitle,
                        required: true),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      AppLocalizations.of(context).applyModalSelectDatesHelp,
                      style: KolabingTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),

                    // Date selector (horizontal scrollable)
                    _buildDateSelector(),
                    if (_availabilityError != null) ...[
                      const SizedBox(height: KolabingSpacing.xxs),
                      Text(
                        _availabilityError!,
                        style: KolabingTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          color: context.colors.error,
                        ),
                      ),
                    ],
                    // Time range picker + notes — only when dates exist
                    if (_availableDates.isNotEmpty) ...[
                      const SizedBox(height: KolabingSpacing.md),
                      _buildTimeRangePicker(),
                      const SizedBox(height: KolabingSpacing.md),
                      Text(
                        AppLocalizations.of(context).applyModalNotesLabel,
                        style: KolabingTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          color: context.colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      KolabingInput(
                        controller: _availabilityNotesController,
                        maxLength: 200,
                        maxLines: 2,
                        minLines: 1,
                        hint: AppLocalizations.of(context).applyModalNotesHint,
                        fillColor: context.colors.background,
                      ),
                    ],

                    const SizedBox(height: KolabingSpacing.xl),

                    // Single full-width primary action (X in header is the escape)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.colors.onPrimary,
                                ),
                              )
                            : const Icon(LucideIcons.send, size: 18),
                        label: Text(
                          _isSubmitting
                              ? AppLocalizations.of(context).applyModalSending
                              : AppLocalizations.of(context).applyModalSend,
                          style: KolabingTextStyles.button.copyWith(
                            fontSize: 15,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: context.colors.primary
                              .withValues(alpha: 0.6),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Time Slot Picker Widgets
  // ===========================================================================

  Widget _buildDateSelector() {
    if (_availableDates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.error.withValues(alpha: 0.05),
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: context.colors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          AppLocalizations.of(context).applyModalNoDates,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 13,
            color: context.colors.error,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDates.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: KolabingSpacing.xs),
        itemBuilder: (context, index) {
          final date = _availableDates[index];
          final isSelected = _selectedDates.contains(date);
          final dayLabel = _dayLabels[date.weekday - 1]; // weekday: 1=Mon
          final dayNum = date.day.toString();
          final monthLabel = _monthLabels[date.month - 1];

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDates.remove(date);
                } else {
                  _selectedDates.add(date);
                }
                _availabilityError = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.background,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : _availabilityError != null
                      ? context.colors.error
                      : context.colors.darkBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? context.colors.onPrimary
                          : context.colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? context.colors.onPrimary
                          : context.colors.onSurface,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? context.colors.onPrimary.withValues(alpha: 0.8)
                          : context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangePicker() => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.background,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: context.colors.darkBorder),
    ),
    child: Row(
      children: [
        Icon(
          LucideIcons.clock,
          size: 18,
          color: context.colors.textTertiary,
        ),
        const SizedBox(width: KolabingSpacing.sm),
        // Start time
        Expanded(
          child: _buildTimePicker(
            label: AppLocalizations.of(context).applyModalTimeFrom,
            time: _startTime,
            onTap: () => _pickTime(isStart: true),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
          child: Icon(
            LucideIcons.arrowRight,
            size: 16,
            color: context.colors.textTertiary,
          ),
        ),
        // End time
        Expanded(
          child: _buildTimePicker(
            label: AppLocalizations.of(context).applyModalTimeTo,
            time: _endTime,
            onTap: () => _pickTime(isStart: false),
          ),
        ),
      ],
    ),
  );

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusSm,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 10,
              color: context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(time),
            style: KolabingTextStyles.labelLarge.copyWith(
              fontSize: 15,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await KolabingTimePicker.show(
      context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ===========================================================================
  // Section & Input Helpers
  // ===========================================================================

  Widget _buildSectionTitle(
    String title, {
    bool required = false,
    bool optional = false,
  }) => Row(
    children: [
      Text(
        title,
        style: KolabingTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.onSurface,
        ),
      ),
      if (required) ...[
        const SizedBox(width: 4),
        Text(
          '*',
          style: KolabingTextStyles.labelLarge.copyWith(
            color: context.colors.error,
          ),
        ),
      ],
      if (optional) ...[
        const SizedBox(width: KolabingSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            AppLocalizations.of(context).applyModalOptionalBadge,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 10,
              letterSpacing: 0.4,
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    ],
  );

  Widget _buildHeroCard() {
    final creator = widget.opportunity.creatorProfile;
    final creatorName =
        creator?.displayName ?? AppLocalizations.of(context).applyModalUnknownHost;
    final creatorTypeLabel = (creator?.userType.isNotEmpty ?? false)
        ? '${creator!.userType[0].toUpperCase()}${creator.userType.substring(1)}'
        : AppLocalizations.of(context).applyModalHostFallback;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child:
                    creator?.avatarUrl != null && creator!.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          creator.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarPlaceholder(),
                        ),
                      )
                    : _buildAvatarPlaceholder(),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            creatorName,
                            style: KolabingTextStyles.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            creatorTypeLabel,
                            style: KolabingTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: context.colors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).applyModalApplyingTo,
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            widget.opportunity.title,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: context.colors.onSurface,
            ),
          ),
          if (widget.opportunity.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.opportunity.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 13,
                height: 1.5,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFacts() {
    final opp = widget.opportunity;
    final facts = <_FactItem>[
      if (opp.preferredCity.isNotEmpty)
        _FactItem(LucideIcons.mapPin, opp.preferredCity),
      _FactItem(LucideIcons.calendar, _formatDateRange()),
      _FactItem(LucideIcons.clock, opp.availabilityMode.displayName),
      _FactItem(LucideIcons.building2, opp.venueMode.displayName),
      if (opp.categories.isNotEmpty)
        _FactItem(LucideIcons.tag, opp.categories.take(2).join(', ')),
    ];

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: facts
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.icon, size: 13, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    f.label,
                    style: KolabingTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOfferHighlight() => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.success.withValues(alpha: 0.1),
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.gift, size: 18, color: context.colors.success),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).applyModalWhatsOffered,
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: context.colors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.opportunity.offerSummary,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTipCard() => Container(
    padding: const EdgeInsets.all(KolabingSpacing.sm),
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant,
      borderRadius: KolabingRadius.borderRadiusSm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.sparkles,
          size: 16,
          color: context.colors.textTertiary,
        ),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            AppLocalizations.of(context).applyModalTip,
            style: KolabingTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    ),
  );

  String _formatDateRange() {
    final start = widget.opportunity.availabilityStart;
    final end = widget.opportunity.availabilityEnd;

    String formatDate(DateTime date) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    if (start == end) {
      return formatDate(start);
    }
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  Widget _buildAvatarPlaceholder() => Center(
    child: Text(
      widget.opportunity.creatorProfile?.initial ?? '?',
      style: KolabingTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colors.primary,
      ),
    ),
  );
}

class _FactItem {
  const _FactItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
