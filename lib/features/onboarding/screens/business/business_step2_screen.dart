import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/theme/colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/type_selection_card.dart';

/// Business Onboarding Step 2: Business Type Selection
class BusinessStep2Screen extends ConsumerStatefulWidget {
  const BusinessStep2Screen({super.key});

  @override
  ConsumerState<BusinessStep2Screen> createState() => _BusinessStep2ScreenState();
}

class _BusinessStep2ScreenState extends ConsumerState<BusinessStep2Screen> {
  @override
  void initState() {
    super.initState();
    _configureSystemUI();
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

  void _handleContinue() {
    final data = ref.read(onboardingProvider);
    if (data?.type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a business type'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }

    context.push('/onboarding/business/step3');
  }

  void _handleTypeSelected(String id, String slug, String name) {
    ref.read(onboardingProvider.notifier).updateType(id, slug, name);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final businessTypes = ref.watch(businessTypesProvider);
    final canContinue = data?.type != null;

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            OnboardingHeader(
              currentStep: 2,
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
                        'WHAT TYPE OF BUSINESS?',
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
                        'This helps us show you to the right communities',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Business types grid
                    businessTypes.when(
                      data: (types) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
                          return TypeSelectionCard(
                            id: type.id,
                            name: type.name,
                            icon: type.icon,
                            isSelected: data?.type == type.id,
                            onTap: () => _handleTypeSelected(type.id, type.slug, type.name),
                          );
                        },
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: KolabingColors.primary,
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: KolabingColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load business types',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: KolabingColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(businessTypesProvider),
                              child: const Text('Retry'),
                            ),
                          ],
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
                  onPressed: canContinue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor: KolabingColors.primary.withValues(alpha: 0.5),
                    disabledForegroundColor: KolabingColors.onPrimary.withValues(alpha: 0.5),
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
