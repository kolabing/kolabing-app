import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/wallet_model.dart';

/// An animated horizontal progress bar showing points toward the withdrawal
/// threshold.
///
/// Displays a label row ("X pts" on the left, "375 pts = EUR75" on the right)
/// and an 8 px track with an animated fill. The bar turns green when the user
/// reaches 100 % of the target.
class PointsProgressBar extends StatefulWidget {
  const PointsProgressBar({
    required this.currentPoints,
    this.targetPoints = WalletModel.withdrawalThreshold,
    this.animate = true,
    this.showLabel = true,
    this.darkMode = false,
    super.key,
  });

  /// Current point balance.
  final int currentPoints;

  /// Target points for the next milestone (defaults to 375).
  final int targetPoints;

  /// Whether the bar should animate from 0 to its current value.
  final bool animate;

  /// Whether to show the label row above the bar.
  final bool showLabel;

  /// When true, uses dark-mode colors (e.g. inside the wallet card).
  final bool darkMode;

  @override
  State<PointsProgressBar> createState() => _PointsProgressBarState();
}

class _PointsProgressBarState extends State<PointsProgressBar> {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double get _progress =>
      (widget.currentPoints / widget.targetPoints).clamp(0.0, 1.0);

  bool get _isComplete => _progress >= 1.0;

  Color get _trackColor => widget.darkMode
      ? Colors.black.withValues(alpha: 0.20)
      : KolabingColors.border;

  Color get _fillColor => _isComplete
      ? KolabingColors.success
      : (widget.darkMode ? Colors.black : KolabingColors.primary);

  Color get _labelColor =>
      widget.darkMode ? Colors.black.withValues(alpha: 0.70) : KolabingColors.textSecondary;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showLabel) ...[
            _buildLabelRow(),
            const SizedBox(height: KolabingSpacing.xxs),
          ],
          _buildTrack(),
        ],
      );

  Widget _buildLabelRow() {
    final eurTarget = (widget.targetPoints * 0.20).toStringAsFixed(0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${widget.currentPoints} pts',
          style: GoogleFonts.openSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
        Text(
          '${widget.targetPoints} pts = \u20AC$eurTarget',
          style: GoogleFonts.openSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTrack() => SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Stack(
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _trackColor,
                  borderRadius: KolabingRadius.borderRadiusRound,
                ),
              ),
              // Animated fill
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: widget.animate ? 0.0 : _progress,
                  end: _progress,
                ),
                duration: widget.animate
                    ? const Duration(milliseconds: 600)
                    : Duration.zero,
                curve: Curves.easeOut,
                builder: (context, value, _) => Container(
                  height: 8,
                  width: (value * maxWidth).clamp(0.0, maxWidth),
                  decoration: BoxDecoration(
                    color: _fillColor,
                    borderRadius: KolabingRadius.borderRadiusRound,
                  ),
                ),
              ),
              // Threshold dot at 100 % position
              Positioned(
                left: (maxWidth - 6).clamp(0.0, maxWidth),
                top: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isComplete
                        ? KolabingColors.success
                        : (widget.darkMode
                            ? Colors.black.withValues(alpha: 0.40)
                            : KolabingColors.textTertiary),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
}
