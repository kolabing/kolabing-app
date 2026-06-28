import 'package:flutter/material.dart';

import '../config/constants/layout.dart';
import '../config/constants/radius.dart';
import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

/// Visual weight of a [KolabingSegmentedControl].
enum KolabingSegmentedStyle {
  /// Full-width, white track + border + shadow, ink fill on the selected
  /// segment. Use for the primary filter row (e.g. status tabs).
  primary,

  /// Compact, content-width track nested under a primary row, with a yellow
  /// fill on the selected segment. Reads as one unified two-option toggle —
  /// not a loose pill next to muted text. Use for a secondary filter row
  /// (e.g. Published/Draft, Sent/Received).
  secondary,
}

/// Reusable pill-shaped segmented control.
///
/// Single source of truth for the "selected = filled pill" filter pattern —
/// every screen binds its own segment labels/value/onChanged; the widget
/// never hardcodes copy.
class KolabingSegmentedControl<T> extends StatelessWidget {
  const KolabingSegmentedControl({
    required this.segments,
    required this.selectedValue,
    required this.onChanged,
    super.key,
    this.style = KolabingSegmentedStyle.primary,
  });

  /// Ordered (value, label) pairs. Labels are rendered as-is (callers
  /// control casing/copy).
  final List<(T value, String label)> segments;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final KolabingSegmentedStyle style;

  bool get _isPrimary => style == KolabingSegmentedStyle.primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Both styles share the same track language (white pill + hairline) so the
    // secondary row reads as a real toggle. Secondary is taller-enough to keep
    // a comfortable tap target and drops the shadow to stay subordinate.
    final height = _isPrimary ? 38.0 : 40.0;

    final track = Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: KolabingRadius.borderRadiusPill,
        border: Border.all(color: c.controlBorder, width: 1),
        boxShadow: _isPrimary ? const [KolabingShadows.card] : null,
      ),
      child: Row(
        mainAxisSize: _isPrimary ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final (value, label) in segments)
            _isPrimary
                ? Expanded(child: _segment(context, value, label, height))
                : _segment(context, value, label, height),
        ],
      ),
    );

    // Primary fills the row; secondary sizes to its content and lets the caller
    // decide alignment (centered in My Kolabs).
    return _isPrimary ? SizedBox(width: double.infinity, child: track) : track;
  }

  Widget _segment(BuildContext context, T value, String label, double height) {
    final c = context.colors;
    final selected = value == selectedValue;

    final fill = selected
        ? (_isPrimary ? c.ink : c.primary)
        : Colors.transparent;
    final labelColor = selected
        ? (_isPrimary ? Colors.white : c.ink)
        : c.mutedFilter;

    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 72),
        padding: EdgeInsets.symmetric(horizontal: _isPrimary ? 4 : 18),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: KolabingRadius.borderRadiusPill,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: KolabingTextStyles.button.copyWith(
              fontSize: _isPrimary ? 12.5 : 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.4,
              color: labelColor,
            ),
          ),
        ),
      ),
    );
  }
}
