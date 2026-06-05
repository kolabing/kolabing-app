import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/permission_service.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/summary_card.dart';

/// Community Onboarding Final: Summary + Email/Password Registration
class CommunityFinalScreen extends ConsumerStatefulWidget {
  const CommunityFinalScreen({super.key});

  @override
  ConsumerState<CommunityFinalScreen> createState() =>
      _CommunityFinalScreenState();
}

class _CommunityFinalScreenState extends ConsumerState<CommunityFinalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // API validation errors for specific fields
  String? _emailApiError;
  String? _passwordApiError;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: context.colors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _handleBack() {
    context.pop();
  }

  void _handleEdit() {
    context.go('/onboarding/community/step1');
  }

  String? _validateEmail(String? value) {
    // Show API error first if present
    if (_emailApiError != null) {
      return _emailApiError;
    }
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).communityFinalEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppLocalizations.of(context).communityFinalEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // Show API error first if present
    if (_passwordApiError != null) {
      return _passwordApiError;
    }
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).communityFinalPasswordRequired;
    }
    if (value.length < 8) {
      return AppLocalizations.of(context).communityFinalPasswordMinLength;
    }
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).communityFinalConfirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return AppLocalizations.of(context).communityFinalPasswordsMismatch;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_isLoading || _showSuccess) return;

    // Clear any previous API errors before validation
    _clearApiErrors();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref
        .read(onboardingProvider.notifier)
        .completeWithEmail(
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

      // Show permission screen on first registration
      final hasShownPermissions = await PermissionService.instance
          .hasShownPermissionScreen();
      if (!mounted) return;

      if (!hasShownPermissions) {
        context.go(
          '${KolabingRoutes.permissions}?destination='
          '${Uri.encodeComponent(KolabingRoutes.communityDashboard)}',
        );
      } else {
        context.go(KolabingRoutes.communityDashboard);
      }
    } else if (result.isNetworkError) {
      setState(() => _isLoading = false);
      _showNetworkErrorSnackBar();
    } else {
      setState(() => _isLoading = false);

      // Handle validation errors - show under specific fields
      if (result.error?.isValidationError == true &&
          result.error?.errors != null) {
        final emailError = result.error!.getFieldError('email');
        final passwordError = result.error!.getFieldError('password');

        if (emailError != null || passwordError != null) {
          setState(() {
            _emailApiError = emailError;
            _passwordApiError = passwordError;
          });
          // Re-validate to show the field errors
          _formKey.currentState?.validate();
          return;
        }
      }

      // Show generic error in snackbar for non-field errors
      _showErrorSnackBar(result.displayError);
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
                AppLocalizations.of(context).communityFinalNoInternet,
                style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.textOnDark),
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
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.textOnDark),
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);

    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/onboarding/community/step1');
      });
      return const SizedBox.shrink();
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: context.colors.background,
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
                              Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 20,
                                color: context.colors.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.commonBack,
                                style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: context.colors.onSurface),
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
                            l10n.communityFinalTitle,
                            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            l10n.communityFinalSubtitle,
                            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
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
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: context.colors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.communityFinalEdit,
                                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

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
                              labelText: l10n.communityFinalEmailLabel,
                              hintText: l10n.communityFinalEmailHint,
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: context.colors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.error,
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
                              labelText: l10n.communityFinalPasswordLabel,
                              hintText: l10n.communityFinalPasswordHint,
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
                              fillColor: context.colors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.error,
                                ),
                              ),
                            ),
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
                            onFieldSubmitted: (_) => _handleRegister(),
                            scrollPadding: const EdgeInsets.only(bottom: 160),
                            decoration: InputDecoration(
                              labelText: l10n.communityFinalConfirmPasswordLabel,
                              hintText: l10n.communityFinalConfirmPasswordHint,
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
                              fillColor: context.colors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.colors.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: context.colors.onPrimary,
                            disabledBackgroundColor: context.colors.primary
                                .withValues(alpha: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.colors.onPrimary,
                                    ),
                                  ),
                                )
                              : _showSuccess
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 24,
                                  color: context.colors.onPrimary,
                                )
                              : Text(
                                  l10n.communityFinalCreateAccountButton,
                                  style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1.0),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Terms text
                      Text(
                        l10n.communityFinalTermsNotice,
                        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
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
