import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/user_model.dart';

/// Segmented control for selecting user type (Business or Community)
///
/// A pill-style toggle that animates smoothly between options.
/// Default selection is Business.
class UserTypeToggle extends StatefulWidget {
  const UserTypeToggle({
    required this.selectedType,
    required this.onChanged,
    super.key,
    this.isEnabled = true,
  });

  /// Currently selected user type
  final UserType selectedType;

  /// Callback when selection changes
  final ValueChanged<UserType> onChanged;

  /// Whether the toggle is interactive
  final bool isEnabled;

  @override
  State<UserTypeToggle> createState() => _UserTypeToggleState();
}

class _UserTypeToggleState extends State<UserTypeToggle>
    with SingleTickerProviderStateMixin {
  /// Animation controller for sliding pill
  late final AnimationController _animationController;

  /// Position animation (0.0 = left/business, 1.0 = right/community)
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: widget.selectedType == UserType.business ? 0.0 : 1.0,
      end: widget.selectedType == UserType.business ? 0.0 : 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(UserTypeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedType != oldWidget.selectedType) {
      _animateToType(widget.selectedType);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateToType(UserType type) {
    final targetValue = type == UserType.business ? 0.0 : 1.0;

    _positionAnimation = Tween<double>(
      begin: _positionAnimation.value,
      end: targetValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController
      ..reset()
      ..forward();
  }

  void _handleTap(UserType type) {
    if (!widget.isEnabled || type == widget.selectedType) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    widget.onChanged(type);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label:
            'Select account type. Two options: Business or Community. Currently selected: ${widget.selectedType.label}. Double tap to switch.',
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isEnabled ? 1.0 : 0.6,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: KolabingColors.darkBorder,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = (constraints.maxWidth - 4) / 2;

                return Stack(
                  children: [
                    // Animated selection pill
                    AnimatedBuilder(
                      animation: _positionAnimation,
                      builder: (context, child) => Positioned(
                        left: _positionAnimation.value * (segmentWidth + 4),
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: KolabingColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Segment buttons
                    Row(
                      children: [
                        _buildSegment(
                          type: UserType.business,
                          width: segmentWidth,
                        ),
                        const SizedBox(width: 4),
                        _buildSegment(
                          type: UserType.community,
                          width: segmentWidth,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

  Widget _buildSegment({
    required UserType type,
    required double width,
  }) {
    final isSelected = widget.selectedType == type;

    return GestureDetector(
      onTap: () => _handleTap(type),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 40,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: KolabingTextStyles.labelLarge.copyWith(
              color: isSelected
                  ? KolabingColors.onPrimary
                  : KolabingColors.textOnDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.8,
            ),
            child: Text(type.label),
          ),
        ),
      ),
    );
  }
}
