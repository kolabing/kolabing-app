import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme/colors.dart';
import '../features/discovery/models/discovery_item.dart';

/// H1: a compact "mini-model" rendering of how a discovery match score was
/// computed. Shows each signal as a tiny weight bar so users can answer the
/// "why is this card a 95% match?" question at a glance without tapping in.
///
/// The signals are ordered as the backend returns them (highest-weight first).
class MatchBreakdown extends StatelessWidget {
  const MatchBreakdown({
    super.key,
    required this.signals,
    this.compact = false,
    this.color,
  });

  final List<DiscoveryMatchSignal> signals;

  /// When true, each signal renders as a single thin row (used on cards).
  /// When false, signals get more vertical room (used on detail sheets).
  final bool compact;

  /// Optional accent color for the filled portion of the weight bar.
  /// Defaults to [KolabingColors.primary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) return const SizedBox.shrink();

    final accent = color ?? KolabingColors.primary;
    final rowGap = compact ? 4.0 : 6.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < signals.length; i++) ...[
          _SignalRow(
            signal: signals[i],
            accent: accent,
            compact: compact,
          ),
          if (i < signals.length - 1) SizedBox(height: rowGap),
        ],
      ],
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.signal,
    required this.accent,
    required this.compact,
  });

  final DiscoveryMatchSignal signal;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Visual weight: combine algorithm weight × per-signal score so the bar
    // reflects this signal's actual contribution to the displayed match %.
    final visual = (signal.weight * signal.score).clamp(0.0, 1.0);
    final cells = compact ? 6 : 8;
    final filled = (visual * cells).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            signal.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CellRow(
          cells: cells,
          filled: filled,
          accent: accent,
          compact: compact,
        ),
      ],
    );
  }
}

class _CellRow extends StatelessWidget {
  const _CellRow({
    required this.cells,
    required this.filled,
    required this.accent,
    required this.compact,
  });

  final int cells;
  final int filled;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cellWidth = compact ? 6.0 : 8.0;
    final cellHeight = compact ? 5.0 : 6.0;
    final gap = compact ? 2.0 : 3.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cells; i++) ...[
          Container(
            width: cellWidth,
            height: cellHeight,
            decoration: BoxDecoration(
              color: i < filled
                  ? accent
                  : KolabingColors.darkBorder.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          if (i < cells - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}
