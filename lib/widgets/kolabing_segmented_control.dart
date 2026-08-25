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
    this.scrollable = false,
    this.maxLines = 1,
  });

  /// Ordered (value, label) pairs. Labels are rendered as-is (callers
  /// control casing/copy).
  final List<(T value, String label)> segments;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final KolabingSegmentedStyle style;

  /// Primary style only. When true the track scrolls horizontally and each
  /// segment sizes to its own label instead of being squeezed into an equal
  /// share of the row.
  ///
  /// Use it for filter rows with many (or long, or long-in-`es`/`ca`) labels:
  /// equal-width segments have to shrink their text to fit five Catalan words
  /// on a 320dp phone, which is exactly the unreadable result this avoids.
  /// Scrolling costs discoverability of the last segment; shrinking costs
  /// legibility of all of them.
  final bool scrollable;

  /// Allowing more than one line switches the label off the shrink-to-fit
  /// path and lets it wrap at a fixed, readable size. Use it when a segment
  /// label is a phrase rather than a word (e.g. "Businesses and
  /// communities") and the control must stay a fixed three-up row.
  final int maxLines;

  bool get _isPrimary => style == KolabingSegmentedStyle.primary;

  /// Only the single-line, equal-width case may shrink text to fit. Anything
  /// else renders at the full 12.5pt.
  bool get _shrinkToFit => maxLines == 1 && !scrollable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Both styles share the same track language (white pill + hairline) so the
    // secondary row reads as a real toggle. Secondary is taller-enough to keep
    // a comfortable tap target and drops the shadow to stay subordinate.
    // A wrapping control has to grow instead of clipping its second line.
    final height = maxLines > 1 ? null : (_isPrimary ? 38.0 : 40.0);
    final scrolls = _isPrimary && scrollable;

    final track = Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: KolabingRadius.borderRadiusPill,
        border: Border.all(color: c.controlBorder, width: 1),
        boxShadow: _isPrimary ? const [KolabingShadows.card] : null,
      ),
      child: _row(context, scrolls: scrolls),
    );

    if (scrolls) {
      // The track keeps its pill shape and hugs its content; the row scrolls
      // under it. `clipBehavior: none` so the shadow is not cut off.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const ClampingScrollPhysics(),
        child: track,
      );
    }

    // Primary fills the row; secondary sizes to its content and lets the caller
    // decide alignment (centered in My Kolabs).
    return _isPrimary ? SizedBox(width: double.infinity, child: track) : track;
  }

  Widget _row(BuildContext context, {required bool scrolls}) {
    final row = Row(
      // Wrapping segments end up with different line counts; stretching keeps
      // every pill the same height instead of leaving the short ones floating.
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      mainAxisSize: (_isPrimary && !scrolls)
          ? MainAxisSize.max
          : MainAxisSize.min,
      children: [
        for (final (value, label) in segments)
          (_isPrimary && !scrolls)
              ? Expanded(child: _segment(context, value, label))
              : _segment(context, value, label),
      ],
    );

    // `stretch` needs a bounded cross-axis extent, and these controls live in
    // scroll views where the height is unbounded. Three short segments make
    // IntrinsicHeight's extra layout pass negligible.
    return maxLines > 1 ? IntrinsicHeight(child: row) : row;
  }

  Widget _segment(BuildContext context, T value, String label) {
    final c = context.colors;
    final selected = value == selectedValue;

    final fill = selected
        ? (_isPrimary ? c.ink : c.primary)
        : Colors.transparent;
    final labelColor = selected
        ? (_isPrimary ? Colors.white : c.ink)
        : c.mutedFilter;

    // Equal-width segments can only afford 4pt of inset before the labels
    // start colliding with the pill edge; a self-sized segment gets real
    // breathing room on both sides.
    final horizontalPadding = _isPrimary ? (scrollable ? 16.0 : 6.0) : 18.0;

    final text = Text(
      label,
      maxLines: maxLines,
      softWrap: maxLines > 1,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: KolabingTextStyles.button.copyWith(
        fontSize: 12.5,
        height: maxLines > 1 ? 1.15 : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: 0.4,
        color: labelColor,
      ),
    );

    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 72, minHeight: 30),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: maxLines > 1 ? 6 : 0,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: KolabingRadius.borderRadiusPill,
        ),
        alignment: Alignment.center,
        child: _shrinkToFit
            ? FittedBox(fit: BoxFit.scaleDown, child: text)
            : text,
      ),
    );
  }
}
