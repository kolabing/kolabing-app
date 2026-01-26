import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/theme/colors.dart';
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
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
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
        const SnackBar(
          content: Text('Please enter your display name'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }

    ref.read(onboardingProvider.notifier).updateName(_nameController.text);
    context.push('/onboarding/community/step2');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final canContinue = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: KolabingColors.background,
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
                        'TELL US ABOUT YOU',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        "Let's create your profile",
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textSecondary,
                        ),
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
                          'Display Name',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.error,
                          ),
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
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: KolabingColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your name or handle',
                        hintStyle: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: KolabingColors.surfaceVariant,
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
                          borderSide: const BorderSide(
                            color: KolabingColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        counterStyle: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textTertiary,
                        ),
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
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        KolabingColors.onPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
