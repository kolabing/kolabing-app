// lib/widgets/glass_icon_button.dart
import 'package:flutter/material.dart';

import '../config/theme/colors.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.semanticsLabel,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? semanticsLabel;

  /// Diameter of the circular button. Defaults to 44 (touch-target size).
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: semanticsLabel ?? tooltip,
        button: true,
        child: GestureDetector(
          onTap: onPressed,
          child: Opacity(
            opacity: onPressed == null ? 0.45 : 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: c.hairline),
              ),
              child: Icon(icon, size: size * 0.41, color: c.glassInk),
            ),
          ),
        ),
      ),
    );
  }
}
