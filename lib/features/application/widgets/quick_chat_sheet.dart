import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_input.dart';
import '../../auth/models/auth_response.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/application.dart';
import '../providers/application_provider.dart';

/// How the Quick chat sheet closed.
class QuickChatResult {
  /// The request went through; [application] is the new application, whose
  /// chat the caller opens.
  const QuickChatResult.sent(this.application) : needsSubscription = false;

  /// The backend refused because the business has no active subscription.
  /// The caller shows the paywall.
  const QuickChatResult.needsSubscription()
    : application = null,
      needsSubscription = true;

  final Application? application;
  final bool needsSubscription;
}

enum _WhenMode { date, weekday }

/// Quick chat: a short request (when, how many people, a short note) that
/// starts a conversation without filling in the whole kolab.
///
/// It is the EXISTING apply call (`POST /kolabs/{id}/applications` with
/// `{message, availability}`); no new backend fields. Mapping:
/// - availability: a specific date becomes "On Saturday, November 14, 2026"
///   (localized long date); a day of the week becomes "Any Tuesday, every
///   week". Both are at least 20 characters, as the backend requires.
/// - message: "Group size: 20 people", then a blank line and the note, if any.
class QuickChatSheet extends ConsumerStatefulWidget {
  const QuickChatSheet({
    required this.opportunity,
    required this.partnerName,
    this.maxPeople,
    this.today,
    super.key,
  });

  final Opportunity opportunity;

  /// Shown as "with <name>" under the title.
  final String partnerName;

  /// The venue capacity, when known. The stepper never goes above it.
  final int? maxPeople;

  /// Overrides "today" (tests).
  final DateTime? today;

  static Future<QuickChatResult?> show(
    BuildContext context, {
    required Opportunity opportunity,
    required String partnerName,
    int? maxPeople,
  }) => showModalBottomSheet<QuickChatResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuickChatSheet(
      opportunity: opportunity,
      partnerName: partnerName,
      maxPeople: maxPeople,
    ),
  );

  @override
  ConsumerState<QuickChatSheet> createState() => _QuickChatSheetState();
}

class _QuickChatSheetState extends ConsumerState<QuickChatSheet> {
  static const int _defaultPeople = 20;
  static const int _minPeople = 1;

  /// Hard upper bound when the venue capacity is unknown.
  static const int _fallbackMaxPeople = 500;
  static const int _noteMaxLength = 160;

  /// How many months past the first bookable month the calendar reaches.
  static const int _monthsAhead = 6;

  final _noteController = TextEditingController();

  _WhenMode _mode = _WhenMode.date;
  DateTime? _pickedDate;
  int? _pickedWeekday; // DateTime.monday .. DateTime.sunday
  late int _people;
  late DateTime _visibleMonth;
  bool _isSubmitting = false;
  String? _errorMessage;

  late final DateTime _today;
  late final DateTime _windowStart;
  late final DateTime _windowEnd;
  late final Set<int> _recurringDays;
  late final DateTime _firstMonth;
  late final DateTime _lastMonth;

  int get _maxPeople {
    final cap = widget.maxPeople;
    if (cap != null && cap >= _minPeople) return cap;
    return _fallbackMaxPeople;
  }

  int _clampPeople(int value) {
    if (value < _minPeople) return _minPeople;
    if (value > _maxPeople) return _maxPeople;
    return value;
  }

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    final opp = widget.opportunity;
    final start = DateUtils.dateOnly(opp.availabilityStart);
    final end = DateUtils.dateOnly(opp.availabilityEnd);
    _windowStart = start.isBefore(_today) ? _today : start;
    _recurringDays = opp.availabilityMode == AvailabilityMode.recurring
        ? opp.recurringDays.toSet()
        : const <int>{};
    _firstMonth = DateTime(_windowStart.year, _windowStart.month);
    final horizonEnd = DateTime(
      _firstMonth.year,
      _firstMonth.month + _monthsAhead + 1,
      0,
    );
    _windowEnd = end.isBefore(horizonEnd) ? end : horizonEnd;
    _lastMonth = _windowEnd.isBefore(_firstMonth)
        ? _firstMonth
        : DateTime(_windowEnd.year, _windowEnd.month);
    _visibleMonth = _firstMonth;
    _people = _clampPeople(_defaultPeople);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Rules
  // ---------------------------------------------------------------------------

  /// Same rule as the full apply modal: inside the kolab's own window, from
  /// today on, and on one of its recurring days when it has any. Also capped
  /// at [_monthsAhead] months.
  bool _isSelectable(DateTime day) {
    if (day.isBefore(_windowStart) || day.isAfter(_windowEnd)) return false;
    return _recurringDays.isEmpty || _recurringDays.contains(day.weekday);
  }

