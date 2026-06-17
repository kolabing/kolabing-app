import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../community/models/verification_channel.dart';
import '../../../community/widgets/verification_channel_repeater.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';

/// Community Onboarding Step 4: About + verification channel repeater.
///
/// Replaces the old fixed Instagram/TikTok/Website fields with a dynamic
/// repeater of {type,url} verification channels. At least one channel is
/// required to "Continue" (request verification); "Skip for now" proceeds with
/// none (the community stays unverified).
class CommunityStep4Screen extends ConsumerStatefulWidget {
  const CommunityStep4Screen({super.key});

  @override
  ConsumerState<CommunityStep4Screen> createState() =>
      _CommunityStep4ScreenState();
}

class _CommunityStep4ScreenState extends ConsumerState<CommunityStep4Screen> {
  final _aboutController = TextEditingController();
  List<VerificationChannel> _channels = const [];
  bool _showNeedChannelError = false;

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
      _channels = List<VerificationChannel>.from(data.verificationChannels);
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  /// Channels that have a plausibly-valid value for their type.
  List<VerificationChannel> get _validChannels => _channels
      .where((c) => isValidChannelValue(c.type, c.url))
      .map((c) => c.copyWith(url: c.url.trim()))
      .toList(growable: false);

  void _handleBack() {
    _saveData();
    context.pop();
  }

  void _handleSkip() {
    // Skip = proceed with no channels (stays unverified). Persist About only,
    // and clear any half-typed channels so we never send invalid rows.
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateAbout(_aboutController.text);
    notifier.updateVerificationChannels(const []);
    context.push('/onboarding/community/final');
  }

  void _handleContinue() {
    final valid = _validChannels;
    if (valid.isEmpty) {
      setState(() => _showNeedChannelError = true);
      return;
    }
    _saveData();
    context.push('/onboarding/community/final');
  }

  void _saveData() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateAbout(_aboutController.text);
    notifier.updateVerificationChannels(_validChannels);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 4,
              onBack: _handleBack,
              onSkip: _handleSkip,
              showSkip: true,
            ),
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
                        l10n.verificationStepTitle,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Explanatory copy
                    Center(
                      child: Text(
                        l10n.verificationStepSubtitle,
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
                          borderSide:
                              BorderSide(color: context.colors.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verification channel repeater
                    VerificationChannelRepeater(
                      channels: _channels,
                      onChanged: (next) => setState(() {
                        _channels = next;
                        if (next.isNotEmpty) _showNeedChannelError = false;
                      }),
                    ),

                    if (_showNeedChannelError) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.verificationNeedOneChannel,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ],
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
