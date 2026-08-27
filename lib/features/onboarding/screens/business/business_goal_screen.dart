import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/models/user_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';

/// Business onboarding goal step.
///
/// First screen of business onboarding. The chosen goal branches the flow:
/// - "Fill my venue" (`has_venue = true`) -> the venue path (Google Places
///   lookup at `/onboarding/business/step5`).
/// - "Promote a product/service" (`has_venue = false`) -> the product path
///   (`/onboarding/business/product/identity`).
class BusinessGoalScreen extends ConsumerStatefulWidget {
  const BusinessGoalScreen({super.key});

  @override
  ConsumerState<BusinessGoalScreen> createState() => _BusinessGoalScreenState();
}

class _BusinessGoalScreenState extends ConsumerState<BusinessGoalScreen> {
  bool? _hasVenue;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    if (ref.read(onboardingProvider) == null) {
      ref.read(onboardingProvider.notifier).initialize(UserType.business);
    }
    _hasVenue = ref.read(onboardingProvider)?.hasVenue;
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

  void _handleBack() => context.pop();

  void _select(bool hasVenue) {
    setState(() => _hasVenue = hasVenue);
  }

  void _handleContinue() {
    final hasVenue = _hasVenue;
    if (hasVenue == null) return;
    ref
        .read(onboardingProvider.notifier)
        .selectBusinessGoal(hasVenue: hasVenue);
    if (hasVenue) {
      context.push(KolabingRoutes.businessOnboardingStep5);
    } else {
      context.push(KolabingRoutes.businessOnboardingProductIdentity);
    }
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
              currentStep: 1,
              totalSteps: 4,
              onBack: _handleBack,
              showSkip: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      l10n.businessGoalTitle,
                      style: KolabingTextStyles.bodyLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.businessGoalSubtitle,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _GoalCard(
                      icon: LucideIcons.store,
                      title: l10n.businessGoalVenueTitle,
                      description: l10n.businessGoalVenueDescription,
                      isSelected: _hasVenue == true,
                      onTap: () => _select(true),
                    ),
                    const SizedBox(height: 16),
                    _GoalCard(
                      icon: LucideIcons.package,
                      title: l10n.businessGoalProductTitle,
                      description: l10n.businessGoalProductDescription,
                      isSelected: _hasVenue == false,
                      onTap: () => _select(false),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _hasVenue != null ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    disabledBackgroundColor: context.colors.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: context.colors.onPrimary
                        .withValues(alpha: 0.5),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.commonContinue,
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
                      letterSpacing: 1,
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.mediumImpact();
      onTap();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? context.colors.softYellow : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? context.colors.primary
              : context.colors.darkBorder,
          width: isSelected ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 26,
              color: isSelected
                  ? context.colors.onPrimary
                  : context.colors.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 22,
            color: isSelected
                ? context.colors.primary
                : context.colors.textTertiary,
          ),
        ],
      ),
    ),
  );
}
