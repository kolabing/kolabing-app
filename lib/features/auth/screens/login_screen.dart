import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/permission_service.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/kolabing_logo.dart';

// ---------------------------------------------------------------------------
// Warm sheet tokens
// ---------------------------------------------------------------------------

const Color _kYellow = Color(0xFFFFE28C);
const Color _kCream = Color(0xFFF6F1E7);
const Color _kInk = Color(0xFF19150F);
const Color _kMuted = Color(0xFF8C8474);
const Color _kInputBorder = Color(0xFFE4DCCB);
const Color _kInputFill = Color(0xFFFFFFFF);
const Color _kDivider = Color(0xFFE1D9C8);

const String _kWelcomeRoute = '/auth/welcome';
const String _kUserTypeSelectionRoute = '/auth/user-type';
const String _kForgotPasswordRoute = '/auth/forgot-password';
const String _kBusinessDashboardRoute = '/business';
const String _kCommunityDashboardRoute = '/community';
const String _kPermissionsRoute = '/permissions';

// ---------------------------------------------------------------------------
// LoginScreen
// ---------------------------------------------------------------------------

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
  late final Animation<double> _fadeIn;
  late final Animation<double> _exitAnimation;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;

  /// Off until the first failed submit, then per-keystroke — so a stale
  /// "Please enter a valid email" clears as soon as the user fixes the field
  /// instead of persisting until the next Sign in tap.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _exitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _entryController.forward();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _kCream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
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
    // Login can be the navigation root (post-logout redirect, deep link, or
    // initial route), where there is nothing to pop. Calling pop() then throws
    // GoError("There is nothing to pop"), so fall back to the welcome screen.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_kWelcomeRoute);
    }
  }

  void _navigateToSignUp() {
    context.push(_kUserTypeSelectionRoute);
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.authEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return l10n.authEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.authPasswordRequired;
    }
    return null;
  }

  Future<void> _handleEmailLogin() async {
    if (_isLoading || _isGoogleLoading || _showSuccess) return;
    if (!_formKey.currentState!.validate()) {
      // From now on, revalidate as the user types so the error clears the
      // moment the field is corrected.
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(authProvider.notifier)
          .signInWithEmail(
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
    } on Object catch (e, st) {
      debugPrint('[AUTH][UI] email login unexpected error: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(AppLocalizations.of(context).commonErrorGeneric);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading || _showSuccess) return;

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
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
    } on Object catch (e, st) {
      debugPrint('[AUTH][UI] google login unexpected error: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      _showErrorSnackBar(AppLocalizations.of(context).commonErrorGeneric);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading || _showSuccess) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isAppleLoading = true);

    try {
      final result = await ref.read(authProvider.notifier).signInWithApple();

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isAppleLoading = false;
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
        setState(() => _isAppleLoading = false);
      } else if (result.isUserNotFound) {
        setState(() => _isAppleLoading = false);
        _showUserNotFoundDialog();
      } else if (result.isNetworkError) {
        setState(() => _isAppleLoading = false);
        _showNetworkErrorSnackBar(isGoogle: false);
      } else {
        setState(() => _isAppleLoading = false);
        _showErrorSnackBar(result.displayError);
      }
    } on Object catch (e, st) {
      debugPrint('[AUTH][UI] apple login unexpected error: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => _isAppleLoading = false);
      _showErrorSnackBar(AppLocalizations.of(context).commonErrorGeneric);
    }
  }

  Future<String> _getNavigationRoute(AuthResult result) async {
    final user = result.user;
    if (user == null) return _kWelcomeRoute;

    final destination = resolveAuthDestination(
      user,
      isNewUser: result.isNewUser,
    );
    if (destination != _kBusinessDashboardRoute &&
        destination != _kCommunityDashboardRoute) {
      return destination;
    }

    final hasShownPermissions = await PermissionService.instance
        .hasShownPermissionScreen();
    if (!hasShownPermissions) {
      return '$_kPermissionsRoute?destination='
          '${Uri.encodeComponent(destination)}';
    }
    return destination;
  }

  void _showUserNotFoundDialog() {
    showDialog<void>(
      context: context,
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
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).authNoInternet,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppLocalizations.of(context).commonRetry,
          textColor: Colors.white,
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
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool get _anyLoading => _isLoading || _isGoogleLoading || _isAppleLoading;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final heroHeight = size.height * 0.32;
    final waveHeight = 130.0 * screenWidth / 402.0;

    return PopScope(
      canPop: !_anyLoading,
      child: Scaffold(
        backgroundColor: _kYellow,
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) =>
              Opacity(opacity: _exitAnimation.value, child: child),
          child: FadeTransition(
            opacity: _fadeIn,
            child: Stack(
              children: [
                // Cream sheet background
                Positioned(
                  top: heroHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(color: _kCream),
                ),

                // Wave transition
                Positioned(
                  top: heroHeight - waveHeight + 12,
                  left: 0,
                  right: 0,
                  height: waveHeight,
                  child: CustomPaint(painter: _WavePainter(color: _kCream)),
                ),

                // Main layout
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Yellow hero with top nav + logo
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: heroHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Top nav row
                              SizedBox(
                                height: 48,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _HeroButton(
                                      onTap: _handleBack,
                                      isEnabled: !_anyLoading && !_showSuccess,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 13,
                                            color: _kInk,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            ).commonBack,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: _kInk,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _HeroButton(
                                      onTap: _navigateToSignUp,
                                      isEnabled: !_anyLoading && !_showSuccess,
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).loginSignUpLink,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _kInk,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Space where the logo used to live — now overlaid on the seam
                              // Logo centred in remaining hero space, shifted slightly above centre
                              // to match the welcome screen's logo position.
                              const Expanded(
                                child: Align(
                                  alignment: Alignment(0, -0.5),
                                  child: KolabingLogo(
                                    width: 158,
                                    variant: KolabingLogoVariant.onYellow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Cream sheet — scrollable form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
                        child: SafeArea(
                          top: false,
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autovalidateMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Heading
                                Text(
                                  'WELCOME BACK.',
                                  style: KolabingTextStyles.displayMedium
                                      .copyWith(
                                        color: _kInk,
                                        height: 0.98,
                                        letterSpacing: 0,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).loginPanelSubtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: const [AutofillHints.email],
                                  enabled: !_anyLoading,
                                  validator: _validateEmail,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _kInk,
                                  ),
                                  cursorColor: _kInk,
                                  decoration: _fieldDecoration(
                                    hint: AppLocalizations.of(
                                      context,
                                    ).authEmailLabel,
                                    prefixIcon: Icons.alternate_email_rounded,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  enabled: !_anyLoading,
                                  validator: _validatePassword,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleEmailLogin(),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _kInk,
                                  ),
                                  cursorColor: _kInk,
                                  decoration: _fieldDecoration(
                                    hint: AppLocalizations.of(
                                      context,
                                    ).authPasswordLabel,
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _kMuted,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Sign in CTA
                                _SignInCta(
                                  isLoading: _isLoading,
                                  showSuccess: _showSuccess,
                                  isEnabled: !_anyLoading,
                                  onPressed: _handleEmailLogin,
                                ),

                                // Forgot password
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _anyLoading || _showSuccess
                                        ? null
                                        : () => context.push(
                                            _kForgotPasswordRoute,
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: _kMuted,
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).loginForgotPassword,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _kMuted,
                                      ),
                                    ),
                                  ),
                                ),

                                // Divider
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: _kDivider,
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        'or',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: _kMuted,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: _kDivider,
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Social buttons — Google + Apple pills
                                Row(
                                  children: [
                                    Expanded(
                                      child: GoogleSignInButton(
                                        onPressed: _handleGoogleSignIn,
                                        buttonText: 'Google',
                                        isLoading: _isGoogleLoading,
                                        showSuccess: _showSuccess,
                                        isEnabled:
                                            !_anyLoading && !_showSuccess,
                                        height: 52,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppleSignInButton(
                                        onPressed: _handleAppleSignIn,
                                        buttonText: 'Apple',
                                        isLoading: _isAppleLoading,
                                        showSuccess: _showSuccess,
                                        isEnabled:
                                            !_anyLoading && !_showSuccess,
                                        height: 52,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: _kMuted,
    ),
    prefixIcon: Icon(prefixIcon, color: _kMuted, size: 19),
    prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 56),
    suffixIcon: suffixIcon,
    isDense: false,
    filled: true,
    fillColor: _kInputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: _kInputBorder, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: _kInputBorder, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: _kInk, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: context.colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: context.colors.error, width: 1.5),
    ),
    errorStyle: GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: context.colors.error,
    ),
  );
}

// ---------------------------------------------------------------------------
// Sign in CTA — pill button, yellow fill
// ---------------------------------------------------------------------------

class _SignInCta extends StatelessWidget {
  const _SignInCta({
    required this.isLoading,
    required this.showSuccess,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool showSuccess;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isEnabled ? 1.0 : 0.65,
        child: Container(
          decoration: BoxDecoration(
            color: _kYellow,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF141210).withValues(alpha: 0.12),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_kInk),
                    ),
                  )
                : showSuccess
                ? const Icon(Icons.check_rounded, size: 22, color: _kInk)
                : Text(
                    AppLocalizations.of(context).loginSignInButton,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Hero tap button (Back / Sign up in yellow hero)
// ---------------------------------------------------------------------------

class _HeroButton extends StatefulWidget {
  const _HeroButton({
    required this.onTap,
    required this.child,
    this.isEnabled = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool isEnabled;

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) {
      if (widget.isEnabled) setState(() => _pressed = true);
    },
    onTapUp: (_) {
      if (widget.isEnabled) setState(() => _pressed = false);
    },
    onTapCancel: () {
      if (widget.isEnabled) setState(() => _pressed = false);
    },
    onTap: () {
      if (widget.isEnabled) {
        HapticFeedback.lightImpact();
        widget.onTap();
      }
    },
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: widget.isEnabled ? (_pressed ? 0.5 : 1.0) : 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: widget.child,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Wave painter — cream sheet with organic wavy top edge
// ---------------------------------------------------------------------------

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final sx = size.width / 402.0;
    final sy = size.height / 130.0;

    final path = Path()
      ..moveTo(0, 130 * sy)
      ..lineTo(0, 66 * sy)
      ..cubicTo(72 * sx, 22 * sy, 150 * sx, 52 * sy, 230 * sx, 60 * sy)
      ..cubicTo(300 * sx, 67 * sy, 352 * sx, 34 * sy, 402 * sx, 50 * sy)
      ..lineTo(402 * sx, 130 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// "User not found" dialog
// ---------------------------------------------------------------------------

class _UserNotFoundDialog extends StatelessWidget {
  const _UserNotFoundDialog({
    required this.onCreateAccount,
    required this.onGotIt,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _kCream,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 48, color: _kInk),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loginUserNotFoundTitle,
            style: KolabingTextStyles.headlineMedium.copyWith(color: _kInk),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).loginUserNotFoundMessage,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _kMuted,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: onCreateAccount,
              child: Container(
                decoration: BoxDecoration(
                  color: _kYellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).loginCreateAccountButton,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onGotIt,
            child: Text(
              AppLocalizations.of(context).commonCancel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
