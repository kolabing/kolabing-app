import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';

/// Type selection card for business/community type selection.
///
/// 2-column layout: large emoji at top, full name wrapping on 2 lines below.
class TypeSelectionCard extends StatefulWidget {
  const TypeSelectionCard({
    required this.id,
    required this.name,
    required this.onTap,
    super.key,
    this.icon,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final String? icon;
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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

  /// Returns the best emoji for this type, falling back to a keyword map.
  String get _emoji {
    final icon = widget.icon?.trim() ?? '';
    if (icon.isNotEmpty) return icon;

    // Keyword → emoji map (checked against the type name, case-insensitive)
    const map = <String, String>{
      'run': '🏃',
      'fitness': '💪',
      'wellness': '🧘',
      'yoga': '🧘',
      'meditation': '🧘',
      'art': '🎨',
      'creative': '🎨',
      'photography': '📸',
      'photo': '📸',
      'music': '🎵',
      'dance': '💃',
      'tech': '💻',
      'startup': '🚀',
      'book': '📚',
      'reading': '📚',
      'sustainab': '🌱',
      'eco': '🌱',
      'food': '🍽️',
      'culinar': '🍽️',
      'travel': '✈️',
      'fashion': '👗',
      'style': '👗',
      'gaming': '🎮',
      'game': '🎮',
      'sport': '⚽',
      'film': '🎬',
      'cinema': '🎬',
      'parent': '👶',
      'family': '👨‍👩‍👧',
      'student': '🎓',
      'educat': '🎓',
      'entrepreneur': '💼',
      'business': '💼',
      'pet': '🐾',
      'animal': '🐾',
      'outdoor': '🏕️',
      'hik': '🥾',
      'cycling': '🚴',
      'bike': '🚴',
      'swim': '🏊',
      'surf': '🏄',
      'skate': '🛹',
      'social': '🤝',
      'community': '🏘️',
      'local': '📍',
      'neighbor': '📍',
      'health': '❤️',
      'mental': '🧠',
      'beauty': '💄',
      'comedy': '😂',
      'podcast': '🎙️',
      'influencer': '⭐',
    };

    final nameLower = widget.name.toLowerCase();
    for (final entry in map.entries) {
      if (nameLower.contains(entry.key)) return entry.value;
    }
    return '🤝';
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
              color: widget.isSelected
                  ? KolabingColors.softYellow
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? KolabingColors.primary
                    : const Color(0xFFE2E8F0),
                width: widget.isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? KolabingColors.primary.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: widget.isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Text(
                    _emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 10),
                  // Name — full text, up to 2 lines, centred
                  Text(
                    widget.name,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.textPrimary,
                      height: 1.3,
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
                      decoration: const BoxDecoration(
                        color: KolabingColors.primary,
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
