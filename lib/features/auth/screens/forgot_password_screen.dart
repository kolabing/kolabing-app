import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../widgets/auth_brand_hero.dart';
import '../widgets/auth_form.dart';

// ---------------------------------------------------------------------------
// Warm-sheet tokens — mirrors login_screen.dart
// ---------------------------------------------------------------------------

const Color _kCream = kAuthSheetCream;
const Color _kInk = KolabingColors.ink;
const Color _kMuted = KolabingColors.muted;
const Color _kReassurance = Color(0xFF9A9281);

const String _kLoginRoute = '/auth/login';

/// Height of the area the K and KOLABING sit in, between nav row and sheet.
const double _kMarkAreaHeight = 120;

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
    // Repaint the focus halo as the field gains and loses focus.
    _emailFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(kAuthHeroOverlayStyle);
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
    _emailFocusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
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
    final size = MediaQuery.sizeOf(context);
    final heroHeight =
        MediaQuery.paddingOf(context).top +
        AuthBrandHero.navHeight +
        _kMarkAreaHeight +
        AuthBrandHero.sheetRadius;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: _kCream,
        resizeToAvoidBottomInset: true,
        body: FadeTransition(
          opacity: _fadeIn,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _kCream)),

              // Main layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandHero(
                    height: heroHeight,
                    markHeight: 64,
                    reveal: _fadeIn,
                    leading: AuthHeroBackButton(
                      onTap: _handleBack,
                      isEnabled: !_isLoading,
                      semanticLabel: AppLocalizations.of(context).commonBack,
                    ),
                  ),

                  // Cream sheet
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SafeArea(
                        top: false,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: size.height - heroHeight - 80,
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autovalidateMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Heading — same type as login
                                Text(
                                  l10n.forgotPasswordHeroLine1,
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
                                  l10n.forgotPasswordFormSubtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _kMuted,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                if (_emailSent) ...[
                                  _SentCard(
                                    title: l10n.forgotPasswordSuccessTitle,
                                    message: l10n.forgotPasswordSuccessSubtitle,
                                    email: _emailController.text.trim(),
                                  ),
                                  const SizedBox(height: 24),
                                  AuthPrimaryCta(
                                    key: const Key('forgot-back-to-login'),
                                    label: l10n.forgotPasswordBackToSignInCta,
                                    onPressed: _handleGoToLogin,
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: AuthInlineLink(
                                      label: l10n.forgotPasswordUseAnotherEmail,
                                      onTap: () => setState(() {
                                        _emailSent = false;
                                        _emailController.clear();
                                      }),
                                    ),
                                  ),
                                ] else ...[
                                  // Email
                                  AuthFieldLabel(text: l10n.authEmailLabel),
                                  const SizedBox(height: 8),
                                  AuthFocusGlow(
                                    focused: _emailFocusNode.hasFocus,
                                    child: TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      enabled: !_isLoading,
                                      validator: _validateEmail,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        if (_emailValid) _handleSendResetLink();
                                      },
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
                                  const SizedBox(height: 12),

                                  // Network/server error
                                  if (_networkError != null) ...[
                                    Text(
                                      _networkError!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: context.colors.error,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 12),

                                  AuthPrimaryCta(
                                    label: l10n.forgotPasswordSendLink,
                                    isLoading: _isLoading,
                                    isEnabled: _emailValid && !_isLoading,
                                    onPressed: _handleSendResetLink,
                                  ),
                                  const SizedBox(height: 16),

                                  // Reassurance
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          size: 14,
                                          color: _kReassurance,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.forgotPasswordSpamHint,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: _kReassurance,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // After sending, "Back to sign in" already does this.
                                if (!_emailSent) ...[
                                  const SizedBox(height: 28),
                                  AuthFooterLink(
                                    inkKey: const Key('forgot-login-link'),
                                    prompt: l10n.forgotPasswordRemembered,
                                    action: l10n.welcomeLogIn,
                                    isEnabled: !_isLoading,
                                    onTap: _handleGoToLogin,
                                  ),
                                ],
                              ],
                            ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// "Check your inbox" — shown after the reset link is requested
// ---------------------------------------------------------------------------

class _SentCard extends StatelessWidget {
  const _SentCard({
    required this.title,
    required this.message,
    required this.email,
  });

  final String title;
  final String message;
  final String email;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('forgot-sent-card'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: KolabingColors.outlineVariant, width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: KolabingColors.tertiaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 20,
            color: KolabingColors.tertiary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                  height: 1.45,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