  /// A weekday can be picked when at least one selectable date falls on it.
  /// Any weekday that occurs in the window occurs in its first seven days.
  bool _isWeekdaySelectable(int weekday) {
    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        _windowStart.year,
        _windowStart.month,
        _windowStart.day + i,
      );
      if (day.isAfter(_windowEnd)) return false;
      if (day.weekday == weekday && _isSelectable(day)) return true;
    }
    return false;
  }

  bool get _hasWhen => switch (_mode) {
    _WhenMode.date => _pickedDate != null,
    _WhenMode.weekday => _pickedWeekday != null,
  };

  String get _locale => Localizations.localeOf(context).toLanguageTag();

  String _weekdayName(int weekday, {bool short = false}) {
    // 1 January 2024 was a Monday.
    final day = DateTime(2024, 1, weekday);
    return short
        ? DateFormat.E(_locale).format(day)
        : DateFormat.EEEE(_locale).format(day);
  }

  String _buildAvailability(AppLocalizations l10n) {
    final date = _pickedDate;
    if (_mode == _WhenMode.date && date != null) {
      return l10n.quickChatAvailabilityOnDate(
        DateFormat.yMMMMEEEEd(_locale).format(date),
      );
    }
    return l10n.quickChatAvailabilityWeekday(_weekdayName(_pickedWeekday!));
  }

  String _buildMessage(AppLocalizations l10n) {
    final groupLine = l10n.quickChatMessageGroupSize(_people);
    final note = _noteController.text.trim();
    return note.isEmpty ? groupLine : '$groupLine\n\n$note';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _setMode(_WhenMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      // Switching mode clears the pick.
      _pickedDate = null;
      _pickedWeekday = null;
    });
  }

  void _changePeople(int delta) {
    setState(() {
      _people = _clampPeople(_people + delta);
    });
  }

  Future<void> _submit() async {
    if (!_hasWhen || _isSubmitting) return;
    final l10n = AppLocalizations.of(context);
    final availability = _buildAvailability(l10n);
    final message = _buildMessage(l10n);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final application = await ref
          .read(myApplicationsProvider.notifier)
          .submitApplication(
            opportunity: widget.opportunity,
            message: message,
            availability: availability,
          );
      if (!mounted) return;
      if (application != null) {
        Navigator.of(context).pop(QuickChatResult.sent(application));
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.quickChatError;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.error.requiresSubscription || error.error.statusCode == 402) {
        Navigator.of(context).pop(const QuickChatResult.needsSubscription());
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.error.allErrorMessages;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().contains('already applied')
            ? l10n.applyModalAlreadyApplied
            : l10n.quickChatError;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      key: const Key('quick-chat-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KolabingRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: KolabingSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                KolabingSpacing.lg,
                KolabingSpacing.md,
                KolabingSpacing.lg,
                bottomInset + bottomPadding + KolabingSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quickChatTitle,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xxxs),
                  Text(
                    l10n.quickChatWith(widget.partnerName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: KolabingSpacing.md),
                    _buildError(_errorMessage!),
                  ],
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildLabel(l10n.quickChatWhenLabel),
                  const SizedBox(height: KolabingSpacing.xs),
                  _buildModeToggle(l10n),
                  const SizedBox(height: KolabingSpacing.sm),
                  if (_mode == _WhenMode.date)
                    _buildCalendar(l10n)
                  else
                    _buildWeekdayChips(l10n),
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildLabel(l10n.quickChatPeopleLabel),
                  const SizedBox(height: KolabingSpacing.xs),
                  _buildPeopleStepper(l10n),
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildLabel(l10n.quickChatNoteLabel),
                  const SizedBox(height: KolabingSpacing.xs),
                  KolabingInput(
                    key: const Key('quick-chat-note'),
                    controller: _noteController,
                    maxLength: _noteMaxLength,
                    maxLines: 3,
                    minLines: 2,
                    hint: l10n.quickChatNoteHint,
                    fillColor: context.colors.background,
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  Text(
                    l10n.quickChatFinePrint,
                    style: KolabingTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: context.colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  KolabingButton(
                    key: const Key('quick-chat-start'),
                    label: l10n.quickChatStart,
                    onPressed: _hasWhen && !_isSubmitting ? _submit : null,
                    variant: KolabingButtonVariant.primary,
                    icon: const Icon(LucideIcons.messageCircle),
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: KolabingTextStyles.labelLarge.copyWith(
      fontWeight: FontWeight.w700,
      color: context.colors.onSurface,
    ),
  );

  Widget _buildError(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(KolabingSpacing.sm),
    decoration: BoxDecoration(
      color: context.colors.error.withValues(alpha: 0.1),
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(LucideIcons.alertCircle, size: 18, color: context.colors.error),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildModeToggle(AppLocalizations l10n) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
    ),
    child: Row(
      children: [
        Expanded(
          child: _SegmentButton(
            key: const Key('quick-chat-mode-date'),
            label: l10n.quickChatModeDate,
            isSelected: _mode == _WhenMode.date,
            onTap: () => _setMode(_WhenMode.date),
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: _SegmentButton(
            key: const Key('quick-chat-mode-weekday'),
            label: l10n.quickChatModeWeekday,
            isSelected: _mode == _WhenMode.weekday,
            onTap: () => _setMode(_WhenMode.weekday),
          ),
        ),
      ],
    ),
  );

  Widget _buildCalendar(AppLocalizations l10n) {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final canGoBack = _visibleMonth.isAfter(_firstMonth);
    final canGoForward = _visibleMonth.isBefore(_lastMonth);
    final leadingBlanks = DateTime(year, month).weekday - 1; // Monday first
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final picked = _pickedDate;

    Widget dayCell(int index) {
      final dayNumber = index - leadingBlanks + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return const SizedBox(height: 38);
      }
      final day = DateTime(year, month, dayNumber);
      final selectable = _isSelectable(day);
      final isSelected = picked != null && DateUtils.isSameDay(picked, day);
      return Semantics(
        button: true,
        selected: isSelected,
        enabled: selectable,
        label: DateFormat.MMMMEEEEd(_locale).format(day),
        excludeSemantics: true,
        child: GestureDetector(
          key: Key('quick-chat-day-$year-$month-$dayNumber'),
          behavior: HitTestBehavior.opaque,
          onTap: selectable
              ? () => setState(() => _pickedDate = day)
              : null,
          child: SizedBox(
            height: 38,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? context.colors.ink : Colors.transparent,
                ),
                child: Text(
                  '$dayNumber',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : selectable
                        ? context.colors.onSurface
                        : context.colors.textTertiary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.xs,
        KolabingSpacing.xs,
        KolabingSpacing.xs,
        KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('quick-chat-prev-month'),
                tooltip: l10n.quickChatPreviousMonth,
                onPressed: canGoBack
                    ? () => setState(
                        () => _visibleMonth = DateTime(year, month - 1),
                      )
                    : null,
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(_locale).format(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                key: const Key('quick-chat-next-month'),
                tooltip: l10n.quickChatNextMonth,
                onPressed: canGoForward
                    ? () => setState(
                        () => _visibleMonth = DateTime(year, month + 1),
                      )
                    : null,
                icon: const Icon(LucideIcons.chevronRight, size: 18),
              ),
            ],
          ),
          Row(
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                Expanded(
                  child: Text(
                    DateFormat.EEEEE(
                      _locale,
                    ).format(DateTime(2024, 1, weekday)),
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          for (var row = 0; row < cellCount ~/ 7; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: dayCell(row * 7 + col)),
              ],
            ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            picked == null
                ? l10n.quickChatPickDate
                : l10n.quickChatSelectedDate(
                    DateFormat.MMMEd(_locale).format(picked),
                  ),
            style: KolabingTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayChips(AppLocalizations l10n) => Wrap(
    spacing: KolabingSpacing.xs,
    runSpacing: KolabingSpacing.xs,
    children: [
      for (var weekday = 1; weekday <= 7; weekday++)
        _WeekdayChip(
          key: Key('quick-chat-weekday-$weekday'),
          label: _weekdayName(weekday, short: true),
          caption: l10n.quickChatEveryWeek,
          isSelected: _pickedWeekday == weekday,
          onTap: _isWeekdaySelectable(weekday)
              ? () => setState(() => _pickedWeekday = weekday)
              : null,
        ),
    ],
  );

  Widget _buildPeopleStepper(AppLocalizations l10n) => Row(
    children: [
      _StepButton(
        key: const Key('quick-chat-people-minus'),
        icon: LucideIcons.minus,
        semanticLabel: l10n.quickChatFewerPeople,
        onTap: _people > _minPeople ? () => _changePeople(-1) : null,
      ),
      Expanded(
        child: Text(
          '$_people',
          key: const Key('quick-chat-people-count'),
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
      ),
      _StepButton(
        key: const Key('quick-chat-people-plus'),
        icon: LucideIcons.plus,
        semanticLabel: l10n.quickChatMorePeople,
        onTap: _people < _maxPeople ? () => _changePeople(1) : null,
      ),
    ],
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: isSelected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? context.colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(KolabingRadius.sm),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KolabingTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? context.colors.onSurface
                : context.colors.textTertiary,
          ),
        ),
      ),
    ),
  );
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.caption,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String caption;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: KolabingSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.softYellow
                  : context.colors.surface,
              borderRadius: BorderRadius.circular(KolabingRadius.md),
              border: Border.all(
                color: isSelected
                    ? context.colors.ink
                    : context.colors.darkBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: KolabingTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                Text(
                  caption,
                  style: KolabingTextStyles.labelSmall.copyWith(
                    fontSize: 11,
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: semanticLabel,
    excludeSemantics: true,
    child: Material(
      color: context.colors.surfaceVariant,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? context.colors.onSurface
                : context.colors.textTertiary,
          ),
        ),
      ),
    ),
  );
}
