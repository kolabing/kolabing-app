import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../auth/models/auth_response.dart';
import '../../opportunity/models/opportunity.dart';
import '../providers/application_provider.dart';

/// Modal bottom sheet for applying to an opportunity
class ApplyModal extends ConsumerStatefulWidget {
  const ApplyModal({
    required this.opportunity,
    super.key,
  });

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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    // Build list of selectable dates from opportunity's availability range
    _availableDates = _buildAvailableDates();
  }

  List<DateTime> _buildAvailableDates() {
    final start = DateUtils.dateOnly(widget.opportunity.availabilityStart);
    final end = DateUtils.dateOnly(widget.opportunity.availabilityEnd);
    final today = DateUtils.dateOnly(DateTime.now());

    // Start from today if the opportunity start is in the past
    final effectiveStart = start.isBefore(today) ? today : start;

    if (effectiveStart.isAfter(end)) return [];

    final dates = <DateTime>[];
    var current = effectiveStart;
    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
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

    final sortedDates = _selectedDates.toList()
      ..sort((a, b) => a.compareTo(b));

    final dateStrings = sortedDates.map((d) =>
      '${_monthLabels[d.month - 1]} ${d.day}, ${d.year}',
    ).join(', ');

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
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: KolabingColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = _parseError(e);
      });
    }
  }

  String _parseError(dynamic e) {
    if (e is ApiException) {
      return e.error.allErrorMessages;
    }
    final errorString = e.toString();
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.lg,
              KolabingSpacing.md,
              KolabingSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply to',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '"${widget.opportunity.title}"',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: KolabingColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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

                    // Opportunity info card
                    _buildOpportunityInfo(),
                    const SizedBox(height: KolabingSpacing.lg),

                    // Message field
                    _buildSectionTitle('Application Message', required: true),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      'Explain why you are a good fit for this collaboration',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    TextFormField(
                      controller: _messageController,
                      maxLength: 1000,
                      maxLines: 5,
                      minLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
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
                    const SizedBox(height: KolabingSpacing.md),

                    // Time range picker
                    _buildTimeRangePicker(),
                    const SizedBox(height: KolabingSpacing.md),

                    // Optional notes
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
                        hintText: 'e.g., Flexible on timing, prefer mornings...',
                      ),
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: KolabingColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: KolabingSpacing.lg),

                    // Recipient info
                    _buildRecipientInfo(),

                    const SizedBox(height: KolabingSpacing.xl),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KolabingColors.textPrimary,
                              side: const BorderSide(color: KolabingColors.border),
                              padding: const EdgeInsets.symmetric(
                                vertical: KolabingSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: KolabingRadius.borderRadiusMd,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: KolabingSpacing.sm),
                        Expanded(
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
                              _isSubmitting ? 'Submitting...' : 'APPLY',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KolabingColors.primary,
                              foregroundColor: KolabingColors.onPrimary,
                              disabledBackgroundColor:
                                  KolabingColors.primary.withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(
                                vertical: KolabingSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: KolabingRadius.borderRadiusMd,
                              ),
                            ),
                          ),
                        ),
                      ],
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
        separatorBuilder: (_, __) =>
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
  }) =>
      GestureDetector(
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
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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

  Widget _buildSectionTitle(String title, {bool required = false}) => Row(
        children: [
          Text(
            title,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
          borderSide: const BorderSide(
            color: KolabingColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: const BorderSide(
            color: KolabingColors.border,
          ),
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
          borderSide: const BorderSide(
            color: KolabingColors.error,
          ),
        ),
        contentPadding: const EdgeInsets.all(KolabingSpacing.md),
        counterStyle: GoogleFonts.openSans(
          fontSize: 12,
          color: KolabingColors.textTertiary,
        ),
      );

  Widget _buildOpportunityInfo() => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.05),
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: KolabingColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range
            if (widget.opportunity.availabilityStart != null) ...[
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: KolabingColors.primary,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Text(
                    'Available: ${_formatDateRange()}',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.xs),
            ],

            // Location
            if (widget.opportunity.preferredCity.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: KolabingColors.primary,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Text(
                    widget.opportunity.preferredCity,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KolabingSpacing.xs),
            ],

            // Categories
            if (widget.opportunity.categories.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    LucideIcons.tag,
                    size: 16,
                    color: KolabingColors.primary,
                  ),
                  const SizedBox(width: KolabingSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.opportunity.categories.join(', '),
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: KolabingColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );

  String _formatDateRange() {
    final start = widget.opportunity.availabilityStart;
    final end = widget.opportunity.availabilityEnd;

    String formatDate(DateTime date) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    if (start == end) {
      return formatDate(start);
    }
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  Widget _buildRecipientInfo() => Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.background,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: KolabingColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: KolabingColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: widget.opportunity.creatorProfile?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.opportunity.creatorProfile!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                      ),
                    )
                  : _buildAvatarPlaceholder(),
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're applying to:",
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.opportunity.creatorProfile?.displayName ?? "Unknown"} • ${widget.opportunity.preferredCity}',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildAvatarPlaceholder() => Center(
        child: Text(
          widget.opportunity.creatorProfile?.initial ?? '?',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: KolabingColors.primary,
          ),
        ),
      );
}
