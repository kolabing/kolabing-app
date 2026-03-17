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
import '../../auth/providers/auth_provider.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_form_provider.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../../../widgets/time_picker.dart';

// =============================================================================
// Local state for time slot management
// =============================================================================

/// A single availability time slot (date + start/end times).
class _TimeSlot {
  _TimeSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
}

/// Single-page scrollable form for creating or editing a collaboration request.
///
/// Sections:
///   1 - Basic Information (title, description)
///   2 - Availability (date + time slots, up to 3)
///   3 - Location (venue mode, preferred city, preferred area)
///   4 - Request Photo (profile photo toggle / upload area)
///   5 - What You're Offering (select or write your own)
///   6 - What You Expect From Community (select or write your own)
///   7 - Bottom sticky action bar (Save Draft / Publish)
class CreateCollabRequestScreen extends ConsumerStatefulWidget {
  const CreateCollabRequestScreen({super.key, this.editOpportunity});

  /// If provided, opens the form in edit mode pre-populated with this opportunity.
  final Opportunity? editOpportunity;

  @override
  ConsumerState<CreateCollabRequestScreen> createState() =>
      _CreateCollabRequestScreenState();
}

class _CreateCollabRequestScreenState
    extends ConsumerState<CreateCollabRequestScreen> {
  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preferredAreaController = TextEditingController();
  final _businessOfferOtherController = TextEditingController();
  final _deliverablesOtherController = TextEditingController();
  final _timelineDaysController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Local state
  // ---------------------------------------------------------------------------

  /// Availability time slots (up to 3).
  final List<_TimeSlot> _timeSlots = [];

  /// Whether user wants to use profile photo.
  bool _useProfilePhoto = true;

  /// Toggle mode for "What You're Offering": true = select from list, false = write own.
  bool _offeringSelectMode = true;

  /// Toggle mode for "What You Expect": true = select from list, false = write own.
  bool _expectSelectMode = true;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(opportunityFormProvider.notifier);
      final opp = widget.editOpportunity;

      if (opp != null) {
        // Edit mode: load existing opportunity into provider and controllers
        notifier.initForEdit(opp);

        _titleController.text = opp.title;
        _descriptionController.text = opp.description;
        _preferredAreaController.text = opp.address ?? '';

        // Photo: if opportunity has a custom photo, deselect "use profile photo"
        if (opp.offerPhoto != null) {
          setState(() => _useProfilePhoto = false);
        }

        // Availability: restore first time slot from saved dates
        final start = opp.availabilityStart;
        setState(() {
          _timeSlots.add(_TimeSlot(
            date: start,
            startTime: TimeOfDay(hour: start.hour, minute: start.minute),
            endTime: TimeOfDay(
              hour: opp.availabilityEnd.hour,
              minute: opp.availabilityEnd.minute,
            ),
          ));
        });

        // Offering mode: switch to "Write my own" if other text is set
        if (opp.businessOffer.other != null) {
          setState(() {
            _offeringSelectMode = false;
            _businessOfferOtherController.text = opp.businessOffer.other!;
          });
        }

        // Deliverables mode: switch to "Write my own" if other text is set
        if (opp.communityDeliverables.other != null) {
          setState(() {
            _expectSelectMode = false;
            _deliverablesOtherController.text = opp.communityDeliverables.other!;
          });
        }
      } else {
        // Create mode: reset to blank form with smart defaults
        notifier.reset();
        final user = ref.read(authProvider).user;
        // Default venue mode = "I Have a Venue" (businessVenue)
        notifier.updateVenueMode(VenueMode.businessVenue);
        // Prefill city from the user's business profile
        final city = user?.businessProfile?.city?.name ?? '';
        if (city.isNotEmpty) {
          notifier.updatePreferredCity(city);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _preferredAreaController.dispose();
    _businessOfferOtherController.dispose();
    _deliverablesOtherController.dispose();
    _timelineDaysController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submission handlers
  // ---------------------------------------------------------------------------

  void _showSubscriptionPaywall() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionPaywall(),
    );
    ref.read(opportunityFormProvider.notifier).clearError();
  }

  Future<void> _handleSaveDraft() async {
    _syncFormToProvider();
    final success = await ref.read(opportunityFormProvider.notifier).saveDraft();
    if (success && mounted) {
      _showSuccessDialog(isDraft: true);
    }
  }

  Future<void> _handlePublish() async {
    _syncFormToProvider();

    // Client-side validation before hitting API
    final errors = _validateForm();
    if (errors.isNotEmpty) {
      ref.read(opportunityFormProvider.notifier).clearError();
      // Set field errors and user-friendly message on state
      final notifier = ref.read(opportunityFormProvider.notifier);
      notifier.setValidationErrors(errors);
      return;
    }

    final success =
        await ref.read(opportunityFormProvider.notifier).saveAndPublish();
    if (success && mounted) {
      _showSuccessDialog(isDraft: false);
    }
  }

  /// Validates form fields and returns a map of field -> error message.
  Map<String, String> _validateForm() {
    final errors = <String, String>{};
    final opp = ref.read(opportunityFormProvider).opportunity;
    if (opp == null) return errors;

    if (opp.title.trim().isEmpty) {
      errors['title'] = 'Please enter a request title';
    }
    if (opp.description.trim().isEmpty) {
      errors['description'] = 'Please enter a description';
    }
    if (opp.categories.isEmpty) {
      errors['categories'] = 'Please select at least one category';
    }
    if (opp.preferredCity.isEmpty) {
      errors['preferred_city'] = 'Please select a city';
    }
    if (opp.availabilityEnd.isBefore(opp.availabilityStart)) {
      errors['availability_end'] = 'End date must be after start date';
    }
    if (!opp.businessOffer.hasAnyOffer) {
      errors['business_offer'] = 'Please select what you are offering';
    }
    if (!opp.communityDeliverables.hasAnyDeliverable) {
      errors['deliverables'] = 'Please select what you expect from the community';
    }
    return errors;
  }

  /// Push all local form values into the Riverpod provider before submission.
  void _syncFormToProvider() {
    final notifier = ref.read(opportunityFormProvider.notifier);

    notifier.updateTitle(_titleController.text);
    notifier.updateDescription(_descriptionController.text);

    // Sync time slots into availability start/end
    if (_timeSlots.isNotEmpty) {
      final first = _timeSlots.first;
      notifier.updateStartDate(first.date);
      // If multiple slots, use last slot date as end; otherwise end = start + 1 day
      // API requires availability_end to be after availability_start
      if (_timeSlots.length > 1) {
        final lastDate = _timeSlots.last.date;
        notifier.updateEndDate(
          lastDate.isAfter(first.date)
              ? lastDate
              : first.date.add(const Duration(days: 1)),
        );
      } else {
        notifier.updateEndDate(first.date.add(const Duration(days: 1)));
      }
    }

    notifier.updateAvailabilityMode(AvailabilityMode.oneTime);

    // Preferred area goes to address field
    if (_preferredAreaController.text.isNotEmpty) {
      notifier.updateAddress(_preferredAreaController.text);
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
              isDraft ? 'Draft Saved!' : 'Request Published!',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              isDraft
                  ? 'Your collaboration request has been saved as a draft. You can edit and publish it later.'
                  : 'Your collaboration request is now live. Communities can start applying!',
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
                'VIEW MY REQUESTS',
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
    ref.listen<OpportunityFormState>(
      opportunityFormProvider,
      (previous, next) {
        if (next.requiresSubscription &&
            !(previous?.requiresSubscription ?? false)) {
          _showSubscriptionPaywall();
        }
      },
    );

    final isBusy = formState.isSubmitting || formState.isPublishing;

    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            color: KolabingColors.textPrimary,
            onPressed: isBusy ? null : () => context.pop(),
          ),
          title: Text(
            widget.editOpportunity != null
                ? 'Edit Collab Request'
                : 'Create Collab Request',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (formState.error != null) _buildErrorBanner(formState.error!),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(formState),
                    const SizedBox(height: KolabingSpacing.md),
                    _buildCategoriesSection(formState),
                    const SizedBox(height: KolabingSpacing.md),
                    _buildAvailabilitySection(),
                    const SizedBox(height: KolabingSpacing.md),
                    _buildLocationSection(formState),
                    const SizedBox(height: KolabingSpacing.md),
                    _buildRequestPhotoSection(),
                    const SizedBox(height: KolabingSpacing.md),
                    _buildOfferingSection(formState),
                    const SizedBox(height: KolabingSpacing.md),
                    _buildExpectSection(formState),
                    // Bottom padding for action bar
                    const SizedBox(height: KolabingSpacing.lg),
                  ],
                ),
              ),
            ),
            _buildBottomActionBar(formState, isBusy),
          ],
        ),
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
  // Section 1 - Basic Information
  // ===========================================================================

  Widget _buildBasicInfoSection(OpportunityFormState formState) {
    return _buildSectionCard(
      children: [
        _buildSectionHeader('BASIC INFORMATION'),
        const SizedBox(height: KolabingSpacing.md),
        _buildTextField(
          label: 'Request Title',
          hint: 'e.g., Restaurant Week Promotion',
          controller: _titleController,
          error: formState.fieldErrors['title'],
          maxLength: 255,
          onChanged: (value) =>
              ref.read(opportunityFormProvider.notifier).updateTitle(value),
        ),
        const SizedBox(height: KolabingSpacing.md),
        _buildTextField(
          label: 'Description',
          hint:
              'Describe your collaboration request in detail. What are you looking for?',
          controller: _descriptionController,
          error: formState.fieldErrors['description'],
          maxLines: 5,
          maxLength: 5000,
          onChanged: (value) => ref
              .read(opportunityFormProvider.notifier)
              .updateDescription(value),
        ),
      ],
    );
  }

  // ===========================================================================
  // Section - Categories
  // ===========================================================================

  Widget _buildCategoriesSection(OpportunityFormState formState) {
    final opp = formState.opportunity;
    final selectedCategories = opp?.categories ?? [];

    return _buildSectionCard(
      children: [
        _buildSectionHeader('CATEGORIES'),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          'Select up to 5 categories that describe your request',
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: KolabingColors.textTertiary,
          ),
        ),
        if (formState.fieldErrors['categories'] != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
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
            final isSelected = selectedCategories.contains(category);
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? KolabingColors.textPrimary
                        : KolabingColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // Section 2 - Availability
  // ===========================================================================

  Widget _buildAvailabilitySection() {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return _buildSectionCard(
      children: [
        _buildSectionHeader('AVAILABILITY'),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Add up to 3 date & time slots for your collaboration',
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: KolabingColors.textTertiary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Existing time slots
        ...List.generate(_timeSlots.length, (index) {
          final slot = _timeSlots[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: KolabingColors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(color: KolabingColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Slot header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.sm,
                      vertical: KolabingSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: KolabingColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: KolabingRadius.borderRadiusMd.topLeft,
                        topRight: KolabingRadius.borderRadiusMd.topRight,
                      ),
                      border: Border(
                        bottom: BorderSide(color: KolabingColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: KolabingColors.primary,
                        ),
                        const SizedBox(width: KolabingSpacing.xs),
                        Text(
                          'Slot ${index + 1}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: KolabingColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _removeTimeSlot(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: KolabingColors.errorBg,
                              borderRadius: KolabingRadius.borderRadiusSm,
                            ),
                            child: const Icon(
                              LucideIcons.trash2,
                              size: 14,
                              color: KolabingColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date picker row
                  InkWell(
                    onTap: () => _pickDate(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KolabingSpacing.sm,
                        vertical: KolabingSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendarDays,
                            size: 18,
                            color: KolabingColors.textSecondary,
                          ),
                          const SizedBox(width: KolabingSpacing.sm),
                          Text(
                            dateFormat.format(slot.date),
                            style: GoogleFonts.openSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: KolabingColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: KolabingColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(height: 1, color: KolabingColors.border),

                  // Time fields
                  Padding(
                    padding: const EdgeInsets.all(KolabingSpacing.sm),
                    child: Row(
                      children: [
                        // Start time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'START TIME',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: KolabingColors.textTertiary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _pickStartTime(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: KolabingSpacing.sm,
                                    vertical: KolabingSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KolabingColors.surface,
                                    borderRadius:
                                        KolabingRadius.borderRadiusSm,
                                    border: Border.all(
                                      color: KolabingColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: 14,
                                        color: KolabingColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(slot.startTime),
                                        style: GoogleFonts.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: KolabingColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: KolabingSpacing.xs,
                            right: KolabingSpacing.xs,
                          ),
                          child: Icon(
                            LucideIcons.arrowRight,
                            size: 16,
                            color: KolabingColors.textTertiary,
                          ),
                        ),

                        // End time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'END TIME',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: KolabingColors.textTertiary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _pickEndTime(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: KolabingSpacing.sm,
                                    vertical: KolabingSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KolabingColors.surface,
                                    borderRadius:
                                        KolabingRadius.borderRadiusSm,
                                    border: Border.all(
                                      color: KolabingColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: 14,
                                        color: KolabingColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(slot.endTime),
                                        style: GoogleFonts.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: KolabingColors.textPrimary,
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
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Add date & time button (max 3 slots)
        if (_timeSlots.length < 3)
          GestureDetector(
            onTap: _addTimeSlot,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: KolabingSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: KolabingColors.primary),
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
                    'ADD DATE & TIME',
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
    );
  }


  void _addTimeSlot() {
    if (_timeSlots.length >= 3) return;
    setState(() {
      _timeSlots.add(
        _TimeSlot(
          date: DateTime.now().add(const Duration(days: 7)),
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
        ),
      );
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _pickDate(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timeSlots[index].date,
      firstDate: DateTime.now(),
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
      setState(() {
        _timeSlots[index].date = date;
      });
    }
  }

  Future<void> _pickStartTime(int index) async {
    final time = await KolabingTimePicker.show(
      context,
      initialTime: _timeSlots[index].startTime,
    );
    if (time != null) {
      setState(() => _timeSlots[index].startTime = time);
    }
  }

  Future<void> _pickEndTime(int index) async {
    final time = await KolabingTimePicker.show(
      context,
      initialTime: _timeSlots[index].endTime,
    );
    if (time != null) {
      setState(() => _timeSlots[index].endTime = time);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ===========================================================================
  // Section 3 - Location
  // ===========================================================================

  Widget _buildLocationSection(OpportunityFormState formState) {
    final opp = formState.opportunity;
    final citiesAsync = ref.watch(citiesProvider);

    return _buildSectionCard(
      children: [
        _buildSectionHeader('LOCATION'),
        const SizedBox(height: KolabingSpacing.md),

        // Venue Mode
        _buildLabel('Venue Mode'),
        const SizedBox(height: KolabingSpacing.xs),
        Row(
          children: VenueMode.values.map((mode) {
            final isSelected = opp?.venueMode == mode;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      mode != VenueMode.values.last ? KolabingSpacing.xs : 0,
                ),
                child: _buildSelectionCard(
                  icon: _venueModeIcon(mode),
                  title: _venueModeLabel(mode),
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(opportunityFormProvider.notifier)
                      .updateVenueMode(mode),
                ),
              ),
            );
          }).toList(),
        ),
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
            value: (opp?.preferredCity.isNotEmpty ?? false)
                ? opp!.preferredCity
                : null,
            decoration: _inputDecoration(hint: 'Select city'),
            items: cities
                .map((city) => DropdownMenuItem(
                      value: city.name,
                      child: Text(city.name),
                    ))
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
        const SizedBox(height: KolabingSpacing.md),

        // Preferred Area
        _buildTextField(
          label: 'Preferred Area',
          hint: 'e.g., City Center, Westside',
          controller: _preferredAreaController,
          onChanged: (_) {},
        ),
      ],
    );
  }

  String _venueModeLabel(VenueMode mode) {
    switch (mode) {
      case VenueMode.noVenue:
        return 'No Venue';
      case VenueMode.businessVenue:
        return 'I Have a Venue';
      case VenueMode.communityVenue:
        return 'Partner Provides';
    }
  }

  IconData _venueModeIcon(VenueMode mode) {
    switch (mode) {
      case VenueMode.noVenue:
        return LucideIcons.globe;
      case VenueMode.businessVenue:
        return LucideIcons.store;
      case VenueMode.communityVenue:
        return LucideIcons.home;
    }
  }

  // ===========================================================================
  // Section 4 - Request Photo
  // ===========================================================================

  Widget _buildRequestPhotoSection() {
    return _buildSectionCard(
      children: [
        _buildSectionHeader('REQUEST PHOTO'),
        const SizedBox(height: KolabingSpacing.md),

        // Radio: Use profile photo
        GestureDetector(
          onTap: () => setState(() => _useProfilePhoto = true),
          child: Container(
            padding: const EdgeInsets.all(KolabingSpacing.sm),
            decoration: BoxDecoration(
              color: _useProfilePhoto
                  ? KolabingColors.softYellow
                  : KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color: _useProfilePhoto
                    ? KolabingColors.primary
                    : KolabingColors.border,
                width: _useProfilePhoto ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _useProfilePhoto
                      ? LucideIcons.checkCircle
                      : LucideIcons.circle,
                  size: 20,
                  color: _useProfilePhoto
                      ? KolabingColors.primary
                      : KolabingColors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Text(
                    'Use your business profile photo',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Upload area
        GestureDetector(
          onTap: () {
            setState(() => _useProfilePhoto = false);
            // Image picker integration can be added later
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: KolabingSpacing.xl,
              horizontal: KolabingSpacing.md,
            ),
            decoration: BoxDecoration(
              color: _useProfilePhoto
                  ? KolabingColors.surfaceVariant
                  : KolabingColors.softYellow,
              borderRadius: KolabingRadius.borderRadiusMd,
              border: Border.all(
                color: _useProfilePhoto
                    ? KolabingColors.border
                    : KolabingColors.primary,
                width: _useProfilePhoto ? 1 : 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.camera,
                  size: 32,
                  color: _useProfilePhoto
                      ? KolabingColors.textTertiary
                      : KolabingColors.primary,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  'Upload Photo',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _useProfilePhoto
                        ? KolabingColors.textSecondary
                        : KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xxs),
                Text(
                  'Max 5MB',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Section 5 - What You're Offering
  // ===========================================================================

  Widget _buildOfferingSection(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();
    final offer = opp.businessOffer;

    return _buildSectionCard(
      children: [
        _buildSectionHeader("WHAT YOU'RE OFFERING"),
        const SizedBox(height: KolabingSpacing.md),

        // Toggle: Select from list / Write my own
        _buildToggleButtons(
          leftLabel: 'Select from list',
          rightLabel: 'Write my own',
          isLeftSelected: _offeringSelectMode,
          onLeftTap: () => setState(() => _offeringSelectMode = true),
          onRightTap: () => setState(() => _offeringSelectMode = false),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (_offeringSelectMode) ...[
          // Chip selection
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xs,
            children: [
              _buildSelectableChip(
                label: 'Venue',
                isSelected: offer.venue,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateBusinessOffer(venue: !offer.venue),
              ),
              _buildSelectableChip(
                label: 'Food & Drink',
                isSelected: offer.foodDrink,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateBusinessOffer(foodDrink: !offer.foodDrink),
              ),
              _buildSelectableChip(
                label: 'Social Media Exposure',
                isSelected: offer.socialMediaExposure,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateBusinessOffer(
                        socialMediaExposure: !offer.socialMediaExposure),
              ),
              _buildSelectableChip(
                label: 'Content Creation',
                isSelected: offer.contentCreation,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateBusinessOffer(
                        contentCreation: !offer.contentCreation),
              ),
              _buildSelectableChip(
                label: 'Discount',
                isSelected: offer.discount.enabled,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateBusinessOffer(
                      discount: offer.discount.copyWith(
                        enabled: !offer.discount.enabled,
                      ),
                    ),
              ),
              _buildSelectableChip(
                label: 'Products',
                isSelected: offer.products.isNotEmpty,
                onTap: () {
                  if (offer.products.isEmpty) {
                    ref
                        .read(opportunityFormProvider.notifier)
                        .addProduct('Products');
                  } else {
                    ref
                        .read(opportunityFormProvider.notifier)
                        .updateBusinessOffer(products: []);
                  }
                },
              ),
              _buildSelectableChip(
                label: 'Other',
                isSelected: offer.other != null,
                onTap: () {
                  if (offer.other == null) {
                    ref
                        .read(opportunityFormProvider.notifier)
                        .updateBusinessOffer(other: 'Other');
                  } else {
                    ref
                        .read(opportunityFormProvider.notifier)
                        .updateBusinessOffer(clearOther: true);
                  }
                },
              ),
            ],
          ),
        ] else ...[
          // Textarea
          _buildTextField(
            label: 'Describe what you are offering',
            hint: 'e.g., We provide a fully equipped venue with catering...',
            controller: _businessOfferOtherController,
            maxLines: 4,
            onChanged: (value) => ref
                .read(opportunityFormProvider.notifier)
                .updateBusinessOffer(other: value),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Section 6 - What You Expect From Community
  // ===========================================================================

  Widget _buildExpectSection(OpportunityFormState formState) {
    final opp = formState.opportunity;
    if (opp == null) return const SizedBox.shrink();
    final deliverables = opp.communityDeliverables;

    return _buildSectionCard(
      children: [
        _buildSectionHeader('WHAT DO YOU EXPECT FROM THE COMMUNITY?'),
        const SizedBox(height: KolabingSpacing.md),

        // Toggle: Select from list / Write my own
        _buildToggleButtons(
          leftLabel: 'Select from list',
          rightLabel: 'Write my own',
          isLeftSelected: _expectSelectMode,
          onLeftTap: () => setState(() => _expectSelectMode = true),
          onRightTap: () => setState(() => _expectSelectMode = false),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (_expectSelectMode) ...[
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xs,
            children: [
              _buildSelectableChip(
                label: 'Social Media Content',
                isSelected: deliverables.socialMediaContent,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateDeliverables(
                        socialMediaContent: !deliverables.socialMediaContent),
              ),
              _buildSelectableChip(
                label: 'Event Activation',
                isSelected: deliverables.eventActivation,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateDeliverables(
                        eventActivation: !deliverables.eventActivation),
              ),
              _buildSelectableChip(
                label: 'Product Placement',
                isSelected: deliverables.productPlacement,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateDeliverables(
                        productPlacement: !deliverables.productPlacement),
              ),
              _buildSelectableChip(
                label: 'Community Reach',
                isSelected: deliverables.communityReach,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateDeliverables(
                        communityReach: !deliverables.communityReach),
              ),
              _buildSelectableChip(
                label: 'Review & Feedback',
                isSelected: deliverables.reviewFeedback,
                onTap: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateDeliverables(
                        reviewFeedback: !deliverables.reviewFeedback),
              ),
              _buildSelectableChip(
                label: 'Other',
                isSelected: deliverables.other != null,
                onTap: () {
                  if (deliverables.other == null) {
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
            ],
          ),
        ] else ...[
          _buildTextField(
            label: 'Describe what you expect',
            hint: 'e.g., We expect 2 Instagram posts and a TikTok video...',
            controller: _deliverablesOtherController,
            maxLines: 4,
            onChanged: (value) => ref
                .read(opportunityFormProvider.notifier)
                .updateDeliverables(other: value),
          ),
        ],

        const SizedBox(height: KolabingSpacing.md),

        // Timeline field
        _buildTextField(
          label: 'Timeline',
          hint: 'e.g., 7',
          controller: _timelineDaysController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {},
          suffixText: 'days after collaboration',
        ),
      ],
    );
  }

  // ===========================================================================
  // Section 7 - Bottom Action Bar (Sticky)
  // ===========================================================================

  Widget _buildBottomActionBar(OpportunityFormState formState, bool isBusy) {
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
        child: Row(
          children: [
            // Save as Draft
            Expanded(
              flex: 2,
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
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SAVE AS DRAFT',
                          maxLines: 1,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            // Publish Request
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: isBusy ? null : _handlePublish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  disabledBackgroundColor:
                      KolabingColors.primary.withValues(alpha: 0.7),
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
                        'PUBLISH REQUEST',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Shared UI Components
  // ===========================================================================

  /// Card wrapper for each form section.
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.rubik(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: KolabingColors.textPrimary,
        letterSpacing: 1,
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
            hintStyle: GoogleFonts.openSans(
              color: KolabingColors.textTertiary,
            ),
            filled: true,
            fillColor: KolabingColors.surface,
            counterText: '',
            suffixText: suffixText,
            suffixStyle: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
              fontWeight: FontWeight.w500,
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
              borderSide:
                  const BorderSide(color: KolabingColors.primary, width: 2),
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
      hintStyle: GoogleFonts.openSans(
        color: KolabingColors.textTertiary,
      ),
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
        borderSide:
            const BorderSide(color: KolabingColors.primary, width: 2),
      ),
    );
  }

  Widget _buildPickerField({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusSm,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: KolabingColors.textTertiary,
          ),
          const SizedBox(width: KolabingSpacing.xxs),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.xs,
          vertical: KolabingSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? KolabingColors.softYellow
              : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color:
                isSelected ? KolabingColors.primary : KolabingColors.border,
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
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

  Widget _buildToggleButtons({
    required String leftLabel,
    required String rightLabel,
    required bool isLeftSelected,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KolabingColors.surfaceVariant,
        borderRadius: KolabingRadius.borderRadiusMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLeftTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isLeftSelected
                      ? KolabingColors.primary
                      : Colors.transparent,
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
                child: Center(
                  child: Text(
                    leftLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isLeftSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onRightTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: !isLeftSelected
                      ? KolabingColors.primary
                      : Colors.transparent,
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
                child: Center(
                  child: Text(
                    rightLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !isLeftSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          borderRadius: KolabingRadius.borderRadiusRound,
          border: Border.all(
            color:
                isSelected ? KolabingColors.primary : KolabingColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                LucideIcons.check,
                size: 14,
                color: KolabingColors.primary,
              ),
              const SizedBox(width: KolabingSpacing.xxs),
            ],
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? KolabingColors.textPrimary
                    : KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
