import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../models/opportunity.dart';
import '../services/opportunity_service.dart';
import 'opportunity_provider.dart';

// =============================================================================
// Form State
// =============================================================================

/// Form state for creating/editing opportunities
@immutable
class OpportunityFormState {
  const OpportunityFormState({
    this.currentStep = 0,
    this.opportunity,
    this.isEditing = false,
    this.isSubmitting = false,
    this.isPublishing = false,
    this.isSuccess = false,
    this.requiresSubscription = false,
    this.error,
    this.fieldErrors = const {},
  });

  final int currentStep;
  final Opportunity? opportunity;
  final bool isEditing;
  final bool isSubmitting;
  final bool isPublishing;
  final bool isSuccess;
  final bool requiresSubscription;
  final String? error;
  final Map<String, String> fieldErrors;

  /// Steps: Basic Info, Business Offer, Community Deliverables, Location, Review
  int get totalSteps => 5;

  static const List<String> stepTitles = [
    'Basic Info',
    'Business Offer',
    'Deliverables',
    'Location',
    'Review',
  ];

  bool get canGoBack => currentStep > 0;
  bool get canGoNext => currentStep < totalSteps - 1;
  bool get isReviewStep => currentStep == totalSteps - 1;

  OpportunityFormState copyWith({
    int? currentStep,
    Opportunity? opportunity,
    bool? isEditing,
    bool? isSubmitting,
    bool? isPublishing,
    bool? isSuccess,
    bool? requiresSubscription,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) =>
      OpportunityFormState(
        currentStep: currentStep ?? this.currentStep,
        opportunity: opportunity ?? this.opportunity,
        isEditing: isEditing ?? this.isEditing,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isPublishing: isPublishing ?? this.isPublishing,
        isSuccess: isSuccess ?? this.isSuccess,
        requiresSubscription:
            requiresSubscription ?? this.requiresSubscription,
        error: clearError ? null : (error ?? this.error),
        fieldErrors: fieldErrors ?? this.fieldErrors,
      );
}

// =============================================================================
// Form Notifier
// =============================================================================

class OpportunityFormNotifier extends Notifier<OpportunityFormState> {
  late final OpportunityService _service;

  @override
  OpportunityFormState build() {
    _service = ref.read(opportunityServiceProvider);
    return OpportunityFormState(
      opportunity: Opportunity.empty(),
    );
  }

  /// Initialize for editing an existing opportunity
  void initForEdit(Opportunity opportunity) {
    state = OpportunityFormState(
      opportunity: opportunity,
      isEditing: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void nextStep() {
    if (state.canGoNext) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.canGoBack) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Basic Info (Step 0)
  // ---------------------------------------------------------------------------

  void updateTitle(String title) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(title: title),
      clearError: true,
    );
  }

