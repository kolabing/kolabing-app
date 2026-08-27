import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';

/// Community Onboarding Step 4: About + Social Links (Optional)
class CommunityStep4Screen extends ConsumerStatefulWidget {
  const CommunityStep4Screen({super.key});

  @override
  ConsumerState<CommunityStep4Screen> createState() =>
      _CommunityStep4ScreenState();
}

class _CommunityStep4ScreenState extends ConsumerState<CommunityStep4Screen> {
  final _aboutController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _websiteController = TextEditingController();

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
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _loadExistingData() {
    final data = ref.read(onboardingProvider);
    if (data != null) {
      _aboutController.text = data.about ?? '';
      _instagramController.text = data.instagram ?? '';
      _tiktokController.text = data.tiktok ?? '';
      _websiteController.text =
          data.website?.replaceFirst('https://', '') ?? '';
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _handleBack() {
    _saveData();
    context.pop();
  }

  void _handleSkip() {
    context.push('/onboarding/community/final');
  }

  void _handleContinue() {
    _saveData();
    context.push('/onboarding/community/final');
  }

  void _saveData() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateAbout(_aboutController.text);
    notifier.updateInstagram(_instagramController.text);
    notifier.updateTiktok(_tiktokController.text);
    notifier.updateWebsite(_websiteController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            OnboardingHeader(
              currentStep: 4,
              onBack: _handleBack,
              onSkip: _handleSkip,
              showSkip: true,
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
                        l10n.communityStep4Title,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        l10n.communityStep4Subtitle,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // About field
                    Text(
                      l10n.communityStep4AboutLabel,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aboutController,
                      maxLength: 1000,
                      maxLines: 5,
                      minLines: 3,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.communityStep4AboutHint,
                        hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: context.colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instagram field
                    Text(
                      'Instagram',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instagramController,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.communityStep4UsernameHint,
                        hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.instagram,
                          size: 20,
                          color: context.colors.textTertiary,
                        ),
                        prefixText: '@ ',
                        prefixStyle: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: context.colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // TikTok field
                    Text(
                      'TikTok',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tiktokController,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.communityStep4UsernameHint,
                        hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.music,
                          size: 20,
                          color: context.colors.textTertiary,
                        ),
                        prefixText: '@ ',
                        prefixStyle: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: context.colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Website field
                    Text(
                      l10n.communityStep4WebsiteLabel,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.communityStep4WebsiteHint,
                        hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.globe,
                          size: 20,
                          color: context.colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: context.colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(elevation: 0),
                  child: Text(
                    l10n.commonContinue,
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
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
