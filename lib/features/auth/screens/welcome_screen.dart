import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../widgets/kolabing_logo.dart';

/// Welcome screen - Landing page after splash
///
/// Light themed screen with logo, tagline, and Login/Create Account buttons.
/// Features staggered entry animations.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;

  // Staggered animations for each element
  late final Animation<double> _logoAnimation;
  late final Animation<double> _appNameAnimation;
  late final Animation<double> _headlineAnimation;
  late final Animation<double> _descriptionAnimation;
  late final Animation<double> _buttonsAnimation;

  // Slide animations
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<Offset> _appNameSlideAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<Offset> _descriptionSlideAnimation;
  late final Animation<Offset> _buttonsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _configureSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Staggered opacity animations
    _logoAnimation = _createOpacityAnimation(0.0, 0.4);
    _appNameAnimation = _createOpacityAnimation(0.08, 0.48);
    _headlineAnimation = _createOpacityAnimation(0.17, 0.57);
    _descriptionAnimation = _createOpacityAnimation(0.25, 0.65);
    _buttonsAnimation = _createOpacityAnimation(0.33, 0.73);

    // Staggered slide animations (20dp up)
    _logoSlideAnimation = _createSlideAnimation(0.0, 0.4);
    _appNameSlideAnimation = _createSlideAnimation(0.08, 0.48);
    _headlineSlideAnimation = _createSlideAnimation(0.17, 0.57);
    _descriptionSlideAnimation = _createSlideAnimation(0.25, 0.65);
    _buttonsSlideAnimation = _createSlideAnimation(0.33, 0.73);
  }

  Animation<double> _createOpacityAnimation(double begin, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _createSlideAnimation(double begin, double end) =>
      Tween<Offset>(begin: const Offset(0, 20), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  void _startEntryAnimation() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    context.push(KolabingRoutes.login);
  }

  void _navigateToUserTypeSelection() {
    HapticFeedback.lightImpact();
    context.push(KolabingRoutes.userTypeSelection);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KolabingColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Logo
            _AnimatedElement(
              opacityAnimation: _logoAnimation,
              slideAnimation: _logoSlideAnimation,
              child: const KolabingLogo(
                size: KolabingLogoSize.xLarge,
                variant: KolabingLogoVariant.yellowCircle,
                showText: false,
                onDarkBackground: false,
              ),
            ),

            const SizedBox(height: 12),

            // App name
            _AnimatedElement(
              opacityAnimation: _appNameAnimation,
              slideAnimation: _appNameSlideAnimation,
              child: Text(
                'Kolabing',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Headline
            _AnimatedElement(
              opacityAnimation: _headlineAnimation,
              slideAnimation: _headlineSlideAnimation,
              child: Text(
                'WHERE BRANDS MEET\nCOMMUNITIES',
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: KolabingColors.textPrimary,
                  letterSpacing: 1.5,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            _AnimatedElement(
              opacityAnimation: _descriptionAnimation,
              slideAnimation: _descriptionSlideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Connect with the perfect collaboration partner to grow your business or community together',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: KolabingColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Buttons
            _AnimatedElement(
              opacityAnimation: _buttonsAnimation,
              slideAnimation: _buttonsSlideAnimation,
              child: Column(
                children: [
                  // Login Button (Primary)
                  _PrimaryButton(text: 'LOGIN', onPressed: _navigateToLogin),

                  const SizedBox(height: 12),

                  // Create Account Button (Secondary)
                  _SecondaryButton(
                    text: 'CREATE ACCOUNT',
                    onPressed: _navigateToUserTypeSelection,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    ),
  );
}

/// Animated wrapper for staggered entry
class _AnimatedElement extends StatelessWidget {
  const _AnimatedElement({
    required this.opacityAnimation,
    required this.slideAnimation,
    required this.child,
  });

  final Animation<double> opacityAnimation;
  final Animation<Offset> slideAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: opacityAnimation,
    builder: (context, child) => Transform.translate(
      offset: slideAnimation.value,
      child: Opacity(opacity: opacityAnimation.value, child: child),
    ),
    child: child,
  );
}

/// Primary yellow button
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _isPressed = true),
    onTapUp: (_) => setState(() => _isPressed = false),
    onTapCancel: () => setState(() => _isPressed = false),
    onTap: widget.onPressed,
    child: AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _isPressed ? 0.98 : 1.0,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _isPressed
              ? KolabingColors.primaryDark
              : KolabingColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF374957).withValues(alpha: 0.11),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.text,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onPrimary,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Secondary outlined button
class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _isPressed = true),
    onTapUp: (_) => setState(() => _isPressed = false),
    onTapCancel: () => setState(() => _isPressed = false),
    onTap: widget.onPressed,
    child: AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _isPressed ? 0.98 : 1.0,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: _isPressed
              ? KolabingColors.surfaceVariant
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KolabingColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    ),
  );
}
