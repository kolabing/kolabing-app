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
import '../../../widgets/keyboard_avoiding_content.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';

// ---------------------------------------------------------------------------
// Design tokens — dark premium theme.
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF0A0A0A);
const Color _kCard = Color(0xFF161616);
const Color _kCardBorder = Color(0xFF272727);
const Color _kFieldFill = Color(0xFF1F1F1F);
const Color _kFieldBorder = Color(0xFF2E2E2E);
const Color _kYellow = Color(0xFFFFE28C);
const Color _kTextWhite = Color(0xFFFFFFFF);
const Color _kTextSoft = Color(0xFFB0AFA8);
const Color _kTextMuted = Color(0xFF6B6A65);

const String _kWelcomeRoute = '/auth/welcome';
const String _kUserTypeSelectionRoute = '/auth/user-type';
const String _kForgotPasswordRoute = '/auth/forgot-password';
const String _kBusinessDashboardRoute = '/business';
const String _kCommunityDashboardRoute = '/community';
const String _kPermissionsRoute = '/permissions';

/// Login Screen for existing users.
///
/// Dark themed screen with email/password login and social sign-in options.
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

  // Slide animations
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<Offset> _buttonSlideAnimation;

  late final Animation<double> _exitAnimation;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;

  static const _brandPhrases = [
    'brand love',
    'word of mouth',
    'local growth',
    'experiences',
    'new customers',
    'authentic content',
    'community',
    'real engagement',
    'partnerships',
    'ugc',
    'visibility',
  ];
  int _phraseIndex = 0;
  double _phraseOpacity = 1.0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _startEntryAnimation();
    _startPhraseRotation();
  }

  void _startPhraseRotation() {
    _phraseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() => _phraseOpacity = 0.0);
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _brandPhrases.length;
          _phraseOpacity = 1.0;
        });
      });
    });
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _kBg,
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

    // Slide animations
    _headlineSlideAnimation = _createSlideAnimation(0.1, 0.5);
    _formSlideAnimation = _createSlideAnimation(0.2, 0.6);
    _buttonSlideAnimation = _createSlideAnimation(0.3, 0.7);

    // Exit fade animation
    _exitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  Animation<double> _createOpacityAnimation(double begin, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _createSlideAnimation(double begin, double end) =>
      Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero).animate(
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
    _phraseTimer?.cancel();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
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

    if (!_formKey.currentState!.validate()) return;

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
        debugPrint(
          '[B2] login success → routing to "$route" '
          '(userType=${result.user?.userType} isNewUser=${result.isNewUser})',
        );
        if (!mounted) return;
        context.go(route);
      } else if (result.isNetworkError) {
        debugPrint('[B2] login network error: ${result.errorMessage}');
        setState(() => _isLoading = false);
        _showNetworkErrorSnackBar(isGoogle: false);
      } else {
        debugPrint(
          '[B2] login failed: status=${result.error?.statusCode} '
          'message=${result.displayError}',
        );
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
    if (user == null) {
      return _kWelcomeRoute;
    }

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
      barrierColor: context.colors.overlayDark60,
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
            Icon(Icons.wifi_off_rounded, color: _kTextWhite, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).authNoInternet,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: _kTextWhite,
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
          textColor: _kTextWhite,
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
            color: _kTextWhite,
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
  Widget build(BuildContext context) => PopScope(
    canPop: !_anyLoading,
    child: Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: false,
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) =>
            Opacity(opacity: _exitAnimation.value, child: child),
        child: KeyboardAvoidingContent(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 760;
              final ultraCompact = constraints.maxHeight < 680;
              final hPad = compact ? 20.0 : 24.0;
              final vPad = ultraCompact ? 8.0 : (compact ? 10.0 : 14.0);
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    vPad,
                    hPad,
                    ultraCompact ? 10 : (compact ? 14 : 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top nav — Back + Sign up.
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) =>
                            Opacity(opacity: _logoAnimation.value, child: child),
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

                      // Flexible space with rotating brand phrase in upper-right.
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AnimatedOpacity(
                              opacity: _phraseOpacity * 0.36,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              child: Text(
                                _brandPhrases[_phraseIndex],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFD4C9A8),
                                  letterSpacing: 0.3,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // WELCOME BACK. headline above card.
                      _AnimatedElement(
                        opacityAnimation: _headlineAnimation,
                        slideAnimation: _headlineSlideAnimation,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: ultraCompact ? 14 : (compact ? 18 : 22),
                          ),
                          child: Text(
                            'WELCOME BACK.',
                            style: KolabingTextStyles.displayLarge.copyWith(
                              color: _kTextWhite,
                            ),
                          ),
                        ),
                      ),

                      // Auth card.
                      _AnimatedElement(
                        opacityAnimation: _formAnimation,
                        slideAnimation: _formSlideAnimation,
                        child: _buildAuthPanel(
                          compact: compact,
                          ultraCompact: ultraCompact,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _buildAuthPanel({
    required bool compact,
    required bool ultraCompact,
  }) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: Container(
      padding: EdgeInsets.all(ultraCompact ? 16 : (compact ? 18 : 20)),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header.
            Text(
              AppLocalizations.of(context).loginPanelTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: _kTextWhite,
                fontSize: ultraCompact ? 14 : (compact ? 15 : 16),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).loginPanelSubtitle,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: _kTextSoft,
                fontSize: ultraCompact ? 12 : 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            SizedBox(height: ultraCompact ? 14 : 16),

            // Email field.
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
              onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: _kTextWhite,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _kYellow,
              decoration: _inputDecoration(
                hint: AppLocalizations.of(context).authEmailLabel,
                prefixIcon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 10),

            // Password field.
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              enabled: !_anyLoading,
              validator: _validatePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleEmailLogin(),
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: _kTextWhite,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _kYellow,
              decoration: _inputDecoration(
                hint: AppLocalizations.of(context).authPasswordLabel,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _kTextMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            SizedBox(height: ultraCompact ? 12 : 14),

            // Sign in button.
            _AnimatedElement(
              opacityAnimation: _buttonAnimation,
              slideAnimation: _buttonSlideAnimation,
              child: SizedBox(
                width: double.infinity,
                height: ultraCompact ? 44 : (compact ? 46 : 50),
                child: ElevatedButton(
                  onPressed: _anyLoading ? null : _handleEmailLogin,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.60),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                KolabingColors.onPrimary),
                          ),
                        )
                      : _showSuccess
                      ? const Icon(Icons.check_rounded, size: 22)
                      : Text(
                          AppLocalizations.of(context).loginSignInButton,
                          style: KolabingTextStyles.button.copyWith(
                            fontSize: compact ? 15 : 15.5,
                          ),
                        ),
                ),
              ),
            ),

            // Forgot password.
            const SizedBox(height: 2),
            AnimatedBuilder(
              animation: _dividerAnimation,
              builder: (context, child) =>
                  Opacity(opacity: _dividerAnimation.value, child: child),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _anyLoading || _showSuccess
                      ? null
                      : () => context.push(_kForgotPasswordRoute),
                  style: TextButton.styleFrom(
                    foregroundColor: KolabingColors.primary,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    AppLocalizations.of(context).loginForgotPassword,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Divider.
            SizedBox(height: ultraCompact ? 10 : 12),
            Row(
              children: [
                Expanded(child: Divider(color: _kCardBorder, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: _kTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: _kCardBorder, thickness: 1)),
              ],
            ),
            SizedBox(height: ultraCompact ? 10 : 12),

            // Social buttons.
            AnimatedBuilder(
              animation: _googleAnimation,
              builder: (context, child) =>
                  Opacity(opacity: _googleAnimation.value, child: child),
              child: Row(
                children: [
                  Expanded(
                    child: GoogleSignInButton(
                      onPressed: _handleGoogleSignIn,
                      buttonText: 'Google',
                      isLoading: _isGoogleLoading,
                      showSuccess: _showSuccess,
                      isEnabled: !_anyLoading && !_showSuccess,
                      height: ultraCompact ? 42 : 44,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppleSignInButton(
                      onPressed: _handleAppleSignIn,
                      buttonText: 'Apple',
                      isLoading: _isAppleLoading,
                      showSuccess: _showSuccess,
                      isEnabled: !_anyLoading && !_showSuccess,
                      height: ultraCompact ? 42 : 44,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: KolabingTextStyles.bodyMedium.copyWith(
      color: _kTextMuted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Icon(prefixIcon, color: _kTextMuted, size: 19),
    prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
    suffixIcon: suffixIcon,
    isDense: true,
    filled: true,
    fillColor: _kFieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kFieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kYellow, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.error, width: 1.5),
    ),
    errorStyle: KolabingTextStyles.labelSmall.copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFFA7B8),
    ),
  );
}

// ---------------------------------------------------------------------------
// Animated stagger wrapper.
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Top-left back button.
// ---------------------------------------------------------------------------

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
      opacity: widget.isEnabled ? (_isPressed ? 0.55 : 1.0) : 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 13,
              color: _kTextSoft,
            ),
            const SizedBox(width: 3),
            Text(
              AppLocalizations.of(context).commonBack,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _kTextSoft,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Top-right sign-up link.
// ---------------------------------------------------------------------------

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
      opacity: widget.isEnabled ? (_isPressed ? 0.55 : 1.0) : 0.35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          AppLocalizations.of(context).loginSignUpLink,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kYellow,
            decoration: _isPressed ? TextDecoration.underline : null,
            decorationColor: _kYellow,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Staggered brand hero for login screen.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// "User not found" dialog — unchanged logic, updated palette.
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
    backgroundColor: _kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 48, color: _kYellow),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loginUserNotFoundTitle,
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: _kTextWhite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).loginUserNotFoundMessage,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: _kTextSoft,
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
              child: Text(
                AppLocalizations.of(context).loginCreateAccountButton,
                style: KolabingTextStyles.button,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onGotIt,
            child: Text(
              AppLocalizations.of(context).commonCancel,
              style: KolabingTextStyles.labelLarge.copyWith(
                color: _kTextMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
