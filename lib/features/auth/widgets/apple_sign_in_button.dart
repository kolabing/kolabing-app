import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

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
          color: Colors.black,
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: _buildContent(),
      ),
    ),
  );

  Widget _buildContent() {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    if (widget.showSuccess) {
      return const Center(
        child: Icon(Icons.check_rounded, size: 24, color: Colors.white),
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
              const Icon(Icons.apple, size: 24, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.buttonText,
                style: KolabingTextStyles.button.copyWith(
                  color: Colors.white,
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
