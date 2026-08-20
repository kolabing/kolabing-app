import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants/feature_flags.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../../onboarding/providers/attendee_onboarding_provider.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_navigation.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/terms_consent_checkbox.dart';

/// Attendee Registration Screen
///
/// Simple email/password registration for attendee users.
/// No onboarding steps required.
class AttendeeRegisterScreen extends ConsumerStatefulWidget {
  const AttendeeRegisterScreen({super.key});

  @override
  ConsumerState<AttendeeRegisterScreen> createState() =>
      _AttendeeRegisterScreenState();
}

class _AttendeeRegisterScreenState
    extends ConsumerState<AttendeeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  /// Off until the first failed submit, then per-keystroke — clears stale
  /// validation errors as soon as the user corrects the field.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  String? _emailApiError;
  String? _passwordApiError;

  bool get _anyLoading => _isLoading || _isGoogleLoading || _isAppleLoading;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // Static value: initState runs before Theme is available.
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    if (_emailApiError != null) return _emailApiError;
    if (value == null || value.isEmpty) return l10n.authEmailRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return l10n.authEmailInvalid;
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (_passwordApiError != null) return _passwordApiError;
    if (value == null || value.isEmpty) return l10n.authPasswordRequired;
    if (value.length < 8) return l10n.authPasswordTooShort;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.authConfirmPasswordRequired;
    if (value != _passwordController.text) return l10n.authPasswordsDoNotMatch;
    return null;
  }

  void _clearApiErrors() {
    if (_emailApiError != null || _passwordApiError != null) {
      setState(() {
        _emailApiError = null;
        _passwordApiError = null;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_isLoading || _showSuccess) return;

    _clearApiErrors();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.registerAttendee(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update auth state + reset any provider state from a prior session, so a
      // sign-out -> create-account starts clean (no stale "session expired").
      await ref.read(authProvider.notifier).onRegistered();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // After register, run the attendee onboarding flow (You · City ·
      // Interests · Join) before the dashboard. Permissions are requested at
      // the end of onboarding (the Join step routes through /permissions).
      context.go('/onboarding/attendee/step1');
    } on ApiException catch (e) {
      if (!mounted) return;
      final apiError = e.error;
      if (apiError.errors != null && apiError.errors!.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _emailApiError = apiError.getFieldError('email');
          _passwordApiError = apiError.getFieldError('password');
        });
        _formKey.currentState!.validate();
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar(apiError.message);
      }
    } on NetworkException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showNetworkErrorSnackBar();
    } on Object catch (e) {
      if (!mounted) return;
      debugPrint('[attendee register] $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar(AppLocalizations.of(context).authUnexpectedError);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    if (_anyLoading || _showSuccess) return;
    setState(() => _isGoogleLoading = true);
    await _runSocial(
      () => ref
          .read(authProvider.notifier)
          .signInWithGoogle(userTypeHint: UserType.attendee),
      onCancelOrError: () {
        if (mounted) setState(() => _isGoogleLoading = false);
      },
    );
  }

  Future<void> _handleAppleSignUp() async {
    if (_anyLoading || _showSuccess) return;
    setState(() => _isAppleLoading = true);
    await _runSocial(
      () => ref
          .read(authProvider.notifier)
          .signInWithApple(userTypeHint: UserType.attendee),
      onCancelOrError: () {
        if (mounted) setState(() => _isAppleLoading = false);
      },
    );
  }

  /// Shared driver for the Google/Apple sign-up buttons: on success seeds the
  /// onboarding name (new attendee, best-effort) and routes via
  /// [resolveAuthDestination]; otherwise surfaces cancel/network/error.
  Future<void> _runSocial(
    Future<AuthResult> Function() action, {
    required VoidCallback onCancelOrError,
  }) async {
    try {
      final result = await action();
      if (!mounted) return;

      if (result.success && result.user != null) {
        final user = result.user!;
        if (result.isNewUser &&
            user.isAttendee &&
            (user.name?.trim().isNotEmpty ?? false)) {
          ref
              .read(attendeeOnboardingProvider.notifier)
              .updateName(user.name!.trim());
        }
        setState(() {
          _isGoogleLoading = false;
          _isAppleLoading = false;
          _showSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final route = await gateDestinationOnPermissions(
          resolveAuthDestination(user, isNewUser: result.isNewUser),
        );
        if (!mounted) return;
        context.go(route);
        return;
      }

      onCancelOrError();
      if (result.cancelled) return;
      if (result.isNetworkError) {
        _showNetworkErrorSnackBar();
      } else {
        _showErrorSnackBar(
          result.displayError.isNotEmpty
              ? result.displayError
              : AppLocalizations.of(context).authUnexpectedError,
        );
      }
    } on Object catch (e) {
      debugPrint('[attendee social] $e');
      if (!mounted) return;
      onCancelOrError();
      _showErrorSnackBar(AppLocalizations.of(context).authUnexpectedError);
    }
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
          onPressed: _handleRegister,
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(prefixIcon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context.colors.surface,
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
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_anyLoading,
    child: Scaffold(
      backgroundColor: context.colors.background,
      resizeToAvoidBottomInset: false,
      body: KeyboardAvoidingContent(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _anyLoading ? null : _handleBack,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 20,
                              color: context.colors.onSurface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).commonBack,
                              style: KolabingTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidateMode,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Icon
                        const Text('\u{1F3AF}', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          AppLocalizations.of(context).attendeeRegisterTitle,
                          style: KolabingTextStyles.bodyLarge.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          AppLocalizations.of(context).attendeeRegisterSubtitle,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enabled: !_isLoading,
                          validator: _validateEmail,
                          onChanged: (_) {
                            if (_emailApiError != null) {
                              setState(() => _emailApiError = null);
                            }
                          },
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context).authEmailLabel,
                            hint: AppLocalizations.of(context).authEmailHint,
                            prefixIcon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          enabled: !_isLoading,
                          validator: _validatePassword,
                          onChanged: (_) {
                            if (_passwordApiError != null) {
                              setState(() => _passwordApiError = null);
                            }
                          },
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(
                              context,
                            ).authPasswordLabel,
                            hint: AppLocalizations.of(
                              context,
                            ).attendeeRegisterPasswordHint,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          enabled: !_isLoading,
                          validator: _validateConfirmPassword,
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(
                              context,
                            ).authConfirmPasswordLabel,
                            hint: AppLocalizations.of(
                              context,
                            ).attendeeRegisterConfirmPasswordHint,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Divider above social sign-in
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                AppLocalizations.of(context).authOrContinueWith,
                                style: KolabingTextStyles.bodySmall.copyWith(
                                  color: KolabingColors.textTertiary,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Social sign-in side by side so the page fits the
                        // viewport without scrolling (Apple gated to iOS+flag;
                        // brand-name labels are i18n-exempt).
                        Row(
                          children: [
                            Expanded(
                              child: GoogleSignInButton(
                                onPressed: _handleGoogleSignUp,
                                buttonText: 'Google',
                                isLoading: _isGoogleLoading,
                                showSuccess: _showSuccess,
                                isEnabled:
                                    !_anyLoading &&
                                    !_showSuccess &&
                                    _acceptedTerms,
                                height: 48,
                              ),
                            ),
                            if (Platform.isIOS &&
                                FeatureFlags.attendeeAppleSignupEnabled) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppleSignInButton(
                                  onPressed: _handleAppleSignUp,
                                  buttonText: 'Apple',
                                  isLoading: _isAppleLoading,
                                  showSuccess: _showSuccess,
                                  isEnabled:
                                      !_anyLoading &&
                                      !_showSuccess &&
                                      _acceptedTerms,
                                  height: 48,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    TermsConsentCheckbox(
                      value: _acceptedTerms,
                      enabled: !_anyLoading && !_showSuccess,
                      onChanged: (v) => setState(() => _acceptedTerms = v),
                    ),
                    const SizedBox(height: 12),
                    KolabingButton(
                      label: _showSuccess
                          ? '✓'
                          : AppLocalizations.of(
                              context,
                            ).attendeeRegisterCreateAccount,
                      onPressed: (_isLoading || !_acceptedTerms)
                          ? null
                          : _handleRegister,
                      variant: KolabingButtonVariant.primary,
                      isLoading: _isLoading,
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
