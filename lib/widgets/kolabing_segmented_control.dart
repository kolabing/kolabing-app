import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants/layout.dart';
import '../config/constants/radius.dart';
import '../config/theme/color_tokens.dart';

/// Visual weight of a [KolabingSegmentedControl].
enum KolabingSegmentedStyle {
  /// Full-width, white track + border + shadow, ink fill on the selected
  /// segment. Use for the primary filter row (e.g. status tabs).
  primary,

  /// Narrower, trackless, yellow fill on the selected segment. Use for a
  /// secondary filter row nested under a primary one.
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
    final height = _isPrimary ? 38.0 : 34.0;

    final track = Container(
      height: height,
      padding: _isPrimary ? const EdgeInsets.all(4) : EdgeInsets.zero,
      decoration: _isPrimary
          ? BoxDecoration(
              color: c.surface,
              borderRadius: KolabingRadius.borderRadiusPill,
              border: Border.all(color: c.controlBorder, width: 1),
              boxShadow: const [KolabingShadows.card],
            )
          : null,
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

    return _isPrimary
        ? SizedBox(width: double.infinity, child: track)
        : FractionallySizedBox(
            widthFactor: 0.6,
            alignment: Alignment.centerLeft,
            child: track,
          );
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

    return Padding(
      padding: _isPrimary ? EdgeInsets.zero : const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: _isPrimary ? 4 : 14),
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
              style: GoogleFonts.inter(
                fontSize: _isPrimary ? 12.5 : 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: _isPrimary ? 0.3 : 0.4,
                color: labelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
