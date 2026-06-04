// lib/widgets/glass_icon_button.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/theme/colors.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          label: semanticsLabel ?? tooltip,
          button: true,
          child: GestureDetector(
            onTap: onPressed,
            child: Opacity(
              opacity: onPressed == null ? 0.45 : 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14785A28),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: KolabingColors.glassInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
