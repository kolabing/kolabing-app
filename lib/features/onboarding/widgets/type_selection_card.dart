import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/category_icon.dart';

/// Type selection card for business/community type selection.
///
/// 2-column layout: custom SVG illustration at top, full name below.
class TypeSelectionCard extends StatefulWidget {
  const TypeSelectionCard({
    required this.id,
    required this.name,
    required this.onTap,
    super.key,
    this.icon,
    this.iconUrl,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final String? icon;

  /// Admin-uploaded SVG URL (rendered over the bundled asset when present).
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<TypeSelectionCard> createState() => _TypeSelectionCardState();
}

class _TypeSelectionCardState extends State<TypeSelectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

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
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: widget.isSelected ? context.colors.softYellow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? context.colors.primary
                : const Color(0xFFE2E8F0),
            width: widget.isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isSelected
                  ? context.colors.primary.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: widget.isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category illustration
              CategoryIcon(
                name: widget.name,
                iconUrl: widget.iconUrl,
                size: 40,
              ),
              const SizedBox(height: 6),
              // Name — full text, up to 2 lines, centred
              Text(
                widget.name,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Selection indicator dot
              if (widget.isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
