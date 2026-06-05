import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/permission_service.dart';
import '../../../../widgets/referral_code_field.dart';
import '../../../auth/models/auth_response.dart';
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

  // Persistent error banner for non-field-mapped backend errors (B6
  // diagnostic: 4-second snackbars hid the actual cause of signup failures).
  String? _bannerErrorTitle;
  String? _bannerErrorDetails;

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
    context.go('/onboarding/business/step2');
  }

  String? _validateEmail(String? value) {
    // Show API error first if present
    if (_emailApiError != null) {
      return _emailApiError;
    }
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).businessFinalEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppLocalizations.of(context).businessFinalEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // Show API error first if present
    if (_passwordApiError != null) {
      return _passwordApiError;
    }
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).businessFinalPasswordRequired;
    }
    if (value.length < 8) {
      return AppLocalizations.of(context).businessFinalPasswordTooShort;
    }
    return null;
  }

  void _clearApiErrors() {
    if (_emailApiError != null ||
        _passwordApiError != null ||
        _referralCodeApiError != null ||
        _bannerErrorTitle != null ||
        _bannerErrorDetails != null) {
      setState(() {
        _emailApiError = null;
        _passwordApiError = null;
        _referralCodeApiError = null;
        _bannerErrorTitle = null;
        _bannerErrorDetails = null;
      });
    }
  }

  String? _validateReferralCode(String? value) => _referralCodeApiError;

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).businessFinalConfirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return AppLocalizations.of(context).businessFinalPasswordsMismatch;
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

    debugPrint(
      '[B6] _handleSubmit start (authenticatedFlow=$authenticatedFlow)',
    );

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

    debugPrint(
      '[B6] _handleSubmit result: success=${result.success} '
      'isNetworkError=${result.isNetworkError} '
      'errorStatus=${result.error?.statusCode} '
      'errorMessage=${result.error?.message ?? result.errorMessage}',
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
      final hasMappedFieldError =
          apiError != null &&
          !authenticatedFlow &&
          apiError.errors != null &&
          apiError.errors!.isNotEmpty &&
          (apiError.errors!.containsKey('email') ||
              apiError.errors!.containsKey('password') ||
              apiError.errors!.containsKey('referral_code'));

      if (hasMappedFieldError) {
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
        // Still surface non-mapped errors in the banner if present (e.g. a
        // 422 that includes both `email` AND `primary_venue.photos.0`).
        final unmapped = apiError.errors!.entries
            .where(
              (e) =>
                  e.key != 'email' &&
                  e.key != 'password' &&
                  e.key != 'referral_code',
            )
            .toList();
        if (unmapped.isNotEmpty) {
          final details = unmapped
              .expand((e) => e.value.map((msg) => '• ${e.key}: $msg'))
              .join('\n');
          setState(() {
            _bannerErrorTitle = apiError.message.isEmpty
                ? AppLocalizations.of(context).businessFinalSignupFailed
                : apiError.message;
            _bannerErrorDetails = details;
          });
        }
      } else {
        // Surface every server-side detail in the persistent banner so QA
        // can read and copy it (snackbars disappear after 4 seconds).
        final title = apiError?.message.isNotEmpty == true
            ? apiError!.message
            : (result.errorMessage ??
                  AppLocalizations.of(context).businessFinalSignupFailed);
        final details = _buildBannerDetails(apiError);
        setState(() {
          _isLoading = false;
          _bannerErrorTitle = title;
          _bannerErrorDetails = details;
        });
      }
    }
  }

  /// Combine status code + all server field errors into a copyable block.
  String _buildBannerDetails(ApiError? apiError) {
    final lines = <String>[];
    if (apiError?.statusCode != null) {
      lines.add('Status: ${apiError!.statusCode}');
    }
    if (apiError?.errors != null && apiError!.errors!.isNotEmpty) {
      apiError.errors!.forEach((field, msgs) {
        for (final msg in msgs) {
          lines.add('• $field: $msg');
        }
      });
    }
    return lines.join('\n');
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
                AppLocalizations.of(context).businessFinalNoInternet,
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

  Widget _buildErrorBanner() {
    final title =
        _bannerErrorTitle ??
        AppLocalizations.of(context).businessFinalSignupFailed;
    final details = _bannerErrorDetails;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: context.colors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.error),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _bannerErrorTitle = null;
                  _bannerErrorDetails = null;
                }),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.colors.error,
                ),
              ),
            ],
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.darkBorder),
              ),
              child: SelectableText(
                details,
                style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant, height: 1.5),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () async {
                  final payload = '$title\n$details';
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        ).businessFinalErrorCopied,
                        style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.textOnDark),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: context.colors.error,
                ),
                label: Text(
                  AppLocalizations.of(context).businessFinalCopyDetails,
                  style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w600, color: context.colors.error),
                ),
              ),
            ),
          ],
        ],
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
                                AppLocalizations.of(context).commonBack,
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

                          if (_bannerErrorTitle != null) ...[
                            _buildErrorBanner(),
                            const SizedBox(height: 16),
                          ],

                          // Title
                          Text(
                            authenticatedFlow
                                ? AppLocalizations.of(
                                    context,
                                  ).businessFinalTitleAuthenticated
                                : AppLocalizations.of(
                                    context,
                                  ).businessFinalTitleNewAccount,
                            style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            authenticatedFlow
                                ? AppLocalizations.of(
                                    context,
                                  ).businessFinalSubtitleAuthenticated
                                : AppLocalizations.of(
                                    context,
                                  ).businessFinalSubtitleNewAccount,
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
                                  AppLocalizations.of(context).businessFinalEdit,
                                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary),
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
                                labelText: AppLocalizations.of(
                                  context,
                                ).businessFinalEmailLabel,
                                hintText: AppLocalizations.of(
                                  context,
                                ).businessFinalEmailHint,
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
                                labelText: AppLocalizations.of(
                                  context,
                                ).businessFinalPasswordLabel,
                                hintText: AppLocalizations.of(
                                  context,
                                ).businessFinalPasswordHint,
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
                                labelText: AppLocalizations.of(
                                  context,
                                ).businessFinalConfirmPasswordLabel,
                                hintText: AppLocalizations.of(
                                  context,
                                ).businessFinalConfirmPasswordHint,
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
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.colors.darkBorder,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).businessFinalAuthenticatedInfo,
                                      style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
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
                                  authenticatedFlow
                                      ? AppLocalizations.of(
                                          context,
                                        ).businessFinalCompleteButton
                                      : AppLocalizations.of(
                                          context,
                                        ).businessFinalCreateAccountButton,
                                  style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1.0),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Terms text
                      Text(
                        authenticatedFlow
                            ? AppLocalizations.of(
                                context,
                              ).businessFinalTermsAuthenticated
                            : AppLocalizations.of(
                                context,
                              ).businessFinalTermsNewAccount,
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
