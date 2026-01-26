import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';

/// Type selection card for business/community type selection
class TypeSelectionCard extends StatefulWidget {
  const TypeSelectionCard({
    required this.id,
    required this.name,
    required this.onTap,
    super.key,
    this.icon,
    this.isSelected = false,
  });

  /// Type ID
  final String id;

  /// Display name
  final String name;

  /// Optional icon (emoji)
  final String? icon;

  /// Whether this card is selected
  final bool isSelected;

  /// Callback when tapped
  final VoidCallback onTap;

  @override
  State<TypeSelectionCard> createState() => _TypeSelectionCardState();
}

class _TypeSelectionCardState extends State<TypeSelectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 96,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? KolabingColors.softYellow
                  : KolabingColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.isSelected ? KolabingColors.primary : KolabingColors.border,
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? KolabingColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFF374957).withValues(alpha: 0.04),
                  blurRadius: widget.isSelected ? 8 : 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                if (widget.icon != null)
                  Text(
                    widget.icon!,
                    style: const TextStyle(fontSize: 32),
                  ),
                const SizedBox(height: 8),

                // Name
                Text(
                  widget.name,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
}
