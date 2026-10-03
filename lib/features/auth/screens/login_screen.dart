import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/auth_fade_slide.dart';
import '../widgets/google_sign_in_button.dart';

// ---------------------------------------------------------------------------
// Tokens — black hero (matches the splash), warm cream sheet
// ---------------------------------------------------------------------------

const Color _kNight = Color(0xFF000000);
const Color _kYellow = KolabingColors.primary;
const Color _kYellowDeep = KolabingColors.primaryDark;
const Color _kCream = Color(0xFFF6F1E7);
const Color _kInk = KolabingColors.ink;
const Color _kInkBody = KolabingColors.inkBody;
const Color _kMuted = KolabingColors.muted;
const Color _kAmber = KolabingColors.amber;
const Color _kInputBorder = KolabingColors.outlineVariant;
const Color _kInputFill = KolabingColors.surface;
const Color _kDivider = Color(0xFFE1D9C8);

const String _kWelcomeRoute = '/auth/welcome';
const String _kUserTypeSelectionRoute = '/auth/user-type';
const String _kForgotPasswordRoute = '/auth/forgot-password';
const String _kLogoMarkAsset = 'assets/brand/kolabing-k-mark.png';

const double _kNavHeight = 56;
const double _kMarkAreaHeight = 150;
const double _kSheetRadius = 32;
const double _kFieldRadius = 16;
const double _kRiseDistance = 18;

