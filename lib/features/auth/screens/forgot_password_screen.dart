import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../widgets/kolabing_logo.dart';

const String _kLoginRoute = '/auth/login';
const Color _kForgotBg = Color(0xFF000000);
const Color _kForgotAccent = Color(0xFFFFD861);
const Color _kForgotPanel = Color(0xCC121212);
const Color _kForgotPanelBorder = Color(0x26FFFFFF);
const Color _kForgotFieldFill = Color(0x14FFFFFF);
const Color _kForgotFieldBorder = Color(0x40FFFFFF);
const Color _kForgotTextMuted = Color(0xCCFFFFFF);
const Color _kForgotTextSoft = Color(0x8AFFFFFF);
const String _kForgotHeroImage = 'assets/images/welcome_hero.png';

/// Forgot password screen using the login hero background with reset-only UI.
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
  late final Animation<double> _logoAnimation;
  late final Animation<double> _headlineAnimation;
  late final Animation<double> _formAnimation;
  late final Animation<double> _buttonAnimation;

  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<Offset> _buttonSlideAnimation;

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _entryController.forward();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _kForgotBg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _logoAnimation = _createOpacityAnimation(0.0, 0.4);
    _headlineAnimation = _createOpacityAnimation(0.1, 0.5);
    _formAnimation = _createOpacityAnimation(0.2, 0.6);
    _buttonAnimation = _createOpacityAnimation(0.3, 0.7);

    _logoSlideAnimation = _createSlideAnimation(0.0, 0.4);
    _headlineSlideAnimation = _createSlideAnimation(0.1, 0.5);
    _formSlideAnimation = _createSlideAnimation(0.2, 0.6);
    _buttonSlideAnimation = _createSlideAnimation(0.3, 0.7);
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

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
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

  Future<void> _handleSendResetLink() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.forgotPassword(email: _emailController.text.trim());
    } on ApiException {
      // Generic success response only, to avoid email enumeration.
    } on NetworkException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showNetworkErrorSnackBar();
      return;
    } on Exception {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('An unexpected error occurred');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _emailSent = true;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.openSans(
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

  void _showNetworkErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: KolabingColors.textOnDark,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No internet connection. Please check your network.',
                style: GoogleFonts.openSans(
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
          onPressed: _handleSendResetLink,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isLoading,
    child: Scaffold(
      backgroundColor: _kForgotBg,
      resizeToAvoidBottomInset: false,
      body: KeyboardAvoidingContent(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            final ultraCompact = constraints.maxHeight < 680;
            final horizontalPadding = compact ? 20.0 : 24.0;
            final verticalPadding = ultraCompact
                ? 8.0
                : (compact ? 10.0 : 14.0);
            final logoWidth = ultraCompact ? 126.0 : (compact ? 138.0 : 152.0);
            final headlineSize = ultraCompact ? 27.0 : (compact ? 31.0 : 35.0);

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
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _BackButton(
                              onPressed: _handleBack,
                              isEnabled: !_isLoading,
                            ),
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
                                headlineSize: headlineSize,
                                emailSent: _emailSent,
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
  );

  Widget _buildAuthPanel({required bool compact, required bool ultraCompact}) =>
      Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.all(
                  ultraCompact ? 14 : (compact ? 16 : 18),
                ),
                decoration: BoxDecoration(
                  color: _kForgotPanel,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _kForgotPanelBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _emailSent
                      ? _buildSuccessPanelContent(
                          compact: compact,
                          ultraCompact: ultraCompact,
                          key: const ValueKey('forgot-success'),
                        )
                      : _buildFormPanelContent(
                          compact: compact,
                          ultraCompact: ultraCompact,
                          key: const ValueKey('forgot-form'),
                        ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildFormPanelContent({
    required bool compact,
    required bool ultraCompact,
    Key? key,
  }) => KeyedSubtree(
    key: key,
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset your password',
            style: GoogleFonts.openSans(
              color: Colors.white,
              fontSize: ultraCompact ? 14 : (compact ? 15 : 16),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Enter your account email and we'll send a secure reset link.",
            style: GoogleFonts.openSans(
              color: _kForgotTextMuted,
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
            enabled: !_isLoading,
            validator: _validateEmail,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendResetLink(),
            style: GoogleFonts.openSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _kForgotAccent,
            decoration: _inputDecoration(
              hint: 'Email',
              prefixIcon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'If the email matches an account, the reset link will arrive shortly.',
            style: GoogleFonts.openSans(
              color: _kForgotTextSoft,
              fontSize: ultraCompact ? 11.0 : 11.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          SizedBox(height: ultraCompact ? 12 : 14),
          _AnimatedElement(
            opacityAnimation: _buttonAnimation,
            slideAnimation: _buttonSlideAnimation,
            child: SizedBox(
              width: double.infinity,
              height: ultraCompact ? 44 : (compact ? 46 : 48),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSendResetLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kForgotAccent,
                  foregroundColor: KolabingColors.onPrimary,
                  disabledBackgroundColor: _kForgotAccent.withValues(
                    alpha: 0.70,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            KolabingColors.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'SEND RESET LINK',
                        style: GoogleFonts.rubik(
                          fontSize: compact ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: KolabingColors.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSuccessPanelContent({
    required bool compact,
    required bool ultraCompact,
    Key? key,
  }) => KeyedSubtree(
    key: key,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kForgotAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 24,
            color: _kForgotAccent,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Check your inbox',
          style: GoogleFonts.openSans(
            color: Colors.white,
            fontSize: ultraCompact ? 14 : (compact ? 15 : 16),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'If an account exists for this email, the reset link is on its way.',
          style: GoogleFonts.openSans(
            color: _kForgotTextMuted,
            fontSize: ultraCompact ? 11.5 : 12.5,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        SizedBox(height: ultraCompact ? 10 : 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _kForgotFieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kForgotFieldBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.email_outlined,
                color: _kForgotTextMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _emailController.text.trim(),
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ultraCompact ? 12 : 14),
        _AnimatedElement(
          opacityAnimation: _buttonAnimation,
          slideAnimation: _buttonSlideAnimation,
          child: SizedBox(
            width: double.infinity,
            height: ultraCompact ? 44 : (compact ? 46 : 48),
            child: ElevatedButton(
              onPressed: () => context.go(_kLoginRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kForgotAccent,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'BACK TO SIGN IN',
                style: GoogleFonts.rubik(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: KolabingColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _emailSent = false);
                  },
            style: TextButton.styleFrom(
              foregroundColor: _kForgotAccent,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'Use another email',
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kForgotAccent,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.openSans(
      color: _kForgotTextSoft,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: Icon(prefixIcon, color: _kForgotTextMuted, size: 20),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    isDense: true,
    filled: true,
    fillColor: _kForgotFieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kForgotFieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kForgotFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kForgotAccent, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: KolabingColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: KolabingColors.error, width: 1.6),
    ),
    errorStyle: GoogleFonts.openSans(
      color: const Color(0xFFFFA7B8),
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    ),
  );
}

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
        const ColoredBox(color: _kForgotBg),
        Image.asset(_kForgotHeroImage, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.24),
                Colors.black.withValues(alpha: 0.42),
                Colors.black.withValues(alpha: 0.72),
                _kForgotBg,
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
  const _HeroCopy({required this.headlineSize, required this.emailSent});

  final double headlineSize;
  final bool emailSent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _HeroLine(
        text: emailSent ? 'CHECK YOUR EMAIL.' : 'RESET ACCESS.',
        color: Colors.white,
        size: headlineSize,
      ),
      _HeroLine(
        text: emailSent ? 'OPEN THE LINK.' : 'GET BACK IN.',
        color: Colors.white,
        size: headlineSize,
      ),
      _HeroLine(
        text: emailSent ? "YOU'RE ALMOST IN." : 'FORGOT PASSWORD?',
        color: _kForgotAccent,
        size: headlineSize,
      ),
    ],
  );
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({
    required this.text,
    required this.color,
    required this.size,
  });

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: GoogleFonts.anton(
          color: color,
          fontSize: size,
          height: 0.94,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}

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
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
            Text(
              'Back',
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
