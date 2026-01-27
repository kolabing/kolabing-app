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
import '../models/opportunity.dart';
import '../providers/opportunity_provider.dart';

/// Multi-step form for creating a collaboration opportunity
class CreateOpportunityScreen extends ConsumerStatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  ConsumerState<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState
    extends ConsumerState<CreateOpportunityScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _attendeesController = TextEditingController();
  final _rewardController = TextEditingController();
  final _budgetController = TextEditingController();
  final _requirementsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset form on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(opportunityFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attendeesController.dispose();
    _rewardController.dispose();
    _budgetController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

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

  Future<void> _handleSubmit() async {
    final success = await ref.read(opportunityFormProvider.notifier).submit();
    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
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
              'Opportunity Created!',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              'Your collaboration request is now live. Businesses can start applying!',
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
                'VIEW MY OPPORTUNITIES',
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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(opportunityFormProvider);

    return PopScope(
      canPop: !formState.isSubmitting,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            color: KolabingColors.textPrimary,
            onPressed: formState.isSubmitting ? null : _handleBack,
          ),
          title: Text(
            'Create Opportunity',
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
            // Progress indicator
            _buildProgressIndicator(formState),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                child: _buildCurrentStep(formState),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(formState),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(OpportunityFormState formState) {
    final steps = ['Basic', 'Details', 'Offer', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        border: Border(
          bottom: BorderSide(color: KolabingColors.border),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == formState.currentStep;
          final isCompleted = index < formState.currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: isCompleted
                  ? () =>
                      ref.read(opportunityFormProvider.notifier).goToStep(index)
                  : null,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted || isActive
                                ? KolabingColors.primary
                                : KolabingColors.border,
                          ),
                        ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isActive
                              ? KolabingColors.primary
                              : isCompleted
                                  ? KolabingColors.success
                                  : KolabingColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? KolabingColors.onPrimary
                                        : KolabingColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted
                                ? KolabingColors.primary
                                : KolabingColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    steps[index],
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? KolabingColors.textPrimary
                          : KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(OpportunityFormState formState) {
    switch (formState.currentStep) {
      case 0:
        return _buildStep1BasicInfo(formState);
      case 1:
        return _buildStep2Details(formState);
      case 2:
        return _buildStep3Offer(formState);
      case 3:
        return _buildStep4Review(formState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo(OpportunityFormState formState) {
    final opportunity = formState.opportunity;
    if (opportunity == null) return const SizedBox.shrink();

    // Sync controller with state
    if (_titleController.text != opportunity.title) {
      _titleController.text = opportunity.title;
    }
    if (_descriptionController.text != opportunity.description) {
      _descriptionController.text = opportunity.description;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BASIC INFORMATION',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Tell us about your collaboration opportunity',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Title
        _buildTextField(
          label: 'Title',
          hint: 'e.g., Restaurant Week Promotion',
          controller: _titleController,
          error: formState.fieldErrors['title'],
          maxLength: 255,
          onChanged: (value) => ref
              .read(opportunityFormProvider.notifier)
              .updateField(title: value),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Type
        _buildTypeSelector(opportunity.type),
        const SizedBox(height: KolabingSpacing.md),

        // Description
        _buildTextField(
          label: 'Description',
          hint:
              'Describe your collaboration opportunity in detail. What are you looking for? What can you offer?',
          controller: _descriptionController,
          error: formState.fieldErrors['description'],
          maxLines: 5,
          maxLength: 2000,
          onChanged: (value) => ref
              .read(opportunityFormProvider.notifier)
              .updateField(description: value),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(OpportunityType selectedType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        ...OpportunityType.values.map((type) {
          final isSelected = type == selectedType;
          return GestureDetector(
            onTap: () => ref
                .read(opportunityFormProvider.notifier)
                .updateField(type: type),
            child: Container(
              margin: const EdgeInsets.only(bottom: KolabingSpacing.xs),
              padding: const EdgeInsets.all(KolabingSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? KolabingColors.primary.withValues(alpha: 0.1)
                    : KolabingColors.surface,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: isSelected
                      ? KolabingColors.primary
                      : KolabingColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? KolabingColors.primary
                          : KolabingColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? KolabingColors.primary
                            : KolabingColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: KolabingColors.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                          ),
                        ),
                        Text(
                          type.description,
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: KolabingColors.textSecondary,
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
      ],
    );
  }

  Widget _buildStep2Details(OpportunityFormState formState) {
    final opportunity = formState.opportunity;
    if (opportunity == null) return const SizedBox.shrink();

    // Sync controller
    if (opportunity.expectedAttendees != null &&
        _attendeesController.text != opportunity.expectedAttendees.toString()) {
      _attendeesController.text = opportunity.expectedAttendees.toString();
    }

    final citiesAsync = ref.watch(citiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENT DETAILS',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'When and where will this take place?',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // City dropdown
        _buildLabel('City'),
        const SizedBox(height: KolabingSpacing.xxs),
        citiesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error loading cities: $e'),
          data: (cities) => DropdownButtonFormField<String>(
            // Use initialValue via value since DropdownButtonFormField expects it
            value: opportunity.cityId.isNotEmpty ? opportunity.cityId : null,
            decoration: InputDecoration(
              hintText: 'Select city',
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
              errorText: formState.fieldErrors['city'],
            ),
            items: cities
                .map((city) => DropdownMenuItem(
                      value: city.id,
                      child: Text(city.name),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                final city = cities.firstWhere((c) => c.id == value);
                ref
                    .read(opportunityFormProvider.notifier)
                    .updateField(cityId: value, cityName: city.name);
              }
            },
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Date pickers
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Start Date',
                value: opportunity.startDate,
                error: formState.fieldErrors['startDate'],
                onChanged: (date) => ref
                    .read(opportunityFormProvider.notifier)
                    .updateField(startDate: date),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: _buildDatePicker(
                label: 'End Date (Optional)',
                value: opportunity.endDate,
                error: formState.fieldErrors['endDate'],
                isOptional: true,
                minDate: opportunity.startDate,
                onChanged: (date) => ref
                    .read(opportunityFormProvider.notifier)
                    .updateField(endDate: date),
                onClear: () => ref
                    .read(opportunityFormProvider.notifier)
                    .updateField(clearEndDate: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Expected attendees
        _buildTextField(
          label: 'Expected Attendees (Optional)',
          hint: 'e.g., 500',
          controller: _attendeesController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final attendees = int.tryParse(value);
            ref
                .read(opportunityFormProvider.notifier)
                .updateField(expectedAttendees: attendees);
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    String? error,
    bool isOptional = false,
    DateTime? minDate,
    required ValueChanged<DateTime> onChanged,
    VoidCallback? onClear,
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
              initialDate: value ?? minDate ?? DateTime.now(),
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
                    value != null ? dateFormat.format(value) : 'Select date',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: value != null
                          ? KolabingColors.textPrimary
                          : KolabingColors.textTertiary,
                    ),
                  ),
                ),
                if (isOptional && value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: KolabingColors.textTertiary,
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

  Widget _buildStep3Offer(OpportunityFormState formState) {
    final opportunity = formState.opportunity;
    if (opportunity == null) return const SizedBox.shrink();

    // Sync controllers
    if (_rewardController.text != (opportunity.rewardDescription ?? '')) {
      _rewardController.text = opportunity.rewardDescription ?? '';
    }
    if (_budgetController.text != (opportunity.budget ?? '')) {
      _budgetController.text = opportunity.budget ?? '';
    }
    if (_requirementsController.text != (opportunity.requirements ?? '')) {
      _requirementsController.text = opportunity.requirements ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU OFFER',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'What benefits do businesses get for collaborating?',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Reward toggle
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: KolabingColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.1),
                  borderRadius: KolabingRadius.borderRadiusSm,
                ),
                child: const Icon(
                  LucideIcons.gift,
                  size: 20,
                  color: KolabingColors.primary,
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer a Reward',
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Highlight what businesses will receive',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: KolabingColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: opportunity.hasReward,
                onChanged: (value) {
                  ref
                      .read(opportunityFormProvider.notifier)
                      .updateField(hasReward: value, clearReward: !value);
                },
                activeTrackColor: KolabingColors.primary.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(
                  opportunity.hasReward
                      ? KolabingColors.primary
                      : KolabingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Reward description (conditional)
        if (opportunity.hasReward) ...[
          const SizedBox(height: KolabingSpacing.md),
          _buildTextField(
            label: 'Reward Description',
            hint: 'e.g., Featured spotlight on social channels (200K reach)',
            controller: _rewardController,
            error: formState.fieldErrors['reward'],
            maxLines: 3,
            maxLength: 500,
            onChanged: (value) => ref
                .read(opportunityFormProvider.notifier)
                .updateField(rewardDescription: value),
          ),
        ],
        const SizedBox(height: KolabingSpacing.md),

        // Budget
        _buildTextField(
          label: 'Budget (Optional)',
          hint: 'e.g., 500-1000 EUR or Free',
          controller: _budgetController,
          onChanged: (value) => ref
              .read(opportunityFormProvider.notifier)
              .updateField(budget: value),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // Requirements
        _buildTextField(
          label: 'Requirements (Optional)',
          hint:
              'e.g., Must have active Instagram account with 1K+ followers',
          controller: _requirementsController,
          maxLines: 3,
          maxLength: 1000,
          onChanged: (value) => ref
              .read(opportunityFormProvider.notifier)
              .updateField(requirements: value),
        ),
      ],
    );
  }

  Widget _buildStep4Review(OpportunityFormState formState) {
    final opportunity = formState.opportunity;
    if (opportunity == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REVIEW YOUR OPPORTUNITY',
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Make sure everything looks correct before publishing',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
          ),
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
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                  vertical: KolabingSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.15),
                  borderRadius: KolabingRadius.borderRadiusRound,
                ),
                child: Text(
                  opportunity.type.displayName.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Title
              Text(
                opportunity.title.isEmpty
                    ? 'Untitled Opportunity'
                    : opportunity.title,
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                opportunity.description.isEmpty
                    ? 'No description provided'
                    : opportunity.description,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Info chips
              Wrap(
                spacing: KolabingSpacing.xs,
                runSpacing: KolabingSpacing.xs,
                children: [
                  _buildInfoChip(
                    LucideIcons.mapPin,
                    opportunity.cityName ?? 'No city selected',
                  ),
                  _buildInfoChip(
                    LucideIcons.calendar,
                    opportunity.endDate != null
                        ? '${dateFormat.format(opportunity.startDate)} - ${dateFormat.format(opportunity.endDate!)}'
                        : 'Starting ${dateFormat.format(opportunity.startDate)}',
                  ),
                  if (opportunity.expectedAttendees != null)
                    _buildInfoChip(
                      LucideIcons.users,
                      '${opportunity.expectedAttendees} expected',
                    ),
                ],
              ),

              // Reward
              if (opportunity.hasReward &&
                  opportunity.rewardDescription?.isNotEmpty == true) ...[
                const SizedBox(height: KolabingSpacing.md),
                Container(
                  padding: const EdgeInsets.all(KolabingSpacing.sm),
                  decoration: BoxDecoration(
                    color: KolabingColors.success.withValues(alpha: 0.1),
                    borderRadius: KolabingRadius.borderRadiusSm,
                    border: Border.all(
                      color: KolabingColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.gift,
                        size: 16,
                        color: KolabingColors.activeText,
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Expanded(
                        child: Text(
                          opportunity.rewardDescription!,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: KolabingColors.activeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Requirements
              if (opportunity.requirements?.isNotEmpty == true) ...[
                const SizedBox(height: KolabingSpacing.md),
                _buildReviewSection('Requirements', opportunity.requirements!),
              ],

              // Budget
              if (opportunity.budget?.isNotEmpty == true) ...[
                const SizedBox(height: KolabingSpacing.sm),
                _buildReviewSection('Budget', opportunity.budget!),
              ],
            ],
          ),
        ),

        // Error message
        if (formState.error != null) ...[
          const SizedBox(height: KolabingSpacing.md),
          Container(
            padding: const EdgeInsets.all(KolabingSpacing.sm),
            decoration: BoxDecoration(
              color: KolabingColors.errorBg,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
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
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.xs,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.surfaceVariant,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: KolabingColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildReviewSection(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textPrimary,
            ),
          ),
        ],
      );

  Widget _buildBottomButtons(OpportunityFormState formState) {
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
            if (formState.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: formState.isSubmitting ? null : _handleBack,
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
            if (formState.currentStep > 0)
              const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              flex: formState.currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: formState.isSubmitting
                    ? null
                    : formState.isReviewStep
                        ? _handleSubmit
                        : _handleNext,
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
                child: formState.isSubmitting
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
                        formState.isReviewStep ? 'PUBLISH' : 'CONTINUE',
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

  Widget _buildLabel(String label) => Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KolabingColors.textPrimary,
        ),
      );
}
