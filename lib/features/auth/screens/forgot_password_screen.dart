import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_page.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Warm-sheet tokens — mirrors login_screen.dart
// ---------------------------------------------------------------------------

const String _kLoginRoute = '/auth/login';

// ---------------------------------------------------------------------------
// ForgotPasswordScreen
// ---------------------------------------------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _authService = AuthService();

  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;

  bool _isLoading = false;

  /// Off until the first failed submit, then per-keystroke — clears stale
  /// validation errors as soon as the user corrects the field.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _emailSent = false;
  String? _networkError;

  bool _emailValid = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entryController.forward();
    _emailController.addListener(_onEmailChanged);
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

  void _onEmailChanged() {
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    final valid = emailRegex.hasMatch(_emailController.text.trim());
    if (valid != _emailValid) {
      setState(() => _emailValid = valid);
    }
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_onEmailChanged)
      ..dispose();
    _emailFocusNode.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_kLoginRoute);
    }
  }

  void _handleGoToLogin() => context.go(_kLoginRoute);

  Future<void> _handleSendResetLink() async {
    if (_isLoading || _emailSent) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _networkError = null;
    });

    try {
      await _authService.forgotPassword(email: _emailController.text.trim());
    } on ApiException {
      // Always show success to avoid account enumeration.
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _networkError = AppLocalizations.of(context).authNoInternet;
      });
      return;
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _networkError = AppLocalizations.of(context).authUnexpectedError;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _emailSent = true;
      _networkError = null;
    });
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.authEmailRequired;
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return l10n.authEmailInvalid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: !_isLoading,
      child: AuthPageScaffold(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthNavRow(
                  backLabel: l10n.loginBackLabel,
                  onBack: _isLoading ? null : _handleBack,
                ),
                AuthHero(
                  headingFirstLine: l10n.forgotPasswordHeadingFirstLine,
                  headingSecondLine: l10n.forgotPasswordHeadingSecondLine,
                  subtitle: l10n.forgotPasswordSubtitle,
                  keyboardOpen: keyboardOpen,
                ),
                const SizedBox(height: AuthMetrics.bodyTop),
                if (_emailSent)
                  _SuccessState(
                    email: _emailController.text.trim(),
                    onUseAnotherEmail: () => setState(() {
                      _emailSent = false;
                      _networkError = null;
                    }),
                    onBackToLogin: _handleGoToLogin,
                  )
                else ...[
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.email],
                    enabled: !_isLoading,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSendResetLink(),
                    style: AuthMetrics.fieldTextStyle,
                    decoration: AuthMetrics.fieldDecoration(
                      hint: l10n.authEmailLabel,
                      prefixIcon: LucideIcons.mail,
                    ),
                  ),
                  if (_networkError != null) ...[
                    const SizedBox(height: AuthMetrics.fieldGap),
                    Text(
                      _networkError!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: KolabingColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AuthMetrics.ctaTop),
                  AuthPrimaryCta(
                    label: l10n.forgotPasswordSendButton,
                    isLoading: _isLoading,
                    // Same rule the sign-in CTA follows: greyed until there is
                    // something to send, rather than waiting for the validator
                    // to complain after a tap.
                    isEnabled: _emailValid && !_isLoading,
                    onPressed: _handleSendResetLink,
                  ),
                  const SizedBox(height: AuthMetrics.fieldGap),
                  Text(
                    l10n.forgotPasswordHelperText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: KolabingColors.muted,
                    ),
                  ),
                ],
                AuthCollapsible(
                  collapsed: keyboardOpen,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AuthMetrics.footerAfterCta),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleGoToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: KolabingColors.brandDark,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            l10n.forgotPasswordBackToSignIn,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }
}

/// What replaces the form once the link is on its way.
class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.email,
    required this.onUseAnotherEmail,
    required this.onBackToLogin,
  });

  final String email;
  final VoidCallback onUseAnotherEmail;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AuthMetrics.hairline, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.mailCheck,
                      size: 20,
                      color: KolabingColors.brandDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.forgotPasswordSuccessTitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KolabingColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.forgotPasswordSuccessSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: KolabingColors.inkBody,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.brandDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AuthMetrics.ctaTop),
        AuthPrimaryCta(
          label: l10n.forgotPasswordBackToSignIn,
          isLoading: false,
          isEnabled: true,
          onPressed: onBackToLogin,
        ),
        const SizedBox(height: AuthMetrics.fieldGap),
        Center(
          child: TextButton(
            onPressed: onUseAnotherEmail,
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.muted,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: Text(
              l10n.forgotPasswordUseAnotherEmail,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
