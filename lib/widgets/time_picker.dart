import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';

/// A UX-friendly time picker displayed as a modal bottom sheet.
///
/// Uses two scroll wheels (hours 00–23, minutes 00–59) instead of
/// the hard-to-use clock dial. Both wheels loop infinitely.
///
/// Usage:
/// ```dart
/// final picked = await KolabingTimePicker.show(
///   context,
///   initialTime: const TimeOfDay(hour: 10, minute: 0),
/// );
/// if (picked != null) { ... }
/// ```
class KolabingTimePicker extends StatefulWidget {
  const KolabingTimePicker({super.key, required this.initialTime});

  final TimeOfDay initialTime;

  /// Shows the picker as a modal bottom sheet and returns the selected
  /// [TimeOfDay], or `null` if dismissed without confirming.
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) =>
      showModalBottomSheet<TimeOfDay>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => KolabingTimePicker(initialTime: initialTime),
      );

  @override
  State<KolabingTimePicker> createState() => _KolabingTimePickerState();
}

class _KolabingTimePickerState extends State<KolabingTimePicker> {
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  // Each item row height
  static const double _itemExtent = 54;
  // How many items visible in the wheel
  static const int _visibleCount = 5;
  // Total wheel height
  static const double _wheelHeight = _itemExtent * _visibleCount;
  // Large offset so the wheel appears "infinite" in both directions
  static const int _loopOffset = 500;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(
      initialItem: _hour + 24 * _loopOffset,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _minute + 60 * _loopOffset,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            KolabingSpacing.sm,
            KolabingSpacing.md,
            KolabingSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KolabingColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Title
              Text(
                'Select Time',
                style: GoogleFonts.rubik(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Wheels
              SizedBox(
                height: _wheelHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection highlight behind the wheels
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _itemExtent,
                        decoration: BoxDecoration(
                          color: KolabingColors.softYellow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    // Hour + colon + minute
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hours
                        SizedBox(
                          width: 80,
                          height: _wheelHeight,
                          child: _buildWheel(
                            controller: _hourController,
                            count: 24,
                            selected: _hour,
                            onChanged: (i) =>
                                setState(() => _hour = i % 24),
                          ),
                        ),

                        // Colon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            ':',
                            style: GoogleFonts.rubik(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: KolabingColors.textPrimary,
                            ),
                          ),
                        ),

                        // Minutes
                        SizedBox(
                          width: 80,
                          height: _wheelHeight,
                          child: _buildWheel(
                            controller: _minuteController,
                            count: 60,
                            selected: _minute,
                            onChanged: (i) =>
                                setState(() => _minute = i % 60),
                          ),
                        ),
                      ],
                    ),

                    // Top fade — hides items above selection
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: _itemExtent * (_visibleCount ~/ 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                KolabingColors.surface,
                                KolabingColors.surface.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom fade
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: _itemExtent * (_visibleCount ~/ 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                KolabingColors.surface,
                                KolabingColors.surface.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KolabingColors.textSecondary,
                        side: const BorderSide(color: KolabingColors.border),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(
                        TimeOfDay(hour: _hour, minute: _minute),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KolabingColors.primary,
                        foregroundColor: KolabingColors.onPrimary,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CONFIRM',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 2.2,
      perspective: 0.002,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildLoopingListDelegate(
        children: List.generate(count, (i) {
          final isSelected = i == selected;
          return Center(
            child: Text(
              _pad(i),
              style: GoogleFonts.rubik(
                fontSize: isSelected ? 26 : 18,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? KolabingColors.textPrimary
                    : KolabingColors.textSecondary.withValues(alpha: 0.45),
              ),
            ),
          );
        }),
      ),
    );
  }
}
