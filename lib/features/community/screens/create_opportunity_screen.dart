import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../onboarding/widgets/photo_upload_widget.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_form_provider.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../../../widgets/time_picker.dart';

/// Multi-step form for creating a collaboration opportunity.
///
/// Five steps:
///   0 - Basic Info (title, description, categories)
///   1 - Business Offer (venue, food, discount, products, other)
///   2 - Community Deliverables (social toggles, attendee count, other)
///   3 - Location & Availability (availability mode, dates, venue mode, city)
///   4 - Review & Publish
class CreateOpportunityScreen extends ConsumerStatefulWidget {
  const CreateOpportunityScreen({super.key, this.editOpportunity});

  /// If non-null the form opens in **edit** mode pre-filled with this data.
  final Opportunity? editOpportunity;

  @override
  ConsumerState<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState
    extends ConsumerState<CreateOpportunityScreen> {
  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Business offer
  final _discountPercentageController = TextEditingController();
  final _businessOfferOtherController = TextEditingController();

  // Community deliverables
  final _deliverablesOtherController = TextEditingController();

  // Location
  final _addressController = TextEditingController();

  // Product controllers managed dynamically
  final List<TextEditingController> _productControllers = [];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  bool get _isEditMode => widget.editOpportunity != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final opp = widget.editOpportunity;
      if (opp != null) {
        ref.read(opportunityFormProvider.notifier).initForEdit(opp);
        _titleController.text = opp.title;
        _descriptionController.text = opp.description;
        _discountPercentageController.text =
            (opp.businessOffer.discount.percentage ?? 0) > 0
            ? opp.businessOffer.discount.percentage.toString()
            : '';
        _businessOfferOtherController.text = opp.businessOffer.other ?? '';
        _deliverablesOtherController.text =
            opp.communityDeliverables.other ?? '';
        _addressController.text = opp.address ?? '';
        // Populate product controllers
        final products = opp.businessOffer.products;
        for (final p in products) {
          _productControllers.add(TextEditingController(text: p));
        }
      } else {
        ref.read(opportunityFormProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _businessOfferOtherController.dispose();
    _deliverablesOtherController.dispose();
    _addressController.dispose();
    for (final c in _productControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation handlers
  // ---------------------------------------------------------------------------

  void _handleNext() {
    final notifier = ref.read(opportunityFormProvider.notifier);
    if (notifier.validateCurrentStep()) {
      notifier.nextStep();
    }
  }

  void _handleBack() {
    final state = ref.read(opportunityFormProvider);
    if (state.currentStep == 0) {
      context.pop();
    } else {
      ref.read(opportunityFormProvider.notifier).previousStep();
    }
  }

  void _showSubscriptionPaywall() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionPaywall(),
    );
    // Reset the flag so it can trigger again
    ref.read(opportunityFormProvider.notifier).clearError();
  }

  Future<void> _handleSaveDraft() async {
    final success = await ref
        .read(opportunityFormProvider.notifier)
        .saveDraft();
    if (success && mounted) {
      _showSuccessDialog(isDraft: true);
    }
  }

  Future<void> _handlePublish() async {
    final success = await ref
        .read(opportunityFormProvider.notifier)
        .saveAndPublish();
    if (success && mounted) {
      _showSuccessDialog(isDraft: false);
    }
  }

  void _showSuccessDialog({required bool isDraft}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: KolabingRadius.borderRadiusLg,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: KolabingColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                size: 48,
                color: KolabingColors.success,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              isDraft ? 'Draft Saved!' : 'Kolab Published!',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              isDraft
                  ? 'Your kolab has been saved as a draft. You can edit and publish it later.'
                  : 'Your kolab is now live. Businesses can start applying!',
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
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'VIEW MY KOLABS',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(opportunityFormProvider);

    // Show subscription paywall when API returns requires_subscription
    ref.listen<OpportunityFormState>(opportunityFormProvider, (previous, next) {
      if (next.requiresSubscription &&
          !(previous?.requiresSubscription ?? false)) {
        _showSubscriptionPaywall();
      }
    });

    return PopScope(
      canPop: !formState.isSubmitting && !formState.isPublishing,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            color: KolabingColors.textPrimary,
            onPressed: formState.isSubmitting || formState.isPublishing
                ? null
                : _handleBack,
          ),
          title: Text(
            _isEditMode ? 'Edit Kolab' : 'Create a Kolab',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
              _buildStepIndicator(formState),
              if (formState.error != null) _buildErrorBanner(formState.error!),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(KolabingSpacing.md),
                  child: _buildCurrentStep(formState),
                ),
              ),
              _buildBottomButtons(formState),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Step Indicator
  // ===========================================================================

  Widget _buildStepIndicator(OpportunityFormState formState) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        border: Border(bottom: BorderSide(color: KolabingColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(formState.totalSteps, (index) {
          final isActive = index == formState.currentStep;
          final isCompleted = index < formState.currentStep;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: isCompleted
                  ? () => ref
                        .read(opportunityFormProvider.notifier)
                        .goToStep(index)
                  : null,
              child: Container(
                width: isActive ? 28 : 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive
                      ? KolabingColors.primary
                      : isCompleted
                      ? KolabingColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive || isCompleted
                        ? KolabingColors.primary
                        : KolabingColors.border,
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // Error Banner
  // ===========================================================================

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      color: KolabingColors.errorBg,
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 18,
            color: KolabingColors.error,
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(opportunityFormProvider.notifier).clearError(),
            child: const Icon(
              LucideIcons.x,
              size: 16,
              color: KolabingColors.error,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step Router
  // ===========================================================================

  Widget _buildCurrentStep(OpportunityFormState formState) {
    switch (formState.currentStep) {
      case 0:
        return _buildStep0BasicInfo(formState);
      case 1:
        return _buildStep1BusinessOffer(formState);
      case 2:
        return _buildStep2Deliverables(formState);
      case 3:
        return _buildStep3Location(formState);
      case 4:
        return _buildStep4Review(formState);
      default:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  // Step 0 - Basic Info
  // ===========================================================================

  Widget _buildStep0BasicInfo(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    _syncController(_titleController, opp.title);
    _syncController(_descriptionController, opp.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: 'BASIC INFORMATION',
          subtitle: 'Describe your collaboration idea',
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Title
        _buildTextField(
          label: 'Title',
          hint: 'e.g., Restaurant Week Promotion',
          controller: _titleController,
          error: formState.fieldErrors['title'],
          maxLength: 255,
          onChanged: (value) =>
              ref.read(opportunityFormProvider.notifier).updateTitle(value),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Description
        _buildTextField(
          label: 'Description',
          hint:
              'Describe your collaboration opportunity in detail. What are you looking for?',
          controller: _descriptionController,
          error: formState.fieldErrors['description'],
          maxLines: 5,
          maxLength: 5000,
          onChanged: (value) => ref
              .read(opportunityFormProvider.notifier)
              .updateDescription(value),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Categories
        _buildLabel('Categories'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Select up to 5 categories',
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: KolabingColors.textTertiary,
          ),
        ),
        if (formState.fieldErrors['categories'] != null) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            formState.fieldErrors['categories']!,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.error,
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.sm),
        Wrap(
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xs,
          children: OpportunityCategories.all.map((category) {
            final isSelected = opp.categories.contains(category);
            return GestureDetector(
              onTap: () => ref
                  .read(opportunityFormProvider.notifier)
                  .toggleCategory(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                  vertical: KolabingSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? KolabingColors.softYellow
                      : KolabingColors.surface,
                  borderRadius: KolabingRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected
                        ? KolabingColors.primary
                        : KolabingColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? KolabingColors.textPrimary
                        : KolabingColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        _buildLabel('Kolab Photo'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Optional, but recommended for Explore.',
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: KolabingColors.textTertiary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        PhotoUploadWidget(
          photoBase64: opp.offerPhoto,
          onPhotoSelected: (file) async {
            await ref
                .read(opportunityFormProvider.notifier)
                .updateOfferPhotoFile(file);
          },
          onPhotoRemoved: () {
            ref.read(opportunityFormProvider.notifier).updateOfferPhoto(null);
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 1 - Business Offer
  // ===========================================================================

  Widget _buildStep1BusinessOffer(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    final offer = opp.businessOffer;

    _syncController(
      _discountPercentageController,
      offer.discount.percentage?.toString() ?? '',
    );
    _syncController(_businessOfferOtherController, offer.other ?? '');

    // Sync product controllers
    _syncProductControllers(offer.products);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: 'WHAT DO YOU NEED FROM THE BUSINESS?',
          subtitle: 'Select what your community expects in this kolab',
        ),
        if (formState.fieldErrors['business_offer'] != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          _buildFieldError(formState.fieldErrors['business_offer']!),
        ],
        const SizedBox(height: KolabingSpacing.lg),

        // Venue toggle
        _buildToggleCard(
          icon: LucideIcons.building,
          title: 'Venue',
          subtitle: 'You need a venue for the event',
          value: offer.venue,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateBusinessOffer(venue: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Food & Drink toggle
        _buildToggleCard(
          icon: LucideIcons.utensils,
          title: 'Food & Drink',
          subtitle: 'You\'d like food or beverages provided',
          value: offer.foodDrink,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateBusinessOffer(foodDrink: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Discount toggle + percentage input
        _buildToggleCard(
          icon: LucideIcons.percent,
          title: 'Discount',
          subtitle: 'Special discount for your community',
          value: offer.discount.enabled,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateBusinessOffer(
                discount: offer.discount.copyWith(
                  enabled: val,
                  clearPercentage: !val,
                ),
              ),
        ),
        if (offer.discount.enabled) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: KolabingSpacing.xl),
            child: _buildTextField(
              label: 'Discount Percentage',
              hint: 'e.g., 20',
              controller: _discountPercentageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _RangeInputFormatter(min: 0, max: 100),
              ],
              onChanged: (value) {
                final pct = int.tryParse(value);
                ref
                    .read(opportunityFormProvider.notifier)
                    .updateBusinessOffer(
                      discount: offer.discount.copyWith(percentage: pct),
                    );
              },
              suffixText: '%',
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.sm),

        // Products (dynamic list)
        _buildToggleCard(
          icon: LucideIcons.packageOpen,
          title: 'Products',
          subtitle: 'You\'d like products or samples',
          value: offer.products.isNotEmpty,
          onChanged: (val) {
            if (val) {
              ref.read(opportunityFormProvider.notifier).addProduct('');
            } else {
              ref
                  .read(opportunityFormProvider.notifier)
                  .updateBusinessOffer(products: []);
            }
          },
        ),
        if (offer.products.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: KolabingSpacing.xl),
            child: Column(
              children: [
                ...List.generate(offer.products.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productControllers[index],
                            style: GoogleFonts.openSans(
                              fontSize: 15,
                              color: KolabingColors.textPrimary,
                            ),
                            decoration: _inputDecoration(hint: 'Product name'),
                            onChanged: (value) => ref
                                .read(opportunityFormProvider.notifier)
                                .updateProduct(index, value),
                          ),
                        ),
                        const SizedBox(width: KolabingSpacing.xs),
                        GestureDetector(
                          onTap: () => ref
                              .read(opportunityFormProvider.notifier)
                              .removeProduct(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: KolabingColors.errorBg,
                              borderRadius: KolabingRadius.borderRadiusSm,
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: KolabingColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: KolabingSpacing.xs),
                GestureDetector(
                  onTap: () =>
                      ref.read(opportunityFormProvider.notifier).addProduct(''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: KolabingSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: KolabingColors.primary,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: KolabingRadius.borderRadiusMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 18,
                          color: KolabingColors.primary,
                        ),
                        const SizedBox(width: KolabingSpacing.xs),
                        Text(
                          'ADD PRODUCT',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.sm),

        // Other toggle + text field
        _buildToggleCard(
          icon: LucideIcons.moreHorizontal,
          title: 'Other',
          subtitle: 'Other support from the business',
          value: offer.other != null,
          onChanged: (val) {
            if (val) {
              ref
                  .read(opportunityFormProvider.notifier)
                  .updateBusinessOffer(other: '');
            } else {
              ref
                  .read(opportunityFormProvider.notifier)
                  .updateBusinessOffer(clearOther: true);
            }
          },
        ),
        if (offer.other != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: KolabingSpacing.xl),
            child: _buildTextField(
              label: 'Other Offer Details',
              hint: 'Describe what the business offers',
              controller: _businessOfferOtherController,
              maxLines: 2,
              onChanged: (value) => ref
                  .read(opportunityFormProvider.notifier)
                  .updateBusinessOffer(other: value),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Step 2 - Community Deliverables
  // ===========================================================================

  Widget _buildStep2Deliverables(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    final deliverables = opp.communityDeliverables;

    _syncController(_deliverablesOtherController, deliverables.other ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: 'COMMUNITY DELIVERABLES',
          subtitle: 'What will the community provide in return?',
        ),
        if (formState.fieldErrors['deliverables'] != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          _buildFieldError(formState.fieldErrors['deliverables']!),
        ],
        const SizedBox(height: KolabingSpacing.lg),

        // Social Media Content
        _buildToggleCard(
          icon: LucideIcons.instagram,
          title: 'Social Media Content',
          subtitle:
              'Instagram Post, Instagram Story, Reel / Short Video, TikTok Video, Photo Content (UGC for brand use)',
          value: deliverables.socialMediaContent,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(socialMediaContent: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Event Activation
        _buildToggleCard(
          icon: LucideIcons.megaphone,
          title: 'Event Activation',
          subtitle: 'Brand integration or mention during our event',
          value: deliverables.eventActivation,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(eventActivation: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Product Placement
        _buildToggleCard(
          icon: LucideIcons.package,
          title: 'Product Placement',
          subtitle: 'Product showcase or visibility during our event',
          value: deliverables.productPlacement,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(productPlacement: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Community Reach
        _buildToggleCard(
          icon: LucideIcons.users,
          title: 'Community Reach',
          subtitle:
              'Minimum attendee guarantee, access to our members, feature, community discount code',
          value: deliverables.communityReach,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(communityReach: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Review & Feedback
        _buildToggleCard(
          icon: LucideIcons.star,
          title: 'Review & Feedback',
          subtitle: 'Google/social reviews, testimonials or member feedback',
          value: deliverables.reviewFeedback,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(reviewFeedback: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Other
        _buildToggleCard(
          icon: LucideIcons.moreHorizontal,
          title: 'Other',
          subtitle: 'Write your own deliverable',
          value: deliverables.other != null,
          onChanged: (val) {
            if (val) {
              ref
                  .read(opportunityFormProvider.notifier)
                  .updateDeliverables(other: '');
            } else {
              ref
                  .read(opportunityFormProvider.notifier)
                  .updateDeliverables(clearOther: true);
            }
          },
        ),
        if (deliverables.other != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: KolabingSpacing.xl),
            child: _buildTextField(
              label: 'Other Deliverable Details',
              hint: 'Describe what the community will deliver',
              controller: _deliverablesOtherController,
              maxLines: 2,
              onChanged: (value) => ref
                  .read(opportunityFormProvider.notifier)
                  .updateDeliverables(other: value),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Step 3 - Location & Availability
  // ===========================================================================

  Widget _buildStep3Location(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    _syncController(_addressController, opp.address ?? '');

    final citiesAsync = ref.watch(citiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: 'LOCATION & AVAILABILITY',
          subtitle: 'When is your community available for this kolab?',
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Availability Mode
        _buildLabel('Availability'),
        const SizedBox(height: KolabingSpacing.xs),
        Row(
          children: AvailabilityMode.values.map((mode) {
            final isSelected = opp.availabilityMode == mode;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: mode != AvailabilityMode.values.last
                      ? KolabingSpacing.xs
                      : 0,
                ),
                child: _buildSelectionCard(
                  icon: _availabilityModeIcon(mode),
                  title: mode.displayName,
                  description: mode.description,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(opportunityFormProvider.notifier)
                      .updateAvailabilityMode(mode),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Mode-specific fields
        ..._buildAvailabilityFields(opp, formState),
        const SizedBox(height: KolabingSpacing.lg),

        // Venue Mode
        _buildLabel('Venue'),
        const SizedBox(height: KolabingSpacing.xs),
        Row(
          children: VenueMode.values.map((mode) {
            final isSelected = opp.venueMode == mode;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: mode != VenueMode.values.last ? KolabingSpacing.xs : 0,
                ),
                child: _buildSelectionCard(
                  icon: _venueModeIcon(mode),
                  title: mode.displayName,
                  description: mode.description,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(opportunityFormProvider.notifier)
                      .updateVenueMode(mode),
                ),
              ),
            );
          }).toList(),
        ),
        if (formState.fieldErrors['address'] != null) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          _buildFieldError(formState.fieldErrors['address']!),
        ],

        // Address (conditional)
        if (opp.venueMode.requiresAddress) ...[
          const SizedBox(height: KolabingSpacing.md),
          _buildTextField(
            label: 'Address',
            hint: 'Enter the venue address',
            controller: _addressController,
            error: formState.fieldErrors['address'],
            onChanged: (value) =>
                ref.read(opportunityFormProvider.notifier).updateAddress(value),
          ),
        ],
        const SizedBox(height: KolabingSpacing.md),

        // Preferred City
        _buildLabel('Preferred City'),
        const SizedBox(height: KolabingSpacing.xxs),
        if (formState.fieldErrors['preferred_city'] != null) ...[
          _buildFieldError(formState.fieldErrors['preferred_city']!),
          const SizedBox(height: KolabingSpacing.xxs),
        ],
        citiesAsync.when(
          loading: () => const LinearProgressIndicator(
            color: KolabingColors.primary,
            backgroundColor: KolabingColors.border,
          ),
          error: (e, _) => Text(
            'Error loading cities: $e',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.error,
            ),
          ),
          data: (cities) => DropdownButtonFormField<String>(
            value: opp.preferredCity.isNotEmpty ? opp.preferredCity : null,
            decoration: _inputDecoration(hint: 'Select city'),
            items: cities
                .map(
                  (city) => DropdownMenuItem(
                    value: city.name,
                    child: Text(city.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(opportunityFormProvider.notifier)
                    .updatePreferredCity(value);
              }
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 4 - Review
  // ===========================================================================

  Widget _buildStep4Review(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: 'REVIEW YOUR OPPORTUNITY',
          subtitle: 'Make sure everything looks correct before publishing',
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Preview card
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(color: KolabingColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                opp.title.isEmpty ? 'Untitled Opportunity' : opp.title,
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                opp.description.isEmpty
                    ? 'No description provided'
                    : opp.description,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Categories
              if (opp.categories.isNotEmpty) ...[
                Wrap(
                  spacing: KolabingSpacing.xxs,
                  runSpacing: KolabingSpacing.xxs,
                  children: opp.categories
                      .map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KolabingSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: KolabingColors.softYellow,
                            borderRadius: KolabingRadius.borderRadiusSm,
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: KolabingColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],

              const Divider(color: KolabingColors.border),
              const SizedBox(height: KolabingSpacing.sm),

              // Business Offer section
              _buildReviewSection(
                icon: LucideIcons.briefcase,
                title: 'Business Offer',
                content: opp.offerSummary,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Deliverables section
              _buildReviewSection(
                icon: LucideIcons.clipboardList,
                title: 'Community Deliverables',
                content: opp.deliverablesSummary,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              const Divider(color: KolabingColors.border),
              const SizedBox(height: KolabingSpacing.sm),

              // Location info
              _buildReviewInfoRow(
                LucideIcons.mapPin,
                opp.preferredCity.isNotEmpty
                    ? opp.preferredCity
                    : 'No city selected',
              ),
              const SizedBox(height: KolabingSpacing.xs),

              if (opp.address?.isNotEmpty == true) ...[
                _buildReviewInfoRow(LucideIcons.navigation, opp.address!),
                const SizedBox(height: KolabingSpacing.xs),
              ],

              // Availability mode + details
              _buildReviewInfoRow(
                _availabilityModeIcon(opp.availabilityMode),
                opp.availabilityMode.displayName,
              ),
              const SizedBox(height: KolabingSpacing.xs),

              if (opp.availabilityMode == AvailabilityMode.recurring) ...[
                _buildReviewInfoRow(
                  LucideIcons.calendar,
                  'Every ${opp.recurringDays.isNotEmpty ? opp.recurringDays.map((d) => _dayNames[d - 1]).join(', ') : '—'}'
                  '${opp.selectedTime != null ? ' at ${opp.selectedTime!.format(context)}' : ''}',
                ),
              ] else ...[
                _buildReviewInfoRow(
                  LucideIcons.calendar,
                  '${dateFormat.format(opp.availabilityStart)} – ${dateFormat.format(opp.availabilityEnd)}'
                  '${opp.availabilityMode == AvailabilityMode.oneTime && opp.selectedTime != null ? ' at ${opp.selectedTime!.format(context)}' : ''}'
                  '${opp.availabilityMode == AvailabilityMode.flexible ? ' (flexible time)' : ''}',
                ),
              ],
              const SizedBox(height: KolabingSpacing.xs),

              // Venue mode
              _buildReviewInfoRow(
                LucideIcons.building,
                opp.venueMode.displayName,
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Edit hint
        Center(
          child: GestureDetector(
            onTap: () => ref.read(opportunityFormProvider.notifier).goToStep(0),
            child: Text(
              'Tap any section above to edit',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.textTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Bottom Buttons
  // ===========================================================================

  Widget _buildBottomButtons(OpportunityFormState formState) {
    final isBusy = formState.isSubmitting || formState.isPublishing;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: formState.isReviewStep
            ? _buildReviewButtons(formState, isBusy)
            : _buildNavigationButtons(formState, isBusy),
      ),
    );
  }

  Widget _buildNavigationButtons(OpportunityFormState formState, bool isBusy) {
    return Row(
      children: [
        if (formState.currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: isBusy ? null : _handleBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'BACK',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
        ],
        Expanded(
          flex: formState.currentStep > 0 ? 2 : 1,
          child: ElevatedButton(
            onPressed: isBusy ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              disabledBackgroundColor: KolabingColors.primary.withValues(
                alpha: 0.7,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
            child: Text(
              'CONTINUE',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewButtons(OpportunityFormState formState, bool isBusy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Publish button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isBusy ? null : _handlePublish,
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              disabledBackgroundColor: KolabingColors.primary.withValues(
                alpha: 0.7,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
            child: formState.isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        KolabingColors.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    'PUBLISH',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Save as draft + Back row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : _handleBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KolabingColors.textPrimary,
                  side: const BorderSide(color: KolabingColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: KolabingRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  'BACK',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : _handleSaveDraft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KolabingColors.textPrimary,
                  side: const BorderSide(color: KolabingColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: KolabingRadius.borderRadiusMd,
                  ),
                ),
                child: formState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            KolabingColors.textSecondary,
                          ),
                        ),
                      )
                    : Text(
                        'SAVE DRAFT',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Shared UI Components
  // ===========================================================================

  Widget _buildStepHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          subtitle,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: value ? KolabingColors.primary : KolabingColors.border,
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? KolabingColors.softYellow
                  : KolabingColors.surfaceVariant,
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 20,
              color: value
                  ? KolabingColors.primary
                  : KolabingColors.textTertiary,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: KolabingColors.primary.withValues(alpha: 0.5),
            thumbColor: WidgetStatePropertyAll(
              value ? KolabingColors.primary : KolabingColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? KolabingColors.softYellow
              : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected ? KolabingColors.primary : KolabingColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? KolabingColors.primary
                  : KolabingColors.textTertiary,
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              title,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: GoogleFonts.openSans(
                fontSize: 10,
                color: KolabingColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? error,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: KolabingSpacing.xxs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: KolabingColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.openSans(color: KolabingColors.textTertiary),
            filled: true,
            fillColor: KolabingColors.surface,
            counterText: maxLength != null ? null : '',
            suffixText: suffixText,
            suffixStyle: GoogleFonts.openSans(
              fontSize: 15,
              color: KolabingColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(
                color: KolabingColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.error),
            ),
            errorText: error,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(color: KolabingColors.textTertiary),
      filled: true,
      fillColor: KolabingColors.surface,
      border: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusMd,
        borderSide: const BorderSide(color: KolabingColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusMd,
        borderSide: const BorderSide(color: KolabingColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusMd,
        borderSide: const BorderSide(color: KolabingColors.primary, width: 2),
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
    label,
    style: GoogleFonts.openSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: KolabingColors.textPrimary,
    ),
  );

  Widget _buildFieldError(String error) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: KolabingColors.errorBg,
      borderRadius: KolabingRadius.borderRadiusSm,
    ),
    child: Row(
      children: [
        const Icon(
          LucideIcons.alertCircle,
          size: 14,
          color: KolabingColors.error,
        ),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.error,
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Availability mode-specific fields
  // ---------------------------------------------------------------------------

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<Widget> _buildAvailabilityFields(
    Opportunity opp,
    OpportunityFormState formState,
  ) {
    switch (opp.availabilityMode) {
      case AvailabilityMode.oneTime:
        return _buildOneTimeFields(opp, formState);
      case AvailabilityMode.recurring:
        return _buildRecurringFields(opp, formState);
      case AvailabilityMode.flexible:
        return _buildFlexibleFields(opp, formState);
    }
  }

  /// A) Date Range (Same Time) — Available From, Available Until, Time
  List<Widget> _buildOneTimeFields(
    Opportunity opp,
    OpportunityFormState formState,
  ) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildDatePicker(
              label: 'Available From',
              value: opp.availabilityStart,
              error: formState.fieldErrors['availability_start'],
              onChanged: (date) => ref
                  .read(opportunityFormProvider.notifier)
                  .updateStartDate(date),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: _buildDatePicker(
              label: 'Available Until',
              value: opp.availabilityEnd,
              error: formState.fieldErrors['availability_end'],
              minDate: opp.availabilityStart,
              onChanged: (date) => ref
                  .read(opportunityFormProvider.notifier)
                  .updateEndDate(date),
            ),
          ),
        ],
      ),
      const SizedBox(height: KolabingSpacing.sm),
      _buildTimePicker(
        label: 'Time',
        value: opp.selectedTime,
        error: formState.fieldErrors['selected_time'],
        onChanged: (time) =>
            ref.read(opportunityFormProvider.notifier).updateSelectedTime(time),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        'e.g. Any day from ${DateFormat('MMM d').format(opp.availabilityStart)} '
        'to ${DateFormat('MMM d').format(opp.availabilityEnd)} '
        'at ${opp.selectedTime != null ? opp.selectedTime!.format(context) : '—'}',
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: KolabingColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  /// B) Recurring — Days of week (multi-select), Time
  List<Widget> _buildRecurringFields(
    Opportunity opp,
    OpportunityFormState formState,
  ) {
    final selectedDaysSummary = opp.recurringDays.isNotEmpty
        ? opp.recurringDays.map((d) => _dayNames[d - 1]).join(', ')
        : '—';

    return [
      _buildLabel('Day of Week'),
      const SizedBox(height: KolabingSpacing.xxs),
      if (formState.fieldErrors['recurring_day'] != null) ...[
        _buildFieldError(formState.fieldErrors['recurring_day']!),
        const SizedBox(height: KolabingSpacing.xxs),
      ],
      Row(
        children: List.generate(7, (i) {
          final dayIndex = i + 1;
          final isSelected = opp.recurringDays.contains(dayIndex);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
              child: GestureDetector(
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .toggleRecurringDay(dayIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KolabingColors.softYellow
                        : KolabingColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? KolabingColors.primary
                          : KolabingColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _dayNames[i].substring(0, 3),
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? KolabingColors.textPrimary
                          : KolabingColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: KolabingSpacing.sm),
      _buildTimePicker(
        label: 'Time',
        value: opp.selectedTime,
        error: formState.fieldErrors['selected_time'],
        onChanged: (time) =>
            ref.read(opportunityFormProvider.notifier).updateSelectedTime(time),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        'e.g. Every $selectedDaysSummary '
        'at ${opp.selectedTime != null ? opp.selectedTime!.format(context) : '—'}',
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: KolabingColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  /// C) Flexible Window — Available From, Available Until, no fixed time
  List<Widget> _buildFlexibleFields(
    Opportunity opp,
    OpportunityFormState formState,
  ) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildDatePicker(
              label: 'Available From',
              value: opp.availabilityStart,
              error: formState.fieldErrors['availability_start'],
              onChanged: (date) => ref
                  .read(opportunityFormProvider.notifier)
                  .updateStartDate(date),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: _buildDatePicker(
              label: 'Available Until',
              value: opp.availabilityEnd,
              error: formState.fieldErrors['availability_end'],
              minDate: opp.availabilityStart,
              onChanged: (date) => ref
                  .read(opportunityFormProvider.notifier)
                  .updateEndDate(date),
            ),
          ),
        ],
      ),
      const SizedBox(height: KolabingSpacing.sm),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow.withValues(alpha: 0.5),
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: KolabingColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.clock,
              size: 16,
              color: KolabingColors.textSecondary,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              'Time: Flexible — no fixed time',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        'Businesses will propose a specific date and time within this window.',
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: KolabingColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Time picker helper
  // ---------------------------------------------------------------------------

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? value,
    String? error,
    required ValueChanged<TimeOfDay?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: KolabingSpacing.xxs),
        GestureDetector(
          onTap: () async {
            final picked = await KolabingTimePicker.show(
              context,
              initialTime: value ?? const TimeOfDay(hour: 10, minute: 0),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color: error != null
                    ? KolabingColors.error
                    : KolabingColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 18,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  value != null ? value.format(context) : 'Select time',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: value != null
                        ? KolabingColors.textPrimary
                        : KolabingColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    String? error,
    DateTime? minDate,
    required ValueChanged<DateTime> onChanged,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: KolabingSpacing.xxs),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: minDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: KolabingColors.primary,
                    onPrimary: KolabingColors.onPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color: error != null
                    ? KolabingColors.error
                    : KolabingColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    dateFormat.format(value),
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.error,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Review helpers
  // ===========================================================================

  Widget _buildReviewSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: KolabingColors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewInfoRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: KolabingColors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Icon helpers
  // ===========================================================================

  IconData _availabilityModeIcon(AvailabilityMode mode) {
    switch (mode) {
      case AvailabilityMode.oneTime:
        return LucideIcons.calendarCheck;
      case AvailabilityMode.recurring:
        return LucideIcons.repeat;
      case AvailabilityMode.flexible:
        return LucideIcons.calendarRange;
    }
  }

  IconData _venueModeIcon(VenueMode mode) {
    switch (mode) {
      case VenueMode.businessVenue:
        return LucideIcons.store;
      case VenueMode.communityVenue:
        return LucideIcons.home;
      case VenueMode.noVenue:
        return LucideIcons.globe;
    }
  }

  // ===========================================================================
  // Controller sync helpers
  // ===========================================================================

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  void _syncProductControllers(List<String> products) {
    // Add missing controllers
    while (_productControllers.length < products.length) {
      _productControllers.add(TextEditingController());
    }
    // Remove excess controllers
    while (_productControllers.length > products.length) {
      _productControllers.removeLast().dispose();
    }
    // Sync values
    for (var i = 0; i < products.length; i++) {
      if (_productControllers[i].text != products[i]) {
        _productControllers[i].text = products[i];
      }
    }
  }
}

// =============================================================================
// Input Formatter
// =============================================================================

/// Restricts numeric input to a min/max range.
class _RangeInputFormatter extends TextInputFormatter {
  _RangeInputFormatter({required this.min, required this.max});

  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < min || value > max) return oldValue;

    return newValue;
  }
}
