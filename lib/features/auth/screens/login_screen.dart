import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../services/permission_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/kolabing_logo.dart';

/// Login Screen for existing users
///
/// Dark themed screen with email/password login and Google Sign In option.
/// Google login is for existing users only.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late final AnimationController _entryController;
  late final AnimationController _exitController;

  // Staggered animations
  late final Animation<double> _logoAnimation;
  late final Animation<double> _headlineAnimation;
  late final Animation<double> _formAnimation;
  late final Animation<double> _buttonAnimation;
  late final Animation<double> _dividerAnimation;
  late final Animation<double> _googleAnimation;
  late final Animation<double> _linkAnimation;

  // Slide animations
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<Offset> _buttonSlideAnimation;

  late final Animation<double> _exitAnimation;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _startEntryAnimation();
  }

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

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Staggered opacity animations
    _logoAnimation = _createOpacityAnimation(0.0, 0.4);
    _headlineAnimation = _createOpacityAnimation(0.1, 0.5);
    _formAnimation = _createOpacityAnimation(0.2, 0.6);
    _buttonAnimation = _createOpacityAnimation(0.3, 0.7);
    _dividerAnimation = _createOpacityAnimation(0.4, 0.8);
    _googleAnimation = _createOpacityAnimation(0.5, 0.9);
    _linkAnimation = _createOpacityAnimation(0.6, 1.0);

    // Slide animations (30dp up as per spec)
    _logoSlideAnimation = _createSlideAnimation(0.0, 0.4);
    _headlineSlideAnimation = _createSlideAnimation(0.1, 0.5);
    _formSlideAnimation = _createSlideAnimation(0.2, 0.6);
    _buttonSlideAnimation = _createSlideAnimation(0.3, 0.7);

    // Exit fade animation
    _exitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeIn,
    ));
  }

  Animation<double> _createOpacityAnimation(double begin, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _createSlideAnimation(double begin, double end) =>
      Tween<Offset>(
        begin: const Offset(0, 30),
        end: Offset.zero,
      ).animate(
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
  }

  void _navigateToSignUp() {
    context.push('/auth/user-type');
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _handleEmailLogin() async {
    if (_isLoading || _isGoogleLoading || _showSuccess) return;

    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final result = await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      await _exitController.forward();
      if (!mounted) return;

      final route = await _getNavigationRoute(result);
      if (!mounted) return;
      context.go(route);
    } else if (result.isNetworkError) {
      setState(() => _isLoading = false);
      _showNetworkErrorSnackBar(isGoogle: false);
    } else {
      setState(() => _isLoading = false);
      _showErrorSnackBar(result.displayError);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading || _showSuccess) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isGoogleLoading = true);

    final result = await ref.read(authProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isGoogleLoading = false;
        _showSuccess = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      await _exitController.forward();
      if (!mounted) return;

      final route = await _getNavigationRoute(result);
      if (!mounted) return;
      context.go(route);
    } else if (result.cancelled) {
      setState(() => _isGoogleLoading = false);
    } else if (result.isUserNotFound) {
      setState(() => _isGoogleLoading = false);
      _showUserNotFoundDialog();
    } else if (result.isNetworkError) {
      setState(() => _isGoogleLoading = false);
      _showNetworkErrorSnackBar(isGoogle: true);
    } else {
      setState(() => _isGoogleLoading = false);
      _showErrorSnackBar(result.displayError);
    }
  }

  Future<String> _getNavigationRoute(AuthResult result) async {
    final user = result.user;

    // Attendees skip onboarding entirely
    if (user?.isAttendee ?? false) {
      return '/attendee';
    }

    if (result.isNewUser || !(user?.onboardingCompleted ?? false)) {
      return '/onboarding';
    }
    final dashboard = (user?.isBusiness ?? false) ? '/business' : '/community';

    final hasShownPermissions =
        await PermissionService.instance.hasShownPermissionScreen();
    if (!hasShownPermissions) {
      return '/permissions?destination=${Uri.encodeComponent(dashboard)}';
    }
    return dashboard;
  }

  void _showUserNotFoundDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _UserNotFoundDialog(
        onCreateAccount: () {
          Navigator.of(context).pop();
          _navigateToSignUp();
        },
        onGotIt: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showNetworkErrorSnackBar({required bool isGoogle}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: KolabingColors.textOnDark, size: 20),
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
          onPressed: isGoogle ? _handleGoogleSignIn : _handleEmailLogin,
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
      ),
    );
  }

  bool get _anyLoading => _isLoading || _isGoogleLoading;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_anyLoading,
        child: Scaffold(
          backgroundColor: KolabingColors.darkBackground,
          body: AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) => Opacity(
              opacity: _exitAnimation.value,
              child: child,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar with back button and Sign Up link
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BackButton(
                          onPressed: _handleBack,
                          isEnabled: !_anyLoading && !_showSuccess,
                        ),
                        _SignUpLink(
                          onTap: _navigateToSignUp,
                          isEnabled: !_anyLoading && !_showSuccess,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            // Logo
                            _AnimatedElement(
                              opacityAnimation: _logoAnimation,
                              slideAnimation: _logoSlideAnimation,
                              child: const KolabingLogo(
                                size: KolabingLogoSize.medium,
                                variant: KolabingLogoVariant.yellowCircle,
                                showText: true,
                                onDarkBackground: true,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Headline
                            _AnimatedElement(
                              opacityAnimation: _headlineAnimation,
                              slideAnimation: _headlineSlideAnimation,
                              child: Text(
                                'WELCOME BACK',
                                style: GoogleFonts.rubik(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: KolabingColors.textOnDark,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Subtitle
                            AnimatedBuilder(
                              animation: _headlineAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _headlineAnimation.value,
                                child: child,
                              ),
                              child: Text(
                                'Sign in to your account',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: KolabingColors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Email/Password Form
                            _AnimatedElement(
                              opacityAnimation: _formAnimation,
                              slideAnimation: _formSlideAnimation,
                              child: Column(
                                children: [
                                  // Email label
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Email',
                                      style: GoogleFonts.openSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: KolabingColors.textOnDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    enabled: !_anyLoading,
                                    validator: _validateEmail,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      _passwordFocusNode.requestFocus();
                                    },
                                    style: GoogleFonts.openSans(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 16,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'your@email.com',
                                      prefixIcon: Icons.email_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Password label
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Password',
                                      style: GoogleFonts.openSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: KolabingColors.textOnDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    enabled: !_anyLoading,
                                    validator: _validatePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleEmailLogin(),
                                    style: GoogleFonts.openSans(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 16,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFFAAAAAA),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login Button
                            _AnimatedElement(
                              opacityAnimation: _buttonAnimation,
                              slideAnimation: _buttonSlideAnimation,
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _anyLoading ? null : _handleEmailLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: KolabingColors.primary,
                                    foregroundColor: KolabingColors.onPrimary,
                                    disabledBackgroundColor:
                                        KolabingColors.primary.withValues(alpha: 0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              KolabingColors.onPrimary,
                                            ),
                                          ),
                                        )
                                      : _showSuccess
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 24,
                                              color: KolabingColors.onPrimary,
                                            )
                                          : Text(
                                              'SIGN IN',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Forgot Password link
                            AnimatedBuilder(
                              animation: _buttonAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _buttonAnimation.value,
                                child: child,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _anyLoading || _showSuccess
                                      ? null
                                      : () => context.push('/auth/forgot-password'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: KolabingColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            AnimatedBuilder(
                              animation: _dividerAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _dividerAnimation.value,
                                child: child,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: KolabingColors.darkBorder,
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'or',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: KolabingColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: KolabingColors.darkBorder,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Google Sign In Button
                            AnimatedBuilder(
                              animation: _googleAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _googleAnimation.value,
                                child: child,
                              ),
                              child: GoogleSignInButton(
                                onPressed: _handleGoogleSignIn,
                                buttonText: 'Continue with Google',
                                isLoading: _isGoogleLoading,
                                showSuccess: _showSuccess,
                                isEnabled: !_anyLoading && !_showSuccess,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Bottom link
                            AnimatedBuilder(
                              animation: _linkAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _linkAnimation.value,
                                child: child,
                              ),
                              child: _CreateAccountLink(
                                onTap: _navigateToSignUp,
                                isEnabled: !_anyLoading && !_showSuccess,
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.openSans(
          color: const Color(0xFFAAAAAA),
          fontSize: 15,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFAAAAAA)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.error, width: 2),
        ),
        errorStyle: GoogleFonts.openSans(
          color: KolabingColors.error,
          fontSize: 12,
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
          child: Opacity(
            opacity: opacityAnimation.value,
            child: child,
          ),
        ),
        child: child,
      );
}

/// Back button for dark theme
class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed, this.isEnabled = true});

  final VoidCallback onPressed;
  final bool isEnabled;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          if (widget.isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (widget.isEnabled) setState(() => _isPressed = false);
        },
        onTap: () {
          if (widget.isEnabled) {
            HapticFeedback.lightImpact();
            widget.onPressed();
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.isEnabled ? (_isPressed ? 0.6 : 1.0) : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: KolabingColors.textOnDark,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.textOnDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Sign Up link in top right
class _SignUpLink extends StatefulWidget {
  const _SignUpLink({required this.onTap, this.isEnabled = true});

  final VoidCallback onTap;
  final bool isEnabled;

  @override
  State<_SignUpLink> createState() => _SignUpLinkState();
}

class _SignUpLinkState extends State<_SignUpLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          if (widget.isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (widget.isEnabled) setState(() => _isPressed = false);
        },
        onTap: () {
          if (widget.isEnabled) {
            HapticFeedback.lightImpact();
            widget.onTap();
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.isEnabled ? (_isPressed ? 0.6 : 1.0) : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Sign Up',
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textOnDark,
                decoration: _isPressed ? TextDecoration.underline : null,
                decorationColor: KolabingColors.textOnDark,
              ),
            ),
          ),
        ),
      );
}

/// Create account link at bottom
class _CreateAccountLink extends StatefulWidget {
  const _CreateAccountLink({required this.onTap, this.isEnabled = true});

  final VoidCallback onTap;
  final bool isEnabled;

  @override
  State<_CreateAccountLink> createState() => _CreateAccountLinkState();
}

class _CreateAccountLinkState extends State<_CreateAccountLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) {
          if (widget.isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (widget.isEnabled) setState(() => _isPressed = false);
        },
        onTap: () {
          if (widget.isEnabled) {
            HapticFeedback.lightImpact();
            widget.onTap();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.isEnabled ? 1.0 : 0.5,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: _isPressed ? 0.98 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: KolabingColors.textTertiary,
                  ),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Create One',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.primary,
                        decoration: _isPressed ? TextDecoration.underline : null,
                        decorationColor: KolabingColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Dialog for user not found with Google login
class _UserNotFoundDialog extends StatelessWidget {
  const _UserNotFoundDialog({
    required this.onCreateAccount,
    required this.onGotIt,
  });

  final VoidCallback onCreateAccount;
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
              const Icon(
                Icons.person_off_outlined,
                size: 48,
                color: KolabingColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Account Not Found',
                style: KolabingTextStyles.headlineMedium.copyWith(
                  color: KolabingColors.textOnDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'No account exists with this Google email. Please create an account first.',
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
                  onPressed: onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Account',
                    style: KolabingTextStyles.button.copyWith(
                      color: KolabingColors.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onGotIt,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
