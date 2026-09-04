import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import 'google_logo.dart';

/// Button states for visual feedback
enum _ButtonState { idle, pressed, loading, success }

/// Google Sign In button with loading and success states
///
/// A yellow primary button that triggers Google OAuth flow.
/// Shows loading spinner during authentication and checkmark on success.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    required this.onPressed,
    super.key,
    this.buttonText = 'Sign in with Google',
    this.isLoading = false,
    this.showSuccess = false,
    this.isEnabled = true,
    this.height = 52,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button text to display
  final String buttonText;

  /// Whether to show loading state
  final bool isLoading;

  /// Whether to show success state
  final bool showSuccess;

  /// Whether button is enabled
  final bool isEnabled;

  /// Button height
  final double height;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  /// Animation controller for press/release
  late final AnimationController _animationController;

  /// Scale animation
  late final Animation<double> _scaleAnimation;

  /// Current button state
  _ButtonState _state = _ButtonState.idle;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(GoogleSignInButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showSuccess && !oldWidget.showSuccess) {
      setState(() {
        _state = _ButtonState.success;
      });
    } else if (widget.isLoading && !oldWidget.isLoading) {
      setState(() {
        _state = _ButtonState.loading;
      });
    } else if (!widget.isLoading && !widget.showSuccess) {
      setState(() {
        _state = _ButtonState.idle;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_canInteract) return;
    _animationController.forward();
    setState(() {
      _state = _ButtonState.pressed;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_canInteract) return;
    _animationController.reverse();
    setState(() {
      _state = _ButtonState.idle;
    });
  }

  void _handleTapCancel() {
    if (!_canInteract) return;
    _animationController.reverse();
    setState(() {
      _state = _ButtonState.idle;
    });
  }

  void _handleTap() {
    if (!_canInteract) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    widget.onPressed?.call();
  }

  bool get _canInteract =>
      widget.isEnabled &&
      !widget.isLoading &&
      !widget.showSuccess &&
      widget.onPressed != null;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: _canInteract,
    label: widget.isLoading
        ? 'Signing in with Google'
        : widget.showSuccess
        ? 'Sign in successful'
        : '${widget.buttonText} button. Tap to authenticate with your Google account.',
    child: GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _canInteract ? 1.0 : 0.6,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: KolabingColors.buttonSecondary,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: _buildContent(),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 150),
    child: _state == _ButtonState.loading
        ? _buildLoadingContent()
        : _state == _ButtonState.success
        ? _buildSuccessContent()
        : _buildDefaultContent(),
  );

  Widget _buildDefaultContent() => Padding(
    key: const ValueKey('default'),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoogleLogo(),
            const SizedBox(width: 10),
            Text(
              widget.buttonText,
              style: KolabingTextStyles.button.copyWith(
                color: KolabingColors.onButtonSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildLoadingContent() => const Center(
    key: ValueKey('loading'),
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C1C16)),
      ),
    ),
  );

  Widget _buildSuccessContent() => const Center(
    key: ValueKey('success'),
    child: Icon(Icons.check_rounded, size: 24, color: Color(0xFF1C1C16)),
  );
}

/// Google "G" icon widget
