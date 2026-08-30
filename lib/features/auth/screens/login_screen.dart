import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/brand/kolabing_k_mark.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/auth_page.dart';
import '../widgets/google_logo.dart';

// ---------------------------------------------------------------------------
// Warm sheet tokens
// ---------------------------------------------------------------------------

const Color _kInk = Color(0xFF19150F);
const Color _kMuted = Color(0xFF8C8474);

const String _kWelcomeRoute = '/auth/welcome';
const String _kUserTypeSelectionRoute = '/auth/user-type';
const String _kForgotPasswordRoute = '/auth/forgot-password';

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

  late final TapGestureRecognizer _createAccountTap;

  /// The design greys the CTA until both fields have something in them.
  bool get _hasCredentials =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _onCredentialsChanged() {
    if (mounted) setState(() {});
  }

  /// Off until the first failed submit, then per-keystroke — so a stale
  /// "Please enter a valid email" clears as soon as the user fixes the field
  /// instead of persisting until the next Sign in tap.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();

    _createAccountTap = TapGestureRecognizer()..onTap = _navigateToSignUp;
    _emailController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);

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
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _createAccountTap.dispose();
    _emailController.removeListener(_onCredentialsChanged);
    _passwordController.removeListener(_onCredentialsChanged);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    /// With the keyboard up the page has ~596pt instead of 932, and variant 1a
    /// spends its top third on brand. So the decorative half stands down while
    /// someone is typing — the mark, the handwritten line and the footer — and
    /// the heading stays, which is the part that was reported missing.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: !_anyLoading,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) =>
              Opacity(opacity: _exitAnimation.value, child: child),
          child: FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AuthMetrics.gutter,
                    0,
                    AuthMetrics.gutter,
                    AuthMetrics.bottomPad,
                  ),
                  child: ConstrainedBox(
                    // Fill the viewport, minus the padding the scroll view adds
                    // BELOW this box. Using the bare maxHeight made the page
                    // permanently scrollable by exactly `bottomPad`: the column
                    // was stretched to the full viewport and the padding then
                    // pushed it past — a scroll with nothing at the end of it,
                    // which is what was reported as unnecessary space.
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AuthMetrics.bottomPad,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildNavRow(l10n),
                            AuthCollapsible(
                              collapsed: keyboardOpen,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: AuthMetrics.markTop),
                                  Transform.rotate(
                                    angle: AuthMetrics.markTilt,
                                    child: AnimatedKolabingKMark(
                                      width: AuthMetrics.markWidth,
                                      color: KolabingColors.brandDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AuthMetrics.headingTop),
                            _buildHeading(l10n),
                            AuthCollapsible(
                              collapsed: keyboardOpen,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: AuthMetrics.subtitleTop,
                                  ),
                                  Transform.rotate(
                                    angle: AuthMetrics.subtitleTilt,
                                    child: Text(
                                      l10n.loginSubtitle,
                                      style: GoogleFonts.caveat(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w600,
                                        color: KolabingColors.inkBody,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AuthMetrics.bodyTop),
                            // Side by side rather than stacked, taking variant
                            // 1b's compact social row from the same design doc.
                            // Two full-width buttons cost 118pt of a page that
                            // could not fit its own footer; this costs 52.
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: _Login.googleLabel,
                                    semanticLabel: l10n.loginContinueWithGoogle,
                                    icon: const GoogleLogo(
                                      size: _Login.socialIcon,
                                    ),
                                    background: Colors.white,
                                    foreground: KolabingColors.brandDark,
                                    bordered: true,
                                    isLoading: _isGoogleLoading,
                                    isEnabled: !_anyLoading && !_showSuccess,
                                    onPressed: _handleGoogleSignIn,
                                  ),
                                ),
                                const SizedBox(width: _Login.socialGap),
                                Expanded(
                                  child: _SocialButton(
                                    label: _Login.appleLabel,
                                    semanticLabel: l10n.loginContinueWithApple,
                                    icon: const Icon(
                                      Icons.apple,
                                      size: _Login.socialIcon,
                                      color: Colors.white,
                                    ),
                                    background: KolabingColors.brandDark,
                                    foreground: Colors.white,
                                    isLoading: _isAppleLoading,
                                    isEnabled: !_anyLoading && !_showSuccess,
                                    onPressed: _handleAppleSignIn,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: _Login.dividerGap),
                            _OrDivider(label: l10n.loginOrWithEmail),
                            const SizedBox(height: _Login.dividerGap),
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
                              style: AuthMetrics.fieldTextStyle,
                              decoration: _fieldDecoration(
                                hint: l10n.authEmailLabel,
                                prefixIcon: LucideIcons.mail,
                              ),
                            ),
                            const SizedBox(height: AuthMetrics.fieldGap),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.password],
                              enabled: !_anyLoading,
                              validator: _validatePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleEmailLogin(),
                              style: AuthMetrics.fieldTextStyle,
                              decoration: _fieldDecoration(
                                hint: l10n.authPasswordLabel,
                                prefixIcon: LucideIcons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    size: 19,
                                    color: KolabingColors.muted,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  tooltip: l10n.loginTogglePasswordVisibility,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _anyLoading
                                    ? null
                                    : () => context.push(_kForgotPasswordRoute),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.loginForgotPasswordPrompt,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: KolabingColors.brandDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AuthMetrics.ctaTop),
                            AuthPrimaryCta(
                              label: l10n.loginSignInButton,
                              isLoading: _isLoading,
                              showSuccess: _showSuccess,
                              // The design greys the CTA until both fields have
                              // something in them, rather than waiting for the
                              // validator to complain after a tap.
                              isEnabled: _hasCredentials && !_anyLoading,
                              onPressed: _handleEmailLogin,
                            ),
                            // No Spacer here on purpose. The design pins the
                            // footer with `margin: auto 0 0`, which works in a
                            // fixed 880pt web frame where the content always
                            // fits. On a phone it pushes the footer to the
                            // bottom of whatever the viewport happens to be,
                            // leaving a void under the CTA and making the page
                            // scrollable for no reason — which is exactly what
                            // was reported. The footer just follows the button.
                            AuthCollapsible(
                              collapsed: keyboardOpen,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: AuthMetrics.footerAfterCta,
                                  ),
                                  _buildFooter(l10n),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavRow(AppLocalizations l10n) => SizedBox(
    height: AuthMetrics.navHeight,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _anyLoading ? null : _handleBack,
          icon: const Icon(LucideIcons.chevronLeft, size: 18),
          label: Text(l10n.loginBackLabel),
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.brandDark,
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: _anyLoading ? null : _navigateToSignUp,
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.brandDark,
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.loginSignUpLabel,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  /// "WELCOME" over "BACK.", the second line carrying the yellow swash.
  ///
  /// Both lines come out of the ARB already in display case. Uppercasing in
  /// Dart would be wrong: `toUpperCase()` is locale-sensitive (Turkish dotless
  /// ı, for one), so the casing belongs to the translator, not to the widget.
  Widget _buildHeading(AppLocalizations l10n) => Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.loginHeadingFirstLine, style: AuthMetrics.headingStyle),
        AuthHighlightedText(
          text: l10n.loginHeadingSecondLine,
          style: AuthMetrics.headingStyle,
          color: KolabingColors.primary,
        ),
      ],
    ),
  );

  Widget _buildFooter(AppLocalizations l10n) => Center(
    child: Text.rich(
      TextSpan(
        text: '${l10n.loginNoAccountPrompt} ',
        style: GoogleFonts.inter(fontSize: 14, color: KolabingColors.muted),
        children: [
          TextSpan(
            text: l10n.loginCreateAccountLink,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KolabingColors.brandDark,
            ),
            recognizer: _createAccountTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ),
  );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: KolabingColors.muted,
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    // The design's field is 54 tall with the glyph inset 20 from the edge.
    // Height comes from padding rather than a BoxConstraints clamp: a clamp
    // also caps the decorator when a validation message appears, and Material
    // then squeezes the text instead of growing.
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Icon(prefixIcon, color: KolabingColors.muted, size: 18),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 44),
    border: AuthMetrics.fieldBorder(
      KolabingColors.brandDark.withValues(alpha: 0.12),
    ),
    enabledBorder: AuthMetrics.fieldBorder(
      KolabingColors.brandDark.withValues(alpha: 0.12),
    ),
    focusedBorder: AuthMetrics.fieldBorder(KolabingColors.brandDark),
    errorBorder: AuthMetrics.fieldBorder(KolabingColors.error),
    focusedErrorBorder: AuthMetrics.fieldBorder(KolabingColors.error),
    errorStyle: GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: KolabingColors.error,
    ),
  );
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

