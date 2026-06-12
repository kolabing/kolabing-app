import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/time_picker.dart';
import '../../onboarding/widgets/photo_upload_widget.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_form_provider.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../opportunity/utils/opportunity_share_launcher.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../../../widgets/category_icon.dart';
import '../widgets/opportunity_publish_success_dialog.dart';

/// Multi-step form for creating a collaboration opportunity.
///
/// Five steps:
///   0 - Basic Info (title, description, categories)
///   1 - Business Offer (venue, food, discount, products, other)
///   2 - Community Deliverables (social toggles, attendee count, other)
///   3 - Location & Availability (availability mode, dates, venue mode, city)
///   4 - Review & Publish
class CreateOpportunityScreen extends ConsumerStatefulWidget {
  const CreateOpportunityScreen({
    super.key,
    this.editOpportunity,
    this.opportunityShareLauncher = const OpportunityShareLauncher(),
  });

  /// If non-null the form opens in **edit** mode pre-filled with this data.
  final Opportunity? editOpportunity;
  final OpportunityShareLauncher opportunityShareLauncher;

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
      // Reload My Kolabs so the new opportunity appears without a manual refresh.
      ref.read(myOpportunitiesProvider.notifier).refresh();
      _showSuccessDialog(isDraft: true);
    }
  }

  Future<void> _handlePublish() async {
    final success = await ref
        .read(opportunityFormProvider.notifier)
        .saveAndPublish();
    if (success && mounted) {
      // Reload My Kolabs so the newly PUBLISHED opportunity shows immediately in
      // the Offers/Published tab (the list is a kept-alive Notifier).
      ref.read(myOpportunitiesProvider.notifier).refresh();
      final opportunity = ref.read(opportunityFormProvider).opportunity;
      _showSuccessDialog(isDraft: false, opportunity: opportunity);
    }
  }

  Future<void> _sharePublishedOpportunity(Opportunity opportunity) async {
    final opportunityId = opportunity.id;
    if (opportunityId == null || opportunityId.isEmpty) {
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    await widget.opportunityShareLauncher.launchOpportunityShare(
      title: opportunity.title,
      opportunityId: opportunityId,
      sharePositionOrigin: shareOrigin,
      onFallbackMessage: _showOpportunityShareFallbackMessage,
    );
  }

  void _showOpportunityShareFallbackMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KolabingColors.onSurface,
      ),
    );
  }

  void _showSuccessDialog({required bool isDraft, Opportunity? opportunity}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OpportunityPublishSuccessDialog(
        isDraft: isDraft,
        opportunity: opportunity,
        onShare: opportunity == null
            ? null
            : () => _sharePublishedOpportunity(opportunity),
        onViewOpportunities: () {
          Navigator.of(context).pop();
          this.context.pop();
        },
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
            color: KolabingColors.onSurface,
            onPressed: formState.isSubmitting || formState.isPublishing
                ? null
                : _handleBack,
          ),
          title: Text(
            _isEditMode
                ? AppLocalizations.of(context).createOpportunityEditTitle
                : AppLocalizations.of(context).createOpportunityCreateTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
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
        border: Border(bottom: BorderSide(color: KolabingColors.darkBorder)),
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
                        : KolabingColors.darkBorder,
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
              style: KolabingTextStyles.captionSecondary.copyWith(
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
    final l10n = AppLocalizations.of(context);
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    _syncController(_titleController, opp.title);
    _syncController(_descriptionController, opp.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.createOpportunityStep0Title,
          subtitle: l10n.createOpportunityStep0Subtitle,
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Title
        _buildTextField(
          label: l10n.createOpportunityTitleLabel,
          hint: l10n.createOpportunityTitleHint,
          controller: _titleController,
          error: formState.fieldErrors['title'],
          maxLength: 255,
          onChanged: (value) =>
              ref.read(opportunityFormProvider.notifier).updateTitle(value),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Description
        _buildTextField(
          label: l10n.createOpportunityDescriptionLabel,
          hint: l10n.createOpportunityDescriptionHint,
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
        _buildLabel(l10n.createOpportunityCategoriesLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.createOpportunityCategoriesHint,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: KolabingColors.textTertiary,
          ),
        ),
        if (formState.fieldErrors['categories'] != null) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            formState.fieldErrors['categories']!,
            style: KolabingTextStyles.bodySmall.copyWith(
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
                        : KolabingColors.darkBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcon(name: category, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: KolabingTextStyles.captionSecondary.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? KolabingColors.onSurface
                            : KolabingColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        _buildLabel(l10n.createOpportunityPhotoLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.createOpportunityPhotoHint,
          style: KolabingTextStyles.bodySmall.copyWith(
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
    final l10n = AppLocalizations.of(context);
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
          title: l10n.createOpportunityStep1Title,
          subtitle: l10n.createOpportunityStep1Subtitle,
        ),
        if (formState.fieldErrors['business_offer'] != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          _buildFieldError(formState.fieldErrors['business_offer']!),
        ],
        const SizedBox(height: KolabingSpacing.lg),

        // Venue toggle
        _buildToggleCard(
          icon: LucideIcons.building,
          title: l10n.createOpportunityOfferVenueTitle,
          subtitle: l10n.createOpportunityOfferVenueSubtitle,
          value: offer.venue,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateBusinessOffer(venue: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Food & Drink toggle
        _buildToggleCard(
          icon: LucideIcons.utensils,
          title: l10n.createOpportunityOfferFoodTitle,
          subtitle: l10n.createOpportunityOfferFoodSubtitle,
          value: offer.foodDrink,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateBusinessOffer(foodDrink: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Discount toggle + percentage input
        _buildToggleCard(
          icon: LucideIcons.percent,
          title: l10n.createOpportunityOfferDiscountTitle,
          subtitle: l10n.createOpportunityOfferDiscountSubtitle,
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
              label: l10n.createOpportunityDiscountPercentageLabel,
              hint: l10n.createOpportunityDiscountPercentageHint,
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
          title: l10n.createOpportunityOfferProductsTitle,
          subtitle: l10n.createOpportunityOfferProductsSubtitle,
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
                            style: KolabingTextStyles.bodyMedium.copyWith(
                              fontSize: 15,
                              color: KolabingColors.onSurface,
                            ),
                            decoration: _inputDecoration(
                              hint: l10n.createOpportunityProductNameHint,
                            ),
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
                          l10n.createOpportunityAddProduct,
                          style: KolabingTextStyles.button.copyWith(
                            fontSize: 13,
                            color: KolabingColors.onSurface,
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
          title: l10n.createOpportunityOfferOtherTitle,
          subtitle: l10n.createOpportunityOfferOtherSubtitle,
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
              label: l10n.createOpportunityOfferOtherDetailsLabel,
              hint: l10n.createOpportunityOfferOtherDetailsHint,
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
    final l10n = AppLocalizations.of(context);
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    final deliverables = opp.communityDeliverables;

    _syncController(_deliverablesOtherController, deliverables.other ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.createOpportunityStep2Title,
          subtitle: l10n.createOpportunityStep2Subtitle,
        ),
        if (formState.fieldErrors['deliverables'] != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          _buildFieldError(formState.fieldErrors['deliverables']!),
        ],
        const SizedBox(height: KolabingSpacing.lg),

        // Social Media Content
        _buildToggleCard(
          icon: LucideIcons.instagram,
          title: l10n.createOpportunityDelivSocialTitle,
          subtitle: l10n.createOpportunityDelivSocialSubtitle,
          value: deliverables.socialMediaContent,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(socialMediaContent: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Event Activation
        _buildToggleCard(
          icon: LucideIcons.megaphone,
          title: l10n.createOpportunityDelivEventTitle,
          subtitle: l10n.createOpportunityDelivEventSubtitle,
          value: deliverables.eventActivation,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(eventActivation: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Product Placement
        _buildToggleCard(
          icon: LucideIcons.package,
          title: l10n.createOpportunityDelivProductTitle,
          subtitle: l10n.createOpportunityDelivProductSubtitle,
          value: deliverables.productPlacement,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(productPlacement: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Community Reach
        _buildToggleCard(
          icon: LucideIcons.users,
          title: l10n.createOpportunityDelivReachTitle,
          subtitle: l10n.createOpportunityDelivReachSubtitle,
          value: deliverables.communityReach,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(communityReach: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Review & Feedback
        _buildToggleCard(
          icon: LucideIcons.star,
          title: l10n.createOpportunityDelivReviewTitle,
          subtitle: l10n.createOpportunityDelivReviewSubtitle,
          value: deliverables.reviewFeedback,
          onChanged: (val) => ref
              .read(opportunityFormProvider.notifier)
              .updateDeliverables(reviewFeedback: val),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Other
        _buildToggleCard(
          icon: LucideIcons.moreHorizontal,
          title: l10n.createOpportunityDelivOtherTitle,
          subtitle: l10n.createOpportunityDelivOtherSubtitle,
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
              label: l10n.createOpportunityDelivOtherDetailsLabel,
              hint: l10n.createOpportunityDelivOtherDetailsHint,
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
    final l10n = AppLocalizations.of(context);
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    _syncController(_addressController, opp.address ?? '');

    final citiesAsync = ref.watch(citiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.createOpportunityStep3Title,
          subtitle: l10n.createOpportunityStep3Subtitle,
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Availability Mode
        _buildLabel(l10n.createOpportunityAvailabilityLabel),
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
        _buildLabel(l10n.createOpportunityVenueLabel),
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
            label: l10n.createOpportunityAddressLabel,
            hint: l10n.createOpportunityAddressHint,
            controller: _addressController,
            error: formState.fieldErrors['address'],
            onChanged: (value) =>
                ref.read(opportunityFormProvider.notifier).updateAddress(value),
          ),
        ],
        const SizedBox(height: KolabingSpacing.md),

        // Preferred City
        _buildLabel(l10n.createOpportunityPreferredCityLabel),
        const SizedBox(height: KolabingSpacing.xxs),
        if (formState.fieldErrors['preferred_city'] != null) ...[
          _buildFieldError(formState.fieldErrors['preferred_city']!),
          const SizedBox(height: KolabingSpacing.xxs),
        ],
        citiesAsync.when(
          loading: () => const LinearProgressIndicator(
            color: KolabingColors.primary,
            backgroundColor: KolabingColors.darkBorder,
          ),
          error: (e, _) => Text(
            l10n.createOpportunityCitiesLoadError(e.toString()),
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: KolabingColors.error,
            ),
          ),
          data: (cities) => DropdownButtonFormField<String>(
            value: opp.preferredCity.isNotEmpty ? opp.preferredCity : null,
            decoration: _inputDecoration(
              hint: l10n.createOpportunitySelectCityHint,
            ),
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
    final l10n = AppLocalizations.of(context);
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: l10n.createOpportunityStep4Title,
          subtitle: l10n.createOpportunityStep4Subtitle,
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Preview card
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(color: KolabingColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                opp.title.isEmpty
                    ? l10n.createOpportunityReviewUntitled
                    : opp.title,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                opp.description.isEmpty
                    ? l10n.createOpportunityReviewNoDescription
                    : opp.description,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
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
                            style: KolabingTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: KolabingColors.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],

              const Divider(color: KolabingColors.darkBorder),
              const SizedBox(height: KolabingSpacing.sm),

              // Business Offer section
              _buildReviewSection(
                icon: LucideIcons.briefcase,
                title: l10n.createOpportunityReviewBusinessOffer,
                content: opp.offerSummary,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Deliverables section
              _buildReviewSection(
                icon: LucideIcons.clipboardList,
                title: l10n.createOpportunityReviewDeliverables,
                content: opp.deliverablesSummary,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              const Divider(color: KolabingColors.darkBorder),
              const SizedBox(height: KolabingSpacing.sm),

              // Location info
              _buildReviewInfoRow(
                LucideIcons.mapPin,
                opp.preferredCity.isNotEmpty
                    ? opp.preferredCity
                    : l10n.createOpportunityReviewNoCity,
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
                  '${opp.selectedTime != null ? ' at ${opp.selectedTime!.format(context)}' : ''}',
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
              l10n.createOpportunityReviewEditHint,
              style: KolabingTextStyles.captionSecondary.copyWith(
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        if (formState.currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: isBusy ? null : _handleBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.onSurface,
                side: const BorderSide(color: KolabingColors.darkBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                l10n.createOpportunityBackButton,
                style: KolabingTextStyles.button.copyWith(
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
              l10n.createOpportunityContinueButton,
              style: KolabingTextStyles.button.copyWith(
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewButtons(OpportunityFormState formState, bool isBusy) {
    final l10n = AppLocalizations.of(context);
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
                    l10n.createOpportunityPublishButton,
                    style: KolabingTextStyles.button.copyWith(
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
                  foregroundColor: KolabingColors.onSurface,
                  side: const BorderSide(color: KolabingColors.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: KolabingRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  l10n.createOpportunityBackButton,
                  style: KolabingTextStyles.button.copyWith(
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
                  foregroundColor: KolabingColors.onSurface,
                  side: const BorderSide(color: KolabingColors.darkBorder),
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
                            KolabingColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Text(
                        l10n.createOpportunitySaveDraftButton,
                        style: KolabingTextStyles.button.copyWith(
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
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: KolabingColors.onSurface,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          subtitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: KolabingColors.onSurfaceVariant,
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
          color: value ? KolabingColors.primary : KolabingColors.darkBorder,
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
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: KolabingColors.onSurfaceVariant,
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
              value ? KolabingColors.primary : KolabingColors.onSurfaceVariant,
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
            color: isSelected ? KolabingColors.primary : KolabingColors.darkBorder,
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
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KolabingColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: KolabingTextStyles.labelSmall.copyWith(
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
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: KolabingColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.textTertiary),
            filled: true,
            fillColor: KolabingColors.surface,
            counterText: maxLength != null ? null : '',
            suffixText: suffixText,
            suffixStyle: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              color: KolabingColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: const BorderSide(color: KolabingColors.darkBorder),
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
      hintStyle: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.textTertiary),
      filled: true,
      fillColor: KolabingColors.surface,
      border: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusMd,
        borderSide: const BorderSide(color: KolabingColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusMd,
        borderSide: const BorderSide(color: KolabingColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: KolabingRadius.borderRadiusMd,
        borderSide: const BorderSide(color: KolabingColors.primary, width: 2),
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
    label,
    style: KolabingTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      color: KolabingColors.onSurface,
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
            style: KolabingTextStyles.bodySmall.copyWith(
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
    }
  }

  /// A) Date Range (Same Time) — Available From, Available Until, Time
  List<Widget> _buildOneTimeFields(
    Opportunity opp,
    OpportunityFormState formState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      Row(
        children: [
          Expanded(
            child: _buildDatePicker(
              label: l10n.createOpportunityAvailableFromLabel,
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
              label: l10n.createOpportunityAvailableUntilLabel,
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
        label: l10n.createOpportunityTimeLabel,
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
        style: KolabingTextStyles.bodySmall.copyWith(
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
    final l10n = AppLocalizations.of(context);
    final selectedDaysSummary = opp.recurringDays.isNotEmpty
        ? opp.recurringDays.map((d) => _dayNames[d - 1]).join(', ')
        : '—';

    return [
      _buildLabel(l10n.createOpportunityDayOfWeekLabel),
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
                          : KolabingColors.darkBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _dayNames[i].substring(0, 3),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? KolabingColors.onSurface
                          : KolabingColors.onSurfaceVariant,
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
        label: l10n.createOpportunityTimeLabel,
        value: opp.selectedTime,
        error: formState.fieldErrors['selected_time'],
        onChanged: (time) =>
            ref.read(opportunityFormProvider.notifier).updateSelectedTime(time),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Text(
        'e.g. Every $selectedDaysSummary '
        'at ${opp.selectedTime != null ? opp.selectedTime!.format(context) : '—'}',
        style: KolabingTextStyles.bodySmall.copyWith(
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
                    : KolabingColors.darkBorder,
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
                  value != null
                      ? value.format(context)
                      : AppLocalizations.of(context)
                          .createOpportunitySelectTime,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: value != null
                        ? KolabingColors.onSurface
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
            style: KolabingTextStyles.bodySmall.copyWith(
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
            final firstDate = DateUtils.dateOnly(minDate ?? DateTime.now());
            final lastDate = DateUtils.dateOnly(
              DateTime.now().add(const Duration(days: 365 * 2)),
            );
            final normalizedValue = DateUtils.dateOnly(value);
            final initialDate = normalizedValue.isBefore(firstDate)
                ? firstDate
                : normalizedValue.isAfter(lastDate)
                ? lastDate
                : normalizedValue;

            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
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
                    : KolabingColors.darkBorder,
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
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurface,
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
            style: KolabingTextStyles.bodySmall.copyWith(
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
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurface,
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
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: KolabingColors.onSurfaceVariant,
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
