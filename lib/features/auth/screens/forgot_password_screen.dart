import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../widgets/auth_brand_hero.dart';

// ---------------------------------------------------------------------------
// Warm-sheet tokens — mirrors login_screen.dart
// ---------------------------------------------------------------------------

const Color _kYellow = Color(0xFFFFE28C);
const Color _kCream = kAuthSheetCream;
const Color _kInk = Color(0xFF19150F);
const Color _kMuted = Color(0xFF8C8474);
const Color _kInputBorder = Color(0xFFE4DCCB);
const Color _kInputFill = Color(0xFFFFFFFF);
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
                      padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
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
                                // Heading
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).forgotPasswordHeroLine1,
                                  style: KolabingTextStyles.displayMedium
                                      .copyWith(
                                        color: _kInk,
                                        height: 0.98,
                                        letterSpacing: 0,
                                      ),
                                ),
                                const SizedBox(height: 6),

                                // Subtitle
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).forgotPasswordFormSubtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kMuted,
                                    height: 1.5,
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
                                  enabled: !_isLoading && !_emailSent,
                                  validator: _validateEmail,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (_emailValid) _handleSendResetLink();
                                  },
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
                                const SizedBox(height: 16),

                                // Network/server error
                                if (_networkError != null) ...[
                                  Text(
                                    _networkError!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFBA1A1A),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // CTA pill / success state
                                if (_emailSent)
                                  _SuccessState(
                                    email: _emailController.text.trim(),
                                    onBackToLogin: _handleGoToLogin,
                                    onTryAnother: () => setState(() {
                                      _emailSent = false;
                                      _emailController.clear();
                                    }),
                                  )
                                else
                                  _SendCta(
                                    isLoading: _isLoading,
                                    isEnabled: _emailValid && !_isLoading,
                                    onPressed: _handleSendResetLink,
                                  ),

                                const SizedBox(height: 16),

                                // Reassurance — always visible
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: _kReassurance,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).forgotPasswordSpamHint,
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

                                const SizedBox(height: 32),

                                // Footer link
                                Center(
                                  child: GestureDetector(
                                    onTap: _isLoading ? null : _handleGoToLogin,
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _kMuted,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                '${AppLocalizations.of(context).forgotPasswordRemembered} ',
                                          ),
                                          TextSpan(
                                            text: AppLocalizations.of(
                                              context,
                                            ).welcomeLogIn,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _kInk,
                                            ),
                                          ),
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

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: _kMuted,
    ),
    prefixIcon: Icon(prefixIcon, color: _kMuted, size: 19),
    prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 56),
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
      borderSide: BorderSide(color: const Color(0xFFBA1A1A)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: const Color(0xFFBA1A1A), width: 1.5),
    ),
    errorStyle: GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFBA1A1A),
    ),
  );
}

// ---------------------------------------------------------------------------
// Send reset link CTA — yellow pill with trailing arrow
// ---------------------------------------------------------------------------

class _SendCta extends StatelessWidget {
  const _SendCta({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isLoading;
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
        opacity: isEnabled ? 1.0 : 0.45,
        child: DecoratedBox(
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
                // FittedBox(scaleDown) so the label+icon shrink together
                // on narrow screens instead of overflowing the pill
                // (matches KolabingButton's compact-width strategy).
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Send reset link',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: _kInk,
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

// ---------------------------------------------------------------------------
// Success state — shown after submit
// ---------------------------------------------------------------------------

class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.email,
    required this.onBackToLogin,
    required this.onTryAnother,
  });

  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onTryAnother;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: double.infinity,
        height: 54,
        child: GestureDetector(
          onTap: onBackToLogin,
          child: DecoratedBox(
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
              child: Text(
                AppLocalizations.of(context).forgotPasswordBackToSignIn,
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
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onTryAnother,
          style: TextButton.styleFrom(
            foregroundColor: _kMuted,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            AppLocalizations.of(context).forgotPasswordUseAnotherEmail,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kMuted,
            ),
          ),
        ),
      ),
    ],
  );
}