/// Full-width social button: dark for Apple, white-with-a-hairline for Google.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
    this.bordered = false,
  });

  final String label;

  /// What a screen reader announces — the short visual label would leave a
  /// blind user with just "Google".
  final String semanticLabel;

  final Widget icon;
  final Color background;
  final Color foreground;
  final bool bordered;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: SizedBox(
      height: _Login.socialHeight,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(_Login.socialHeight / 2),
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: BorderRadius.circular(_Login.socialHeight / 2),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_Login.socialHeight / 2),
              border: bordered
                  ? Border.all(
                      color: KolabingColors.brandDark.withValues(alpha: 0.12),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(foreground),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(width: 10),
                        // Flexible, not bare: the design is drawn at 430pt in
                        // English, and neither holds everywhere — "Continuar con
                        // Google" is longer, and a 320pt phone is narrower.
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: foreground,
                            ),
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
}

/// Metrics only the sign-in page has: the compact social row from variant 1b.
abstract final class _Login {
  static const double socialIcon = 17;
  static const double socialHeight = 52;
  static const double socialGap = 10;
  static const double dividerGap = 22;

  /// Brand names, so they are deliberately not in the ARBs — CLAUDE.md exempts
  /// them from i18n. The full "Continue with …" phrasing still reaches screen
  /// readers through [_SocialButton.semanticLabel].
  static const String googleLabel = 'Google';
  static const String appleLabel = 'Apple';
}

/// A hairline, a label, a hairline.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 1,
          color: KolabingColors.brandDark.withValues(alpha: 0.12),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: KolabingColors.muted),
        ),
      ),
      Expanded(
        child: Container(
          height: 1,
          color: KolabingColors.brandDark.withValues(alpha: 0.12),
        ),
      ),
    ],
  );
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
    backgroundColor: KolabingColors.background,
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
                  color: KolabingColors.primary,
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
