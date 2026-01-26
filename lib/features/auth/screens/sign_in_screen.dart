import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_link.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/kolabing_logo.dart';

/// Sign In screen with Google OAuth
///
/// Minimal dark-themed screen for returning users.
/// No user type selection - determined from existing account.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with TickerProviderStateMixin {
  /// Animation controller for staggered entry
  late final AnimationController _entryController;

  /// Animation controller for exit
  late final AnimationController _exitController;

  /// Individual element animations
  late final Animation<double> _logoAnimation;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _subtitleAnimation;
  late final Animation<double> _buttonAnimation;
  late final Animation<double> _linkAnimation;
  late final Animation<double> _exitAnimation;

  /// Loading and success states
  bool _isLoading = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _configureSystemUI();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Staggered entry animations
    _logoAnimation = _createStaggeredAnimation(0.0, 0.5);
    _titleAnimation = _createStaggeredAnimation(0.15, 0.65);
    _subtitleAnimation = _createStaggeredAnimation(0.25, 0.75);
    _buttonAnimation = _createStaggeredAnimation(0.35, 0.85);
    _linkAnimation = _createStaggeredAnimation(0.5, 1.0);

    // Exit fade animation
    _exitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeIn,
    ));
  }

  Animation<double> _createStaggeredAnimation(double begin, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: KolabingColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _startEntryAnimation() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _showSuccess) return;

    setState(() {
      _isLoading = true;
    });

    final result = await ref.read(authProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      // Wait for success animation, then navigate
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Start exit animation
      await _exitController.forward();

      if (!mounted) return;

      // Navigate based on user state
      final route = _getNavigationRoute(result);
      context.go(route);
    } else if (result.cancelled) {
      setState(() {
        _isLoading = false;
      });
    } else if (result.isUserTypeMismatch) {
      setState(() {
        _isLoading = false;
      });
      _showUserTypeMismatchDialog(result.existingUserType);
    } else if (result.isNetworkError) {
      setState(() {
        _isLoading = false;
      });
      _showNetworkErrorSnackBar();
    } else {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(result.displayError);
    }
  }

  String _getNavigationRoute(AuthResult result) {
    if (result.isNewUser || !(result.user?.onboardingCompleted ?? false)) {
      return '/onboarding';
    }

    return result.user?.isBusiness ?? false ? '/business' : '/community';
  }

  void _showUserTypeMismatchDialog(UserType? existingType) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _UserTypeMismatchDialog(
        existingType: existingType,
        onGotIt: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showNetworkErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: KolabingColors.textOnDark,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No internet connection. Please check your network.',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: KolabingColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: KolabingColors.textOnDark,
          onPressed: _handleGoogleSignIn,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.textOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: KolabingColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: KolabingColors.textOnDark,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _navigateToSignUp() {
    context.go('/auth/sign-up');
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_isLoading,
        child: Scaffold(
          backgroundColor: KolabingColors.darkBackground,
          body: AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) => Opacity(
              opacity: _exitAnimation.value,
              child: child,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo
                    _AnimatedElement(
                      animation: _logoAnimation,
                      child: const KolabingLogo(
                        size: KolabingLogoSize.large,
                        showText: true,
                        onDarkBackground: true,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    _AnimatedElement(
                      animation: _titleAnimation,
                      slideUp: true,
                      child: Text(
                        'WELCOME BACK',
                        style: KolabingTextStyles.displayLarge.copyWith(
                          color: KolabingColors.textOnDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    _AnimatedElement(
                      animation: _subtitleAnimation,
                      slideUp: true,
                      child: Text(
                        'Sign in to continue',
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          color: KolabingColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Google Sign In Button
                    _AnimatedElement(
                      animation: _buttonAnimation,
                      slideUp: true,
                      child: GoogleSignInButton(
                        onPressed: _handleGoogleSignIn,
                        buttonText: 'Sign in with Google',
                        isLoading: _isLoading,
                        showSuccess: _showSuccess,
                        isEnabled: !_isLoading && !_showSuccess,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign Up Link
                    _AnimatedElement(
                      animation: _linkAnimation,
                      child: AuthLink(
                        leadingText: "Don't have an account?",
                        actionText: 'Sign Up',
                        onTap: _navigateToSignUp,
                        isEnabled: !_isLoading && !_showSuccess,
                      ),
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Animated wrapper for staggered entry
class _AnimatedElement extends StatelessWidget {
  const _AnimatedElement({
    required this.animation,
    required this.child,
    this.slideUp = false,
  });

  final Animation<double> animation;
  final Widget child;
  final bool slideUp;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          offset: slideUp ? Offset(0, 20 * (1 - animation.value)) : Offset.zero,
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        ),
        child: child,
      );
}

/// Dialog for user type mismatch error
class _UserTypeMismatchDialog extends StatelessWidget {
  const _UserTypeMismatchDialog({
    required this.existingType,
    required this.onGotIt,
  });

  final UserType? existingType;
  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: KolabingColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Account Type Mismatch',
                style: KolabingTextStyles.headlineMedium.copyWith(
                  color: KolabingColors.textOnDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This Google account is registered as a ${existingType?.label ?? 'different'} user. Please sign in from the correct screen.',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFCCCCCC),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onGotIt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: KolabingTextStyles.button.copyWith(
                      color: KolabingColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
