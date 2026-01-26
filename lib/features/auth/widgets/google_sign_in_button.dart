import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// Button states for visual feedback
enum _ButtonState {
  idle,
  pressed,
  loading,
  success,
}

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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
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
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _canInteract ? 1.0 : 0.6,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: KolabingColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF374957).withValues(alpha: 0.11),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            const SizedBox(width: 12),
            Text(
              widget.buttonText.toUpperCase(),
              style: KolabingTextStyles.button.copyWith(
                color: KolabingColors.onPrimary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );

  Widget _buildLoadingContent() => const Center(
        key: ValueKey('loading'),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(KolabingColors.onPrimary),
          ),
        ),
      );

  Widget _buildSuccessContent() => const Center(
        key: ValueKey('success'),
        child: Icon(
          Icons.check_rounded,
          size: 24,
          color: KolabingColors.onPrimary,
        ),
      );
}

/// Google "G" icon widget
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.string(
          _googleIconSvg,
          width: 24,
          height: 24,
        ),
      );
}

/// Google "G" logo SVG
const String _googleIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>
''';
