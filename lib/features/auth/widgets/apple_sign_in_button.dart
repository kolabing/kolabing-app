import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// Apple Sign In button matching the app's design system
class AppleSignInButton extends StatefulWidget {
  const AppleSignInButton({
    required this.onPressed,
    super.key,
    this.buttonText = 'Sign in with Apple',
    this.isLoading = false,
    this.showSuccess = false,
    this.isEnabled = true,
    this.height = 52,
    this.light = false,
  });

  /// Apple's white-outline style: white fill, ink logo and label.
  final bool light;

  final VoidCallback? onPressed;
  final String buttonText;
  final bool isLoading;
  final bool showSuccess;
  final bool isEnabled;
  final double height;

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool get _canInteract =>
      widget.isEnabled &&
      !widget.isLoading &&
      !widget.showSuccess &&
      widget.onPressed != null;

  Color get _foreground => widget.light ? KolabingColors.ink : Colors.white;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      if (!_canInteract) return;
      HapticFeedback.mediumImpact();
      widget.onPressed?.call();
    },
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: _canInteract ? 1.0 : 0.6,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.light ? KolabingColors.surface : Colors.black,
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: widget.light
                ? KolabingColors.outlineVariant
                : Colors.white.withValues(alpha: 0.16),
            width: widget.light ? 1.2 : 1,
          ),
        ),
        child: _buildContent(),
      ),
    ),
  );

  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(_foreground),
          ),
        ),
      );
    }
    if (widget.showSuccess) {
      return Center(
        child: Icon(Icons.check_rounded, size: 24, color: _foreground),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apple, size: 24, color: _foreground),
              const SizedBox(width: 10),
              Text(
                widget.buttonText,
                style: KolabingTextStyles.button.copyWith(
                  color: _foreground,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
