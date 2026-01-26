import 'package:flutter/material.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// Footer navigation link for auth screens
///
/// Displays text like "Don't have an account? Sign Up" with
/// the action text highlighted in primary color.
class AuthLink extends StatefulWidget {
  const AuthLink({
    required this.leadingText,
    required this.actionText,
    required this.onTap,
    super.key,
    this.isEnabled = true,
  });

  /// Text before the action link
  final String leadingText;

  /// Action link text (highlighted)
  final String actionText;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Whether the link is interactive
  final bool isEnabled;

  @override
  State<AuthLink> createState() => _AuthLinkState();
}

class _AuthLinkState extends State<AuthLink> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: widget.isEnabled,
        label: '${widget.leadingText} Tap ${widget.actionText} to navigate',
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: widget.isEnabled ? 1.0 : 0.5,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: _isPressed ? 0.98 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                constraints: const BoxConstraints(minHeight: 48),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: KolabingColors.textOnDark,
                    ),
                    children: [
                      TextSpan(text: '${widget.leadingText} '),
                      TextSpan(
                        text: widget.actionText,
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          color: KolabingColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration:
                              _isPressed ? TextDecoration.underline : null,
                          decorationColor: KolabingColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
