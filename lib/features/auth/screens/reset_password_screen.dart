import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

/// Reset Password Screen
///
/// Dark themed screen for resetting a password using a token from a deep link.
/// Accessed via /auth/reset-password?token=xxx&email=xxx
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
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
  bool _resetSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _token = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _entryController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = GoRouterState.of(context);
    _token = state.uri.queryParameters['token'] ?? '';
    _email = state.uri.queryParameters['email'] ?? '';
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.go('/auth/login');
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    if (_token.isEmpty || _email.isEmpty) {
      _showErrorSnackBar('Invalid reset link. Please request a new one.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        email: _email,
        token: _token,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _resetSuccess = true;
      });

      // Navigate to login after a delay
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/auth/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.error.isValidationError) {
        final passwordError = e.error.getFieldError('password');
        final tokenError = e.error.getFieldError('token');
        if (tokenError != null) {
          _showErrorSnackBar(tokenError);
          return;
        }
        if (passwordError != null) {
          _showErrorSnackBar(passwordError);
          return;
        }
      }
      _showErrorSnackBar(e.error.message);
    } on NetworkException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showNetworkErrorSnackBar();
    } on Exception {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('An unexpected error occurred');
    }
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
          onPressed: _handleResetPassword,
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
                    child: _resetSuccess
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
                  Icons.lock_outline_rounded,
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
                    'RESET PASSWORD',
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
                      'Enter your new password below.',
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

            // Password fields
            _AnimatedEntry(
              opacity: _formAnimation,
              slide: _formSlideAnimation,
              child: Column(
                children: [
                  // New password field
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    validator: _validatePassword,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      _confirmPasswordFocusNode.requestFocus();
                    },
                    style: GoogleFonts.openSans(
                      color: KolabingColors.textOnDark,
                      fontSize: 16,
                    ),
                    decoration: _inputDecoration(
                      label: 'New Password',
                      hint: 'Enter new password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: KolabingColors.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleResetPassword(),
                    style: GoogleFonts.openSans(
                      color: KolabingColors.textOnDark,
                      fontSize: 16,
                    ),
                    decoration: _inputDecoration(
                      label: 'Confirm Password',
                      hint: 'Confirm new password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: KolabingColors.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reset button
            _AnimatedEntry(
              opacity: _buttonAnimation,
              slide: _buttonSlideAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.7),
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
                          'RESET PASSWORD',
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
              color: KolabingColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: KolabingColors.success,
            ),
          ),

          const SizedBox(height: 32),

          // Success headline
          Text(
            'PASSWORD RESET',
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
              'Your password has been successfully reset. Redirecting you to sign in...',
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Manual sign in button (in case auto-redirect fails)
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
                'GO TO SIGN IN',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      );

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.openSans(
          color: KolabingColors.textTertiary,
        ),
        hintStyle: GoogleFonts.openSans(
          color: KolabingColors.textTertiary.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(prefixIcon, color: KolabingColors.textTertiary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: KolabingColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: KolabingColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KolabingColors.error, width: 2),
        ),
        errorStyle: GoogleFonts.openSans(
          color: KolabingColors.error,
          fontSize: 12,
        ),
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
