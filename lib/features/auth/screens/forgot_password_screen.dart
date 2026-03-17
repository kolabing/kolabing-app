import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

/// Forgot Password Screen
///
/// Dark themed screen matching login screen style.
/// User enters email, receives a reset link via email.
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
  late final Animation<double> _iconAnimation;
  late final Animation<double> _headlineAnimation;
  late final Animation<double> _formAnimation;
  late final Animation<double> _buttonAnimation;

  late final Animation<Offset> _iconSlideAnimation;
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
        systemNavigationBarColor: KolabingColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _iconAnimation = _createOpacityAnimation(0.0, 0.4);
    _headlineAnimation = _createOpacityAnimation(0.1, 0.5);
    _formAnimation = _createOpacityAnimation(0.2, 0.6);
    _buttonAnimation = _createOpacityAnimation(0.3, 0.7);

    _iconSlideAnimation = _createSlideAnimation(0.0, 0.4);
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
      Tween<Offset>(
        begin: const Offset(0, 30),
        end: Offset.zero,
      ).animate(
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
      await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );
    } on ApiException {
      // Per API spec: always show generic success to avoid email enumeration.
      // Do NOT reveal whether the email exists or not.
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
            const Icon(Icons.wifi_off_rounded,
                color: KolabingColors.textOnDark, size: 20),
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
          backgroundColor: KolabingColors.darkBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar with back button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _handleBack,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 20,
                                color: KolabingColors.textOnDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: KolabingColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _emailSent
                        ? _buildSuccessContent()
                        : _buildFormContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFormContent() => Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Lock icon
            _AnimatedEntry(
              opacity: _iconAnimation,
              slide: _iconSlideAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 40,
                  color: KolabingColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Headline
            _AnimatedEntry(
              opacity: _headlineAnimation,
              slide: _headlineSlideAnimation,
              child: Column(
                children: [
                  Text(
                    'FORGOT PASSWORD?',
                    style: GoogleFonts.rubik(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: KolabingColors.textOnDark,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Enter your email address and we'll send you a link to reset your password.",
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: KolabingColors.textTertiary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Email field
            _AnimatedEntry(
              opacity: _formAnimation,
              slide: _formSlideAnimation,
              child: TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_isLoading,
                validator: _validateEmail,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSendResetLink(),
                style: GoogleFonts.openSans(
                  color: KolabingColors.textOnDark,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  labelStyle: GoogleFonts.openSans(
                    color: KolabingColors.textTertiary,
                  ),
                  hintStyle: GoogleFonts.openSans(
                    color: KolabingColors.textTertiary.withValues(alpha:0.6),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: KolabingColors.textTertiary),
                  filled: true,
                  fillColor: KolabingColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: KolabingColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: KolabingColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: KolabingColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: KolabingColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: KolabingColors.error, width: 2),
                  ),
                  errorStyle: GoogleFonts.openSans(
                    color: KolabingColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Send button
            _AnimatedEntry(
              opacity: _buttonAnimation,
              slide: _buttonSlideAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha:0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              KolabingColors.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'SEND RESET LINK',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      );

  Widget _buildSuccessContent() => Column(
        children: [
          const SizedBox(height: 48),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KolabingColors.success.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: KolabingColors.success,
            ),
          ),

          const SizedBox(height: 32),

          // Success headline
          Text(
            'CHECK YOUR EMAIL',
            style: GoogleFonts.rubik(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: KolabingColors.textOnDark,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Success message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "We've sent a password reset link to",
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // Email address
          Text(
            _emailController.text.trim(),
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: KolabingColors.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Please check your inbox and follow the link to reset your password.',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Back to login button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/auth/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'BACK TO SIGN IN',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Resend link
          TextButton(
            onPressed: () {
              setState(() => _emailSent = false);
            },
            child: Text(
              "Didn't receive the email? Try again",
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      );
}

/// Animated wrapper for staggered entry
class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({
    required this.opacity,
    required this.slide,
    required this.child,
  });

  final Animation<double> opacity;
  final Animation<Offset> slide;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: opacity,
        builder: (context, child) => Transform.translate(
          offset: slide.value,
          child: Opacity(
            opacity: opacity.value,
            child: child,
          ),
        ),
        child: child,
      );
}