  void updateDescription(String description) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(description: description),
      clearError: true,
    );
  }

  void toggleCategory(String category) {
    final opp = state.opportunity;
    if (opp == null) return;
    final categories = List<String>.from(opp.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else if (categories.length < 5) {
      categories.add(category);
    }
    state = state.copyWith(
      opportunity: opp.copyWith(categories: categories),
      clearError: true,
    );
  }

  void updateOfferPhoto(String? url) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(
        offerPhoto: url,
        clearOfferPhoto: url == null,
      ),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Business Offer (Step 1)
  // ---------------------------------------------------------------------------

  void updateBusinessOffer({
    bool? venue,
    bool? foodDrink,
    bool? socialMediaExposure,
    bool? contentCreation,
    DiscountOffer? discount,
    List<String>? products,
    String? other,
    bool clearOther = false,
  }) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(
        businessOffer: opp.businessOffer.copyWith(
          venue: venue,
          foodDrink: foodDrink,
          socialMediaExposure: socialMediaExposure,
          contentCreation: contentCreation,
          discount: discount,
          products: products,
          other: other,
          clearOther: clearOther,
        ),
      ),
      clearError: true,
    );
  }

  void addProduct(String product) {
    final opp = state.opportunity;
    if (opp == null) return;
    final products = [...opp.businessOffer.products, product];
    updateBusinessOffer(products: products);
  }

  void removeProduct(int index) {
    final opp = state.opportunity;
    if (opp == null) return;
    final products = List<String>.from(opp.businessOffer.products)
      ..removeAt(index);
    updateBusinessOffer(products: products);
  }

  void updateProduct(int index, String value) {
    final opp = state.opportunity;
    if (opp == null) return;
    final products = List<String>.from(opp.businessOffer.products);
    if (index < products.length) {
      products[index] = value;
      updateBusinessOffer(products: products);
    }
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Community Deliverables (Step 2)
  // ---------------------------------------------------------------------------

  void updateDeliverables({
    bool? socialMediaContent,
    bool? eventActivation,
    bool? productPlacement,
    bool? communityReach,
    bool? reviewFeedback,
    String? other,
    bool clearOther = false,
  }) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(
        communityDeliverables: opp.communityDeliverables.copyWith(
          socialMediaContent: socialMediaContent,
          eventActivation: eventActivation,
          productPlacement: productPlacement,
          communityReach: communityReach,
          reviewFeedback: reviewFeedback,
          other: other,
          clearOther: clearOther,
        ),
      ),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Location & Availability (Step 3)
  // ---------------------------------------------------------------------------

  void updateAvailabilityMode(AvailabilityMode mode) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(
        availabilityMode: mode,
        // Clear mode-specific fields when switching
        clearRecurringDays: mode != AvailabilityMode.recurring,
        clearSelectedTime: mode == AvailabilityMode.flexible,
      ),
      clearError: true,
    );
  }

  void updateStartDate(DateTime date) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(availabilityStart: date),
      clearError: true,
    );
  }

  void updateEndDate(DateTime date) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(availabilityEnd: date),
      clearError: true,
    );
  }

  void updateSelectedTime(TimeOfDay? time) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(
        selectedTime: time,
        clearSelectedTime: time == null,
      ),
      clearError: true,
    );
  }

  void toggleRecurringDay(int day) {
    final opp = state.opportunity;
    if (opp == null) return;
    final days = List<int>.from(opp.recurringDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
      days.sort();
    }
    state = state.copyWith(
      opportunity: opp.copyWith(recurringDays: days),
      clearError: true,
    );
  }

  void updateVenueMode(VenueMode mode) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(
        venueMode: mode,
        clearAddress: !mode.requiresAddress,
      ),
      clearError: true,
    );
  }

  void updateAddress(String address) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(address: address),
      clearError: true,
    );
  }

  void updatePreferredCity(String city) {
    final opp = state.opportunity;
    if (opp == null) return;
    state = state.copyWith(
      opportunity: opp.copyWith(preferredCity: city),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool validateCurrentStep() {
    final opp = state.opportunity;
    if (opp == null) return false;

    final errors = <String, String>{};

    switch (state.currentStep) {
      case 0: // Basic Info
        if (opp.title.isEmpty) {
          errors['title'] = 'Title is required';
        } else if (opp.title.length > 255) {
          errors['title'] = 'Title must be less than 255 characters';
        }
        if (opp.description.isEmpty) {
          errors['description'] = 'Description is required';
        } else if (opp.description.length > 5000) {
          errors['description'] =
              'Description must be less than 5000 characters';
        }
        if (opp.categories.isEmpty) {
          errors['categories'] = 'Select at least 1 category';
        } else if (opp.categories.length > 5) {
          errors['categories'] = 'Maximum 5 categories allowed';
        }

      case 1: // Business Offer
        if (!opp.businessOffer.hasAnyOffer) {
          errors['business_offer'] = 'Configure at least one offer';
        }

      case 2: // Community Deliverables
        if (!opp.communityDeliverables.hasAnyDeliverable) {
          errors['deliverables'] = 'Configure at least one deliverable';
        }

      case 3: // Location & Availability
        if (opp.availabilityMode == AvailabilityMode.recurring) {
          if (opp.recurringDays.isEmpty) {
            errors['recurring_day'] = 'Select at least one day';
          }
          if (opp.selectedTime == null) {
            errors['selected_time'] = 'Select a time';
          }
        } else {
          // oneTime and flexible both need date range
          if (opp.availabilityStart.isBefore(DateTime.now())) {
            errors['availability_start'] = 'Start date must be in the future';
          }
          if (opp.availabilityEnd.isBefore(opp.availabilityStart)) {
            errors['availability_end'] = 'End date must be after start date';
          }
          if (opp.availabilityMode == AvailabilityMode.oneTime &&
              opp.selectedTime == null) {
            errors['selected_time'] = 'Select a time';
          }
        }
        if (opp.venueMode.requiresAddress &&
            (opp.address?.isEmpty ?? true)) {
          errors['address'] = 'Address is required for this venue mode';
        }
        if (opp.preferredCity.isEmpty) {
          errors['preferred_city'] = 'Preferred city is required';
        }
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(fieldErrors: {});
    return true;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  /// Save as draft
  Future<bool> saveDraft() async {
    final opp = state.opportunity;
    if (opp == null) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      requiresSubscription: false,
    );

    try {
      Opportunity result;
      if (state.isEditing && opp.id != null) {
        result = await _service.updateOpportunity(opp.id!, opp);
      } else {
        result = await _service.createOpportunity(opp);
      }
      state = state.copyWith(
        opportunity: result,
        isSubmitting: false,
        isSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      if (e.error.requiresSubscription) {
        state = state.copyWith(
          isSubmitting: false,
          requiresSubscription: true,
          error: e.error.message,
        );
        return false;
      }
      final fieldErrors = <String, String>{};
      if (e.error.errors != null) {
        for (final entry in e.error.errors!.entries) {
          if (entry.value.isNotEmpty) {
            fieldErrors[entry.key] = entry.value.first;
          }
        }
      }
      // Show field-level errors to the user instead of generic "Validation failed"
      final userMessage = fieldErrors.isNotEmpty
          ? fieldErrors.values.join('\n')
          : e.error.message;
      state = state.copyWith(
        isSubmitting: false,
        error: userMessage,
        fieldErrors: fieldErrors,
      );
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Save draft error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  /// Save and publish
  Future<bool> saveAndPublish() async {
    final opp = state.opportunity;
    if (opp == null) return false;

    state = state.copyWith(
      isPublishing: true,
      clearError: true,
      requiresSubscription: false,
    );

    try {
      // Set status to published before saving
      final oppToSave = opp.copyWith(status: OpportunityStatus.published);

      Opportunity saved;
      if (state.isEditing && opp.id != null) {
        saved = await _service.updateOpportunity(opp.id!, oppToSave);
      } else {
        saved = await _service.createOpportunity(oppToSave);
      }

      // If the status came back as draft (backend didn't accept inline publish),
      // try the dedicated publish endpoint as fallback
      if (saved.status == OpportunityStatus.draft && saved.id != null) {
        try {
          final published = await _service.publishOpportunity(saved.id!);
          state = state.copyWith(
            opportunity: published,
            isPublishing: false,
            isSuccess: true,
          );
          return true;
        } on ApiException catch (publishError) {
          debugPrint('Publish endpoint failed: ${publishError.error.message}');
          // If publish endpoint also fails, report the error
          state = state.copyWith(
            isPublishing: false,
            error: publishError.error.message,
          );
          return false;
        }
      }

      state = state.copyWith(
        opportunity: saved,
        isPublishing: false,
        isSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      if (e.error.requiresSubscription) {
        state = state.copyWith(
          isPublishing: false,
          requiresSubscription: true,
          error: e.error.message,
        );
        return false;
      }
      final fieldErrors = <String, String>{};
      if (e.error.errors != null) {
        for (final entry in e.error.errors!.entries) {
          if (entry.value.isNotEmpty) {
            fieldErrors[entry.key] = entry.value.first;
          }
        }
      }
      // Show field-level errors to the user instead of generic "Validation failed"
      final userMessage = fieldErrors.isNotEmpty
          ? fieldErrors.values.join('\n')
          : e.error.message;
      state = state.copyWith(
        isPublishing: false,
        error: userMessage,
        fieldErrors: fieldErrors,
      );
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isPublishing: false, error: e.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Save and publish error: $e');
      state = state.copyWith(
        isPublishing: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void reset() {
    state = OpportunityFormState(
      opportunity: Opportunity.empty(),
    );
  }

  /// Set client-side validation errors with user-friendly messages.
  void setValidationErrors(Map<String, String> fieldErrors) {
    state = state.copyWith(
      error: fieldErrors.values.join('\n'),
      fieldErrors: fieldErrors,
    );
  }

  void clearError() {
    state = state.copyWith(
      clearError: true,
      fieldErrors: {},
      requiresSubscription: false,
    );
  }
}

/// Provider for opportunity form
final opportunityFormProvider =
    NotifierProvider<OpportunityFormNotifier, OpportunityFormState>(
        OpportunityFormNotifier.new);
