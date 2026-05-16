import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../services/permission_service.dart';
import '../../../../widgets/referral_code_field.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/summary_card.dart';

/// Business Onboarding Final: Summary + Email/Password Registration
class BusinessFinalScreen extends ConsumerStatefulWidget {
  const BusinessFinalScreen({super.key});

  @override
  ConsumerState<BusinessFinalScreen> createState() =>
      _BusinessFinalScreenState();
}

class _BusinessFinalScreenState extends ConsumerState<BusinessFinalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _referralCodeFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _isLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // API validation errors for specific fields
  String? _emailApiError;
  String? _passwordApiError;
  String? _referralCodeApiError;

  @override
  void initState() {
    super.initState();
    _referralCodeController.text =
        ref.read(onboardingProvider)?.referralCode ?? '';
    _configureSystemUI();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _referralCodeFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _handleBack() {
    context.pop();
  }

  void _handleEdit() {
    context.go('/onboarding/business/step2');
  }

  String? _validateEmail(String? value) {
    // Show API error first if present
    if (_emailApiError != null) {
      return _emailApiError;
    }
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // Show API error first if present
    if (_passwordApiError != null) {
      return _passwordApiError;
    }
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  void _clearApiErrors() {
    if (_emailApiError != null ||
        _passwordApiError != null ||
        _referralCodeApiError != null) {
      setState(() {
        _emailApiError = null;
        _passwordApiError = null;
        _referralCodeApiError = null;
      });
    }
  }

  String? _validateReferralCode(String? value) => _referralCodeApiError;

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _finishOnboardingSuccess() async {
    setState(() {
      _isLoading = false;
      _showSuccess = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final hasShownPermissions = await PermissionService.instance
        .hasShownPermissionScreen();
    if (!mounted) return;

    if (!hasShownPermissions) {
      context.go(
        '${KolabingRoutes.permissions}?destination='
        '${Uri.encodeComponent(KolabingRoutes.businessDashboard)}',
      );
    } else {
      context.go(KolabingRoutes.businessDashboard);
    }
  }

  Future<void> _handleSubmit({required bool authenticatedFlow}) async {
    if (_isLoading || _showSuccess) return;

    // Clear any previous API errors before validation
    _clearApiErrors();

    if (!authenticatedFlow && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = authenticatedFlow
        ? await ref
              .read(onboardingProvider.notifier)
              .completeAuthenticatedOnboarding()
        : await ref
              .read(onboardingProvider.notifier)
              .completeWithEmail(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );

    if (!mounted) return;

    if (result.success) {
      await _finishOnboardingSuccess();
    } else if (result.isNetworkError) {
      setState(() => _isLoading = false);
      _showNetworkErrorSnackBar();
    } else {
      // Check for field-specific validation errors
      final apiError = result.error;
      if (apiError != null &&
          !authenticatedFlow &&
          apiError.errors != null &&
          apiError.errors!.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _emailApiError = apiError.getFieldError('email');
          _passwordApiError = apiError.getFieldError('password');
          _referralCodeApiError = apiError.getFriendlyFieldError(
            'referral_code',
          );
        });
        // Trigger form validation to show the errors on fields
        _formKey.currentState!.validate();
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar(result.displayError);
      }
    }
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
          onPressed: () {
            final authState = ref.read(authProvider);
            final authenticatedFlow =
                authState.isAuthenticated && authState.user?.isBusiness == true;
            _handleSubmit(authenticatedFlow: authenticatedFlow);
          },
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final authState = ref.watch(authProvider);
    final authenticatedFlow =
        authState.isAuthenticated && authState.user?.isBusiness == true;

    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/onboarding/business/step5');
      });
      return const SizedBox.shrink();
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
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
                                color: KolabingColors.textPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: KolabingColors.textPrimary,
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
                    padding: EdgeInsets.fromLTRB(24, 0, 24, keyboardInset + 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            authenticatedFlow
                                ? 'FINISH BUSINESS ONBOARDING'
                                : 'CREATE YOUR ACCOUNT',
                            style: GoogleFonts.rubik(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: KolabingColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            authenticatedFlow
                                ? 'Review your imported details one last time and save your business profile.'
                                : 'Enter your email and password to complete registration',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: KolabingColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Summary card (collapsed)
                          SummaryCard(data: data),
                          const SizedBox(height: 8),

                          // Edit button
                          TextButton(
                            onPressed: _isLoading ? null : _handleEdit,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: KolabingColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: KolabingColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!authenticatedFlow) ...[
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              enabled: !_isLoading,
                              validator: _validateEmail,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_emailApiError != null) {
                                  setState(() => _emailApiError = null);
                                }
                              },
                              onFieldSubmitted: (_) {
                                _passwordFocusNode.requestFocus();
                              },
                              scrollPadding: const EdgeInsets.only(bottom: 160),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'your@email.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: KolabingColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.error,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              enabled: !_isLoading,
                              validator: _validatePassword,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_passwordApiError != null) {
                                  setState(() => _passwordApiError = null);
                                }
                              },
                              onFieldSubmitted: (_) {
                                _confirmPasswordFocusNode.requestFocus();
                              },
                              scrollPadding: const EdgeInsets.only(bottom: 160),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Min. 8 characters',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: KolabingColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.error,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            ReferralCodeField(
                              controller: _referralCodeController,
                              focusNode: _referralCodeFocusNode,
                              enabled: !_isLoading,
                              errorText: _validateReferralCode(
                                _referralCodeController.text,
                              ),
                              onChanged: (value) {
                                if (_referralCodeApiError != null) {
                                  setState(() => _referralCodeApiError = null);
                                }
                                ref
                                    .read(onboardingProvider.notifier)
                                    .updateReferralCode(value);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              obscureText: _obscureConfirmPassword,
                              enabled: !_isLoading,
                              validator: _validateConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  _handleSubmit(authenticatedFlow: false),
                              scrollPadding: const EdgeInsets.only(bottom: 160),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: KolabingColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: KolabingColors.error,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: KolabingColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: KolabingColors.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: KolabingColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your account is already created. Tapping the button below will save this onboarding data to the business onboarding endpoint.',
                                      style: GoogleFonts.openSans(
                                        fontSize: 13,
                                        color: KolabingColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleSubmit(
                                  authenticatedFlow: authenticatedFlow,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KolabingColors.primary,
                            foregroundColor: KolabingColors.onPrimary,
                            disabledBackgroundColor: KolabingColors.primary
                                .withValues(alpha: 0.7),
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
                              : _showSuccess
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 24,
                                  color: KolabingColors.onPrimary,
                                )
                              : Text(
                                  authenticatedFlow
                                      ? 'COMPLETE ONBOARDING'
                                      : 'CREATE ACCOUNT',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Terms text
                      Text(
                        authenticatedFlow
                            ? 'We only save the selected Google photos when the onboarding request succeeds.'
                            : 'By creating an account, you agree to our Terms of Service and Privacy Policy',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
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
