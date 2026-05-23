import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
      setState(() => _availabilityError = 'Please select at least one date');
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
      setState(() {
        _isSubmitting = false;
        _errorMessage = _parseError(error);
      });
    }
  }

  String _parseError(Object error) {
    if (error is ApiException) {
      return error.error.allErrorMessages;
    }
    final errorString = error.toString();
    if (errorString.contains('already applied')) {
      return 'You have already applied to this opportunity';
    }
    return 'Failed to submit application. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
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
                color: KolabingColors.border,
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
                    'NEW APPLICATION',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  style: IconButton.styleFrom(
                    foregroundColor: KolabingColors.textTertiary,
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
                          color: KolabingColors.error.withValues(alpha: 0.1),
                          borderRadius: KolabingRadius.borderRadiusMd,
                          border: Border.all(
                            color: KolabingColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.alertCircle,
                              size: 18,
                              color: KolabingColors.error,
                            ),
                            const SizedBox(width: KolabingSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.openSans(
                                  fontSize: 14,
                                  color: KolabingColors.error,
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
                    _buildSectionTitle('Your message', optional: true),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      'A short pitch helps you stand out — mention what you bring and why this fit makes sense.',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        height: 1.5,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    TextFormField(
                      controller: _messageController,
                      maxLength: 1000,
                      maxLines: 5,
                      minLines: 4,
                      decoration: _buildInputDecoration(
                        hintText:
                            "Tell them why you're perfect for this collaboration and what value you can bring...",
                      ),
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: KolabingColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: KolabingSpacing.lg),

                    // Availability field — date picker constrained to opportunity range
                    _buildSectionTitle('Select Date(s)', required: true),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      'Pick from the available dates for this collaboration',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),

                    // Date selector (horizontal scrollable)
                    _buildDateSelector(),
                    if (_availabilityError != null) ...[
                      const SizedBox(height: KolabingSpacing.xxs),
                      Text(
                        _availabilityError!,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.error,
                        ),
                      ),
                    ],
                    // Time range picker + notes — only when dates exist
                    if (_availableDates.isNotEmpty) ...[
                      const SizedBox(height: KolabingSpacing.md),
                      _buildTimeRangePicker(),
                      const SizedBox(height: KolabingSpacing.md),
                      Text(
                        'Additional notes (optional)',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.xs),
                      TextFormField(
                        controller: _availabilityNotesController,
                        maxLength: 200,
                        maxLines: 2,
                        minLines: 1,
                        decoration: _buildInputDecoration(
                          hintText:
                              'e.g., Flexible on timing, prefer mornings...',
                        ),
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textPrimary,
                        ),
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
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KolabingColors.onPrimary,
                                ),
                              )
                            : const Icon(LucideIcons.send, size: 18),
                        label: Text(
                          _isSubmitting ? 'SENDING…' : 'SEND APPLICATION',
                          style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KolabingColors.primary,
                          foregroundColor: KolabingColors.onPrimary,
                          disabledBackgroundColor: KolabingColors.primary
                              .withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: KolabingRadius.borderRadiusMd,
                          ),
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
          color: KolabingColors.error.withValues(alpha: 0.05),
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: KolabingColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          'No available dates for this collaboration',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.error,
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
                    ? KolabingColors.primary
                    : KolabingColors.background,
                borderRadius: KolabingRadius.borderRadiusSm,
                border: Border.all(
                  color: isSelected
                      ? KolabingColors.primary
                      : _availabilityError != null
                      ? KolabingColors.error
                      : KolabingColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textPrimary,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? KolabingColors.onPrimary.withValues(alpha: 0.8)
                          : KolabingColors.textTertiary,
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
      color: KolabingColors.background,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: KolabingColors.border),
    ),
    child: Row(
      children: [
        const Icon(
          LucideIcons.clock,
          size: 18,
          color: KolabingColors.textTertiary,
        ),
        const SizedBox(width: KolabingSpacing.sm),
        // Start time
        Expanded(
          child: _buildTimePicker(
            label: 'From',
            time: _startTime,
            onTap: () => _pickTime(isStart: true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
          child: Icon(
            LucideIcons.arrowRight,
            size: 16,
            color: KolabingColors.textTertiary,
          ),
        ),
        // End time
        Expanded(
          child: _buildTimePicker(
            label: 'To',
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
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusSm,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 10,
              color: KolabingColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(time),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
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
        style: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: KolabingColors.textPrimary,
        ),
      ),
      if (required) ...[
        const SizedBox(width: 4),
        Text(
          '*',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KolabingColors.error,
          ),
        ),
      ],
      if (optional) ...[
        const SizedBox(width: KolabingSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: KolabingColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Optional',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    ],
  );

  InputDecoration _buildInputDecoration({required String hintText}) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.openSans(
          fontSize: 14,
          color: KolabingColors.textTertiary,
        ),
        filled: true,
        fillColor: KolabingColors.background,
        border: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: const BorderSide(color: KolabingColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: const BorderSide(color: KolabingColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: const BorderSide(
            color: KolabingColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: const BorderSide(color: KolabingColors.error),
        ),
        contentPadding: const EdgeInsets.all(KolabingSpacing.md),
        counterStyle: GoogleFonts.openSans(
          fontSize: 12,
          color: KolabingColors.textTertiary,
        ),
      );

  Widget _buildHeroCard() {
    final creator = widget.opportunity.creatorProfile;
    final creatorName = creator?.displayName ?? 'Unknown host';
    final creatorTypeLabel = (creator?.userType.isNotEmpty ?? false)
        ? '${creator!.userType[0].toUpperCase()}${creator.userType.substring(1)}'
        : 'Host';

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.primary.withValues(alpha: 0.08),
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: KolabingColors.primary.withValues(alpha: 0.25),
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
                  color: KolabingColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KolabingColors.primary.withValues(alpha: 0.4),
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
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.textPrimary,
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
                            color: KolabingColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            creatorTypeLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.onPrimary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You are applying to',
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: KolabingColors.textTertiary,
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
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: KolabingColors.textPrimary,
            ),
          ),
          if (widget.opportunity.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.opportunity.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 13,
                height: 1.5,
                color: KolabingColors.textSecondary,
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
                color: KolabingColors.surfaceVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.icon, size: 13, color: KolabingColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    f.label,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textSecondary,
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
      color: KolabingColors.success.withValues(alpha: 0.1),
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: KolabingColors.success.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.gift, size: 18, color: KolabingColors.success),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's offered",
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: KolabingColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.opportunity.offerSummary,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: KolabingColors.textPrimary,
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
      color: KolabingColors.surfaceVariant,
      borderRadius: KolabingRadius.borderRadiusSm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          LucideIcons.sparkles,
          size: 16,
          color: KolabingColors.textTertiary,
        ),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            'Pick the dates that work for you and add a short message — applications with specifics get accepted faster.',
            style: GoogleFonts.openSans(
              fontSize: 12,
              height: 1.5,
              color: KolabingColors.textTertiary,
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
      style: GoogleFonts.rubik(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: KolabingColors.primary,
      ),
    ),
  );
}

class _FactItem {
  const _FactItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
