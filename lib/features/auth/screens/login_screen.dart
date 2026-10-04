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
import '../widgets/auth_brand_hero.dart';
import '../widgets/auth_fade_slide.dart';
import '../widgets/auth_form.dart';
import '../widgets/google_sign_in_button.dart';

// ---------------------------------------------------------------------------
// Tokens — black hero (matches the splash), warm cream sheet
// ---------------------------------------------------------------------------

const Color _kYellow = KolabingColors.primary;
const Color _kCream = kAuthSheetCream;
const Color _kInk = KolabingColors.ink;
const Color _kMuted = KolabingColors.muted;

const String _kWelcomeRoute = '/auth/welcome';
const String _kUserTypeSelectionRoute = '/auth/user-type';
const String _kForgotPasswordRoute = '/auth/forgot-password';

/// Height of the area the K and KOLABING sit in, between nav row and sheet.
const double _kMarkAreaHeight = 150;
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
    SystemChrome.setSystemUIOverlayStyle(kAuthHeroOverlayStyle);
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
        topInset +
        AuthBrandHero.navHeight +
        _kMarkAreaHeight +
        AuthBrandHero.sheetRadius;
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
                colors: [kAuthHeroNight, kAuthHeroNight, _kCream, _kCream],
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
                  child: AuthBrandHero(
                    height: heroHeight,
                    reveal: _stagger(0, 0.55),
                    leading: AuthHeroBackButton(
                      onTap: _handleBack,
                      isEnabled: interactive,
                      semanticLabel: l10n.commonBack,
                    ),
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
                                    AuthFieldLabel(text: l10n.authEmailLabel),
                                    const SizedBox(height: 8),
                                    AuthFocusGlow(
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
                                        style: authFieldTextStyle,
                                        cursorColor: _kInk,
                                        decoration: authFieldDecoration(
                                          context,
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
                                          child: AuthFieldLabel(
                                            text: l10n.authPasswordLabel,
                                          ),
                                        ),
                                        AuthInlineLink(
                                          label: l10n.loginForgotPassword,
                                          isEnabled: interactive,
                                          onTap: () => context.push(
                                            _kForgotPasswordRoute,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    AuthFocusGlow(
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
                                        style: authFieldTextStyle,
                                        cursorColor: _kInk,
                                        decoration: authFieldDecoration(
                                          context,
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
                                AuthPrimaryCta(
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
                                    AuthOrDivider(
                                      label: l10n.authOrContinueWith,
                                    ),
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
                                AuthFooterLink(
                                  inkKey: const Key('login-sign-up'),
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
