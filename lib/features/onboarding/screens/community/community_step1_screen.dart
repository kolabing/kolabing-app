import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/photo_upload_widget.dart';

/// Community Onboarding Step 1: Photo + Display Name
class CommunityStep1Screen extends ConsumerStatefulWidget {
  const CommunityStep1Screen({super.key});

  @override
  ConsumerState<CommunityStep1Screen> createState() =>
      _CommunityStep1ScreenState();
}

class _CommunityStep1ScreenState extends ConsumerState<CommunityStep1Screen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _loadExistingData();
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

  void _loadExistingData() {
    final data = ref.read(onboardingProvider);
    if (data?.name != null) {
      _nameController.text = data!.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
  }

  void _handleContinue() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).communityStep1NameRequired,
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    ref.read(onboardingProvider.notifier).updateName(_nameController.text);
    context.push('/onboarding/community/step2');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);
    final canContinue = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            OnboardingHeader(
              currentStep: 1,
              onBack: _handleBack,
              showSkip: false,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    Center(
                      child: Text(
                        l10n.communityStep1Title,
                        style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        l10n.communityStep1Subtitle,
                        style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Photo upload
                    PhotoUploadWidget(
                      photoBase64: data?.photoBase64,
                      onPhotoSelected: (file) {
                        ref.read(onboardingProvider.notifier).updatePhoto(file);
                      },
                      onPhotoRemoved: () {
                        ref.read(onboardingProvider.notifier).clearPhoto();
                      },
                    ),
                    const SizedBox(height: 24),

                    // Display name label
                    Row(
                      children: [
                        Text(
                          l10n.communityStep1DisplayNameLabel,
                          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Display name input
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      maxLength: 255,
                      onChanged: (value) {
                        setState(() {});
                        ref.read(onboardingProvider.notifier).updateName(value);
                      },
                      style: KolabingTextStyles.bodyMedium.copyWith(color: context.colors.onSurface),
                      decoration: InputDecoration(
                        hintText: l10n.communityStep1NameHint,
                        hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: context.colors.textTertiary),
                        filled: true,
                        fillColor: context.colors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.colors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        counterStyle: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canContinue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    disabledBackgroundColor:
                        context.colors.primary.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        context.colors.onPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.commonContinue,
                    style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
