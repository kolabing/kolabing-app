import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../business/providers/profile_provider.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';
import '../providers/kolab_form_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../widgets/kolab_action_bar.dart';
import '../widgets/kolab_step_indicator.dart';
import 'business/availability_screen.dart';
import 'business/ideal_community_screen.dart';
import 'business/media_screen.dart';
import 'business/offering_screen.dart';
import 'business/past_events_screen.dart';
import 'business/product_details_screen.dart';
import 'business/review_screen.dart' as business_review;
import 'business/venue_details_screen.dart';
import 'community/community_info_screen.dart';
import 'community/event_details_screen.dart';
import 'community/logistics_screen.dart';
import 'community/needs_screen.dart';
import 'community/photo_screen.dart';
import 'community/review_screen.dart' as community_review;

/// Shell screen that wraps the step-based kolab creation flow.
/// Provides Scaffold, AppBar, step indicator, and action bar.
/// Switches content based on intentType + currentStep.
class KolabFlowScreen extends ConsumerStatefulWidget {
  const KolabFlowScreen({super.key, this.editKolab});

  final Kolab? editKolab;

  @override
  ConsumerState<KolabFlowScreen> createState() => _KolabFlowScreenState();
}

class _KolabFlowScreenState extends ConsumerState<KolabFlowScreen> {
  bool _isShowingSubscriptionPaywall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editKolab = widget.editKolab;
      if (editKolab != null) {
        ref.read(kolabFormProvider.notifier).initForEdit(editKolab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final notifier = ref.read(kolabFormProvider.notifier);
    final intentType = formState.intentType;

    // Listen for success
    ref.listen<KolabFormState>(kolabFormProvider, (prev, next) {
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        _showSuccessDialog(context, ref, next.isPublishing);
      }

      final shouldShowPaywall =
          next.requiresSubscription &&
          !(prev?.requiresSubscription ?? false) &&
          !_isShowingSubscriptionPaywall;
      if (shouldShowPaywall) {
        _handleSubscriptionRequirement(
          context,
          ref,
          shouldRetryPublish: prev?.isPublishing ?? false,
        );
      }
    });

    if (intentType == null) {
      return const Scaffold(body: Center(child: Text('No intent selected')));
    }

    final isReviewStep = formState.currentStep == formState.totalSteps - 1;

    return PopScope(
      canPop:
          formState.currentStep == 0 &&
          !formState.isSubmitting &&
          !formState.isPublishing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (formState.isSubmitting || formState.isPublishing) return;
          notifier.previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: KolabingColors.textPrimary,
            ),
            onPressed: () {
              if (formState.isSubmitting || formState.isPublishing) return;
              if (formState.currentStep == 0) {
                context.pop();
              } else {
                notifier.previousStep();
              }
            },
          ),
          title: Text(
            _getTitle(intentType),
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: KolabingColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                  vertical: KolabingSpacing.sm,
                ),
                child: KolabStepIndicator(
                  currentStep: formState.currentStep,
                  totalSteps: formState.totalSteps,
                  onStepTap: (step) {
                    if (step < formState.currentStep) {
                      notifier.goToStep(step);
                    }
                  },
                ),
              ),

              // Error banner
              if (formState.error != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                  ),
                  padding: const EdgeInsets.all(KolabingSpacing.sm),
                  decoration: BoxDecoration(
                    color: KolabingColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Expanded(
                        child: Text(
                          formState.error!,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Step content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildStepContent(intentType, formState.currentStep),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: KolabActionBar(
          onBack: formState.currentStep > 0 ? notifier.previousStep : null,
          onNext: !isReviewStep ? notifier.nextStep : null,
          onSaveDraft: isReviewStep ? notifier.saveDraft : null,
          onPublish: isReviewStep ? notifier.saveAndPublish : null,
          isLastStep: isReviewStep,
          isFirstStep: formState.currentStep == 0,
          isSubmitting: formState.isSubmitting,
          isPublishing: formState.isPublishing,
        ),
      ),
    );
  }

  Future<void> _handleSubscriptionRequirement(
    BuildContext context,
    WidgetRef ref, {
    required bool shouldRetryPublish,
  }) async {
    _isShowingSubscriptionPaywall = true;
    ref.read(kolabFormProvider.notifier).clearSubscriptionRequirement();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionPaywall(),
    );

    if (!mounted) {
      return;
    }

    await ref.read(profileProvider.notifier).refreshSubscription();
    final profileState = ref.read(profileProvider);
    if ((result ?? false) && profileState.isSubscribed && shouldRetryPublish) {
      await ref.read(kolabFormProvider.notifier).saveAndPublish();
    }

    _isShowingSubscriptionPaywall = false;
  }

  String _getTitle(IntentType type) {
    switch (type) {
      case IntentType.communitySeeking:
        return 'FIND A PARTNER';
      case IntentType.venuePromotion:
        return 'PROMOTE VENUE';
      case IntentType.productPromotion:
        return 'PROMOTE PRODUCT';
    }
  }

  Widget _buildStepContent(IntentType intent, int step) {
    switch (intent) {
      case IntentType.communitySeeking:
        return switch (step) {
          0 => const NeedsScreen(),
          1 => const CommunityInfoScreen(),
          2 => const EventDetailsScreen(),
          3 => const LogisticsScreen(),
          4 => const PhotoScreen(),
          5 => const community_review.ReviewScreen(),
          _ => const SizedBox(),
        };
      case IntentType.venuePromotion:
        return switch (step) {
          0 => const VenueDetailsScreen(),
          1 => const MediaScreen(),
          2 => const OfferingScreen(),
          3 => const IdealCommunityScreen(),
          4 => const PastEventsScreen(),
          5 => const AvailabilityScreen(),
          6 => const business_review.ReviewScreen(),
          _ => const SizedBox(),
        };
      case IntentType.productPromotion:
        return switch (step) {
          0 => const ProductDetailsScreen(),
          1 => const MediaScreen(),
          2 => const OfferingScreen(),
          3 => const IdealCommunityScreen(),
          4 => const PastEventsScreen(),
          5 => const AvailabilityScreen(),
          6 => const business_review.ReviewScreen(),
          _ => const SizedBox(),
        };
    }
  }

  void _showSuccessDialog(
    BuildContext context,
    WidgetRef ref,
    bool wasPublished,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: KolabingColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              wasPublished ? 'Kolab Published!' : 'Draft Saved!',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              wasPublished
                  ? 'Your kolab is now visible in Explore.'
                  : 'You can continue editing later.',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(kolabFormProvider.notifier).reset();
                // Pop back to dashboard (IntentSelection + FlowScreen)
                if (context.canPop()) context.pop();
                if (context.canPop()) context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'DONE',
                style: GoogleFonts.darkerGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
