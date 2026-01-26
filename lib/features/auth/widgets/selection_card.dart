import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';

/// User type for selection cards
enum SelectionUserType {
  business,
  community,
}

/// Selection card for user type (Business or Community)
///
/// Interactive card with icon, title, and description.
/// Shows selected state with yellow border.
class SelectionCard extends StatefulWidget {
  const SelectionCard({
    required this.userType,
    required this.onTap,
    super.key,
    this.isSelected = false,
    this.isEnabled = true,
  });

  /// The user type this card represents
  final SelectionUserType userType;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Whether the card is interactive
  final bool isEnabled;

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  String get _icon =>
      widget.userType == SelectionUserType.business ? '\u{1F3E2}' : '\u{1F465}';

  String get _title => widget.userType == SelectionUserType.business
      ? "I'M A BUSINESS"
      : "I'M A COMMUNITY";

  String get _description => widget.userType == SelectionUserType.business
      ? 'Looking for communities to partner with'
      : 'Seeking sponsors and collaboration partners';

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: widget.isEnabled,
        selected: widget.isSelected,
        label: '$_title. $_description',
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _isPressed || widget.isSelected
                  ? _scaleAnimation.value
                  : 1.0,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: KolabingColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed || widget.isSelected
                      ? KolabingColors.primary
                      : KolabingColors.border,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isPressed || widget.isSelected
                        ? KolabingColors.primary.withValues(alpha: 0.20)
                        : const Color(0xFF374957).withValues(alpha: 0.10),
                    blurRadius: _isPressed || widget.isSelected ? 16 : 8,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Text(
                    _icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _title,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _description,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: KolabingColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
