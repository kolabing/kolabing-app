import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/kolabing_logo.dart';

const Color _kLoginBg = Color(0xFF000000);
const Color _kLoginPanel = Color(0xB3121212);
const Color _kLoginPanelBorder = Color(0x26FFFFFF);
const Color _kLoginFieldFill = Color(0x14FFFFFF);
const Color _kLoginFieldBorder = Color(0x40FFFFFF);
const Color _kLoginTextMuted = Color(0xCCFFFFFF);
const Color _kLoginTextSoft = Color(0x8AFFFFFF);
const String _kLoginHeroImage = 'assets/images/welcome_hero.png';
const String _kWelcomeRoute = '/auth/welcome';
const String _kUserTypeSelectionRoute = '/auth/user-type';
const String _kForgotPasswordRoute = '/auth/forgot-password';
const String _kBusinessDashboardRoute = '/business';
const String _kCommunityDashboardRoute = '/community';
const String _kPermissionsRoute = '/permissions';

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

  // Slide animations
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<Offset> _buttonSlideAnimation;

  late final Animation<double> _exitAnimation;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
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
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _kLoginBg,
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

    // Slide animations (30dp up as per spec)
    _logoSlideAnimation = _createSlideAnimation(0.0, 0.4);
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

    // Dismiss keyboard
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

    // Dismiss keyboard
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
            Icon(
              Icons.wifi_off_rounded,
              color: context.colors.textOnDark,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).authNoInternet,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.textOnDark,
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
          textColor: context.colors.textOnDark,
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
            color: context.colors.textOnDark,
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
      backgroundColor: _kLoginBg,
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
              final horizontalPadding = compact ? 20.0 : 24.0;
              final verticalPadding = ultraCompact
                  ? 8.0
                  : (compact ? 10.0 : 14.0);
              final logoWidth = ultraCompact
                  ? 126.0
                  : (compact ? 138.0 : 152.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  const _LoginBackdrop(),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        ultraCompact ? 10 : (compact ? 14 : 18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) => Opacity(
                              opacity: _logoAnimation.value,
                              child: child,
                            ),
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
                          SizedBox(
                            height: ultraCompact ? 8 : (compact ? 10 : 14),
                          ),
                          _AnimatedElement(
                            opacityAnimation: _logoAnimation,
                            slideAnimation: _logoSlideAnimation,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _HeroLogo(
                                width: logoWidth,
                                variant: KolabingLogoVariant.yellowTransparent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: _AnimatedElement(
                                opacityAnimation: _headlineAnimation,
                                slideAnimation: _headlineSlideAnimation,
                                child: _HeroCopy(
                                  headlineSize: ultraCompact ? 28.0 : (compact ? 32.0 : 36.0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ultraCompact ? 10 : (compact ? 12 : 18),
                          ),
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
                  ),
                ],
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
  }) => Align(
    alignment: Alignment.bottomCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(ultraCompact ? 14 : (compact ? 16 : 18)),
            decoration: BoxDecoration(
              color: _kLoginPanel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kLoginPanelBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context).loginPanelTitle,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: context.colors.textOnDark,
                      fontSize: ultraCompact ? 14 : (compact ? 15 : 16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).loginPanelSubtitle,
                    style: KolabingTextStyles.labelMedium.copyWith(
                      color: _kLoginTextMuted,
                      fontSize: ultraCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: ultraCompact ? 10 : 12),
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
                      color: context.colors.textOnDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: context.colors.primary,
                    decoration: _inputDecoration(
                      hint: AppLocalizations.of(context).authEmailLabel,
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      color: context.colors.textOnDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: context.colors.primary,
                    decoration: _inputDecoration(
                      hint: AppLocalizations.of(context).authPasswordLabel,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _kLoginTextMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: ultraCompact ? 10 : 12),
                  _AnimatedElement(
                    opacityAnimation: _buttonAnimation,
                    slideAnimation: _buttonSlideAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: ultraCompact ? 44 : (compact ? 46 : 48),
                      child: ElevatedButton(
                        onPressed: _anyLoading ? null : _handleEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: context.colors.onPrimary,
                          disabledBackgroundColor: context.colors.primary.withValues(
                            alpha: 0.70,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.colors.onPrimary,
                                  ),
                                ),
                              )
                            : _showSuccess
                            ? Icon(
                                Icons.check_rounded,
                                size: 24,
                                color: context.colors.onPrimary,
                              )
                            : Text(
                                AppLocalizations.of(context).loginSignInButton,
                                style: KolabingTextStyles.button.copyWith(
                                  fontSize: compact ? 15 : 16,
                                  letterSpacing: 0.2,
                                  color: context.colors.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                          foregroundColor: context.colors.primary,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          AppLocalizations.of(context).loginForgotPassword,
                          style: KolabingTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
      color: _kLoginTextSoft,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: Icon(prefixIcon, color: _kLoginTextMuted, size: 20),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    suffixIcon: suffixIcon,
    isDense: true,
    filled: true,
    fillColor: _kLoginFieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kLoginFieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kLoginFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: context.colors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: context.colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: context.colors.error, width: 1.6),
    ),
    errorStyle: KolabingTextStyles.labelSmall.copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFFA7B8),
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

class _HeroLogo extends StatelessWidget {
  const _HeroLogo({required this.width, required this.variant});

  final double width;
  final KolabingLogoVariant variant;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 0.34,
    child: ClipRect(
      child: OverflowBox(
        maxWidth: width * 1.9,
        maxHeight: width * 1.9,
        alignment: Alignment.bottomLeft,
        child: Transform.translate(
          offset: Offset(-width * 0.05, 0),
          child: KolabingLogo(width: width * 1.9, variant: variant),
        ),
      ),
    ),
  );
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _kLoginBg),
        Image.asset(_kLoginHeroImage, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.24),
                Colors.black.withValues(alpha: 0.42),
                Colors.black.withValues(alpha: 0.72),
                _kLoginBg,
              ],
              stops: const [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.24),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.14),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.headlineSize});

  final double headlineSize;

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).loginHeroWelcome,
    style: KolabingTextStyles.displayLarge.copyWith(
      color: context.colors.textOnDark,
      fontSize: headlineSize,
      height: 1.0,
      letterSpacing: 0.3,
    ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: context.colors.textOnDark,
            ),
            const SizedBox(width: 2),
            Text(
              AppLocalizations.of(context).commonBack,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.textOnDark,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          AppLocalizations.of(context).loginSignUpLink,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
            decoration: _isPressed ? TextDecoration.underline : null,
            decorationColor: context.colors.primary,
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
    backgroundColor: context.colors.darkSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 48,
            color: context.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loginUserNotFoundTitle,
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: context.colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).loginUserNotFoundMessage,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
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
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).loginCreateAccountButton,
                style: KolabingTextStyles.button.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onGotIt,
            child: Text(
              AppLocalizations.of(context).commonCancel,
              style: KolabingTextStyles.labelLarge.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
