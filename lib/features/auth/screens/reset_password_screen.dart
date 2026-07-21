import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../../../widgets/kolabing_button.dart';
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

  /// Off until the first failed submit, then per-keystroke — clears stale
  /// validation errors as soon as the user corrects the field.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
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
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: KolabingColors.surface,
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
      Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero).animate(
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
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.authPasswordRequired;
    }
    if (value.length < 8) {
      return l10n.authPasswordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.authConfirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return l10n.authPasswordsDoNotMatch;
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    FocusScope.of(context).unfocus();

    if (_token.isEmpty || _email.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context).resetPasswordInvalidLink);
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
      _showErrorSnackBar(AppLocalizations.of(context).authUnexpectedError);
    }
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

  void _showNetworkErrorSnackBar() {
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
          onPressed: _handleResetPassword,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isLoading,
    child: Scaffold(
      backgroundColor: context.colors.surface,
      resizeToAvoidBottomInset: false,
      body: KeyboardAvoidingContent(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isLoading ? null : _handleBack,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 20,
                              color: context.colors.textOnDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).commonBack,
                              style: KolabingTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.colors.textOnDark,
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
    ),
  );

  Widget _buildFormContent() => Form(
    key: _formKey,
    autovalidateMode: _autovalidateMode,
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
              color: context.colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: context.colors.primary,
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
                AppLocalizations.of(context).resetPasswordTitle,
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textOnDark,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context).resetPasswordSubtitle,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: context.colors.textTertiary,
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
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.textOnDark,
                ),
                decoration: _inputDecoration(
                  label: AppLocalizations.of(context).resetPasswordNewLabel,
                  hint: AppLocalizations.of(context).resetPasswordNewHint,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.colors.textTertiary,
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
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.textOnDark,
                ),
                decoration: _inputDecoration(
                  label: AppLocalizations.of(context).authConfirmPasswordLabel,
                  hint: AppLocalizations.of(context).resetPasswordConfirmHint,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.colors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
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
          child: KolabingButton(
            label: AppLocalizations.of(context).resetPasswordButton,
            onPressed: _isLoading ? null : _handleResetPassword,
            variant: KolabingButtonVariant.primary,
            isLoading: _isLoading,
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
          color: context.colors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle_outline_rounded,
          size: 40,
          color: context.colors.success,
        ),
      ),

      const SizedBox(height: 32),

      // Success headline
      Text(
        AppLocalizations.of(context).resetPasswordSuccessTitle,
        style: KolabingTextStyles.bodyLarge.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: context.colors.textOnDark,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 12),

      // Success message
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          AppLocalizations.of(context).resetPasswordSuccessMessage,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.textTertiary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),

      const SizedBox(height: 40),

      // Manual sign in button (in case auto-redirect fails)
      KolabingButton(
        label: AppLocalizations.of(context).resetPasswordGoToSignIn,
        onPressed: () => context.go('/auth/login'),
        variant: KolabingButtonVariant.primary,
      ),

      const SizedBox(height: 32),
    ],
  );

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: KolabingTextStyles.bodyMedium.copyWith(
      color: context.colors.textTertiary,
    ),
    hintStyle: KolabingTextStyles.bodyMedium.copyWith(
      color: context.colors.textTertiary.withValues(alpha: 0.6),
    ),
    prefixIcon: Icon(prefixIcon, color: context.colors.textTertiary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context.colors.darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.colors.error, width: 2),
    ),
    errorStyle: KolabingTextStyles.bodySmall.copyWith(
      color: context.colors.error,
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
      child: Opacity(opacity: opacity.value, child: child),
    ),
    child: child,
  );
}