/// When a field scrolls above the keyboard, keep this much room below it so the
/// Sign in button under the password field comes along.
const EdgeInsets _kFieldScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 130);

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
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    // Repaint the focus glow as focus moves between the fields.
    _emailFocusNode.addListener(_onFocusChanged);
    _passwordFocusNode.addListener(_onFocusChanged);

    _entryController.forward();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Light icons over the black hero.
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _kCream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onFocusChanged);
    _passwordFocusNode.removeListener(_onFocusChanged);
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

    return gateDestinationOnPermissions(
      resolveAuthDestination(user, isNewUser: result.isNewUser),
    );
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

  /// One staggered slice of the entry animation, [start]..[end] of 0..1.
  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _entryController,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  /// Fades a form row in while it rises [_kRiseDistance] into place.
  Widget _rise(double start, Widget child) {
    final t = _stagger(start, (start + 0.45).clamp(0, 1).toDouble());
    return AuthFadeSlide(
      opacity: t,
      offset: Tween<Offset>(
        begin: const Offset(0, _kRiseDistance),
        end: Offset.zero,
      ).animate(t),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight =
        topInset + _kNavHeight + _kMarkAreaHeight + _kSheetRadius;
    final interactive = !_anyLoading && !_showSuccess;

    return PopScope(
      canPop: !_anyLoading,
      child: Scaffold(
        backgroundColor: _kCream,
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) =>
              Opacity(opacity: _exitAnimation.value, child: child),
          // Black above the middle, cream below, so an iOS overscroll at
          // either end shows the colour of the section it pulls away from.
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kNight, _kNight, _kCream, _kCream],
                stops: [0, 0.5, 0.5, 1],
              ),
            ),
            // One scroll view for the whole page (FX-60): the hero and the
            // form move together, so a field is never clipped at a fixed edge,
            // and the focused field scrolls above the keyboard.
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(
                    height: heroHeight,
                    topInset: topInset,
                    markScale: _stagger(0, 0.55),
                    backEnabled: interactive,
                    onBack: _handleBack,
                    backLabel: l10n.commonBack,
                  ),
                ),

                // Cream sheet — the form
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ColoredBox(
                    color: _kCream,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _rise(
                                0.15,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.signInTitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: _kInk,
                                        height: 1.05,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.loginPanelSubtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: _kMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email
                              _rise(
                                0.25,
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _FieldLabel(text: l10n.authEmailLabel),
                                    const SizedBox(height: 8),
                                    _FocusGlow(
                                      focused: _emailFocusNode.hasFocus,
                                      child: TextFormField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        scrollPadding: _kFieldScrollPadding,
                                        enabled: !_anyLoading,
                                        validator: _validateEmail,
                                        textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) =>
                                            _passwordFocusNode.requestFocus(),
                                        style: _fieldTextStyle,
                                        cursorColor: _kInk,
                                        decoration: _fieldDecoration(
                                          hint: l10n.authEmailHint,
                                          prefixIcon:
                                              Icons.alternate_email_rounded,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Password — "Forgot password?" sits on its
                              // label row, next to the field it is about.
                              _rise(
                                0.32,
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _FieldLabel(
                                            text: l10n.authPasswordLabel,
                                          ),
                                        ),
                                        _InlineLink(
                                          label: l10n.loginForgotPassword,
                                          isEnabled: interactive,
                                          onTap: () => context.push(
                                            _kForgotPasswordRoute,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _FocusGlow(
                                      focused: _passwordFocusNode.hasFocus,
                                      child: TextFormField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        obscureText: _obscurePassword,
                                        enabled: !_anyLoading,
                                        validator: _validatePassword,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        scrollPadding: _kFieldScrollPadding,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) =>
                                            _handleEmailLogin(),
                                        style: _fieldTextStyle,
                                        cursorColor: _kInk,
                                        decoration: _fieldDecoration(
                                          hint: '••••••••',
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: _kMuted,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              _rise(
                                0.4,
                                _SignInCta(
                                  label: l10n.loginSignInButton,
                                  isLoading: _isLoading,
                                  showSuccess: _showSuccess,
                                  isEnabled: !_anyLoading,
                                  onPressed: _handleEmailLogin,
                                ),
                              ),
                              const SizedBox(height: 28),

                              _rise(
                                0.48,
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _OrDivider(label: l10n.authOrContinueWith),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GoogleSignInButton(
                                            onPressed: _handleGoogleSignIn,
                                            buttonText: 'Google',
                                            isLoading: _isGoogleLoading,
                                            showSuccess: _showSuccess,
                                            isEnabled: interactive,
                                            height: 52,
                                            light: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: AppleSignInButton(
                                            onPressed: _handleAppleSignIn,
                                            buttonText: 'Apple',
                                            isLoading: _isAppleLoading,
                                            showSuccess: _showSuccess,
                                            isEnabled: interactive,
                                            height: 52,
                                            light: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Pushes the footer to the bottom on tall
                              // screens; collapses when the form needs room.
                              const Spacer(),
                              const SizedBox(height: 24),
                              _rise(
                                0.55,
                                _SignUpFooter(
                                  prompt: l10n.signInNoAccount,
                                  action: l10n.signInSignUp,
                                  isEnabled: interactive,
                                  onTap: _navigateToSignUp,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }

  TextStyle get _fieldTextStyle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: _kInk,
  );

  InputDecoration _fieldDecoration({
    required IconData prefixIcon,
    String? hint,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kFieldRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: _kMuted.withValues(alpha: 0.7),
      ),
      prefixIcon: Icon(prefixIcon, color: _kMuted, size: 19),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _kInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(_kInputBorder),
      enabledBorder: border(_kInputBorder),
      disabledBorder: border(_kInputBorder),
      focusedBorder: border(_kInk, 1.6),
      errorBorder: border(context.colors.error),
      focusedErrorBorder: border(context.colors.error, 1.6),
      errorStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: context.colors.error,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — the yellow K on black, as on the splash, so the hand-off from the
// splash has no colour seam. The cream sheet's rounded top is drawn here.
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({
    required this.height,
    required this.topInset,
    required this.markScale,
    required this.backEnabled,
    required this.onBack,
    required this.backLabel,
  });

  final double height;
  final double topInset;
  final Animation<double> markScale;
  final bool backEnabled;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: ColoredBox(color: _kNight)),
        // A soft yellow glow behind the mark.
        Positioned(
          left: 0,
          right: 0,
          top: topInset + _kNavHeight - 30,
          height: _kMarkAreaHeight + 60,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.45,
                colors: [Color(0x38FFE28C), Color(0x00FFE28C)],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, topInset, 16, 0),
          child: Column(
            children: [
              SizedBox(
                height: _kNavHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleBackButton(
                    onTap: onBack,
                    isEnabled: backEnabled,
                    semanticLabel: backLabel,
                  ),
                ),
              ),
              SizedBox(
                height: _kMarkAreaHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1).animate(
                        CurvedAnimation(
                          parent: markScale,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: markScale,
                        child: Image.asset(
                          _kLogoMarkAsset,
                          key: const Key('login-logo-mark'),
                          height: 78,
                          semanticLabel: 'Kolabing',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: markScale,
                      // Brand name — exempt from i18n, as on the splash.
                      child: Text(
                        'KOLABING',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kYellow,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // The cream sheet's rounded top, overlapping the black.
        const Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          height: _kSheetRadius + 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kCream,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_kSheetRadius),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Circular back button on the dark hero
// ---------------------------------------------------------------------------

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({
    required this.onTap,
    required this.isEnabled,
    required this.semanticLabel,
  });

  final VoidCallback onTap;
  final bool isEnabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isEnabled ? 1 : 0.35,
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Form pieces
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _kInkBody,
      ),
    ),
  );
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({
    required this.label,
    required this.onTap,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isEnabled ? onTap : null,
    style: TextButton.styleFrom(
      foregroundColor: _kInk,
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isEnabled ? _kAmber : _kMuted,
      ),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: _kDivider, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kMuted,
          ),
        ),
      ),
      const Expanded(child: Divider(color: _kDivider, thickness: 1)),
    ],
  );
}

class _SignUpFooter extends StatelessWidget {
  const _SignUpFooter({
    required this.prompt,
    required this.action,
    required this.onTap,
    required this.isEnabled,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) => Center(
    // The whole row is the button, so a tap on the prompt counts too.
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('login-sign-up'),
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    prompt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                    decoration: TextDecoration.underline,
                    decorationColor: _kYellowDeep,
                    decorationThickness: 2.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: _kInk),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A soft yellow halo around a field while it has focus.
class _FocusGlow extends StatelessWidget {
  const _FocusGlow({required this.focused, required this.child});

  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      boxShadow: [
        BoxShadow(
          color: _kYellow.withValues(alpha: focused ? 0.75 : 0),
          spreadRadius: focused ? 4 : 0,
        ),
      ],
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Sign in CTA — ink pill, yellow label
// ---------------------------------------------------------------------------

class _SignInCta extends StatefulWidget {
  const _SignInCta({
    required this.label,
    required this.isLoading,
    required this.showSuccess,
    required this.isEnabled,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final bool showSuccess;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  State<_SignInCta> createState() => _SignInCtaState();
}

class _SignInCtaState extends State<_SignInCta> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isEnabled && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (widget.isLoading) {
      content = const SizedBox(
        key: ValueKey('loading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_kYellow),
        ),
      );
    } else if (widget.showSuccess) {
      content = const Icon(
        Icons.check_rounded,
        key: ValueKey('success'),
        size: 24,
        color: _kYellow,
      );
    } else {
      content = Row(
        key: const ValueKey('label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kYellow,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_rounded, size: 20, color: _kYellow),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.isEnabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: widget.isEnabled || widget.isLoading ? 1 : 0.6,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: _kInk,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _kInk.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
