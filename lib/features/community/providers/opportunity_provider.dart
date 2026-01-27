import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../onboarding/models/city.dart';
import '../models/opportunity.dart';
import '../services/opportunity_service.dart';

/// Provider for OpportunityService instance
final opportunityServiceProvider = Provider<OpportunityService>(
  (ref) => OpportunityService.instance,
);

/// Provider for cities dropdown
final citiesProvider = FutureProvider<List<OnboardingCity>>((ref) async {
  final service = ref.watch(opportunityServiceProvider);
  return service.getCities();
});

/// Form state for creating/editing opportunities
@immutable
class OpportunityFormState {
  const OpportunityFormState({
    this.currentStep = 0,
    this.opportunity,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
    this.fieldErrors = const {},
  });

  final int currentStep;
  final Opportunity? opportunity;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;
  final Map<String, String> fieldErrors;

  int get totalSteps => 4; // Basic, Details, Offer, Review

  bool get canGoBack => currentStep > 0;
  bool get canGoNext => currentStep < totalSteps - 1;
  bool get isReviewStep => currentStep == totalSteps - 1;

  OpportunityFormState copyWith({
    int? currentStep,
    Opportunity? opportunity,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) =>
      OpportunityFormState(
        currentStep: currentStep ?? this.currentStep,
        opportunity: opportunity ?? this.opportunity,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isSuccess: isSuccess ?? this.isSuccess,
        error: clearError ? null : (error ?? this.error),
        fieldErrors: fieldErrors ?? this.fieldErrors,
      );
}

/// Notifier for opportunity form
class OpportunityFormNotifier extends Notifier<OpportunityFormState> {
  late final OpportunityService _service;

  @override
  OpportunityFormState build() {
    _service = ref.read(opportunityServiceProvider);

    // Initialize with default opportunity
    return OpportunityFormState(
      opportunity: Opportunity(
        title: '',
        type: OpportunityType.event,
        description: '',
        cityId: '',
        startDate: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  }

  /// Go to next step
  void nextStep() {
    if (state.canGoNext) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.canGoBack) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  /// Update opportunity data
  void updateOpportunity(Opportunity opportunity) {
    state = state.copyWith(opportunity: opportunity, clearError: true);
  }

  /// Update specific field
  void updateField({
    String? title,
    OpportunityType? type,
    String? description,
    String? cityId,
    String? cityName,
    DateTime? startDate,
    DateTime? endDate,
    int? expectedAttendees,
    bool? hasReward,
    String? rewardDescription,
    String? budget,
    String? requirements,
    bool clearEndDate = false,
    bool clearReward = false,
  }) {
    final current = state.opportunity;
    if (current == null) return;

    state = state.copyWith(
      opportunity: current.copyWith(
        title: title,
        type: type,
        description: description,
        cityId: cityId,
        cityName: cityName,
        startDate: startDate,
        endDate: endDate,
        expectedAttendees: expectedAttendees,
        hasReward: hasReward,
        rewardDescription: rewardDescription,
        budget: budget,
        requirements: requirements,
        clearEndDate: clearEndDate,
        clearReward: clearReward,
      ),
      clearError: true,
    );
  }

  /// Validate current step
  bool validateCurrentStep() {
    final opportunity = state.opportunity;
    if (opportunity == null) return false;

    final errors = <String, String>{};

    switch (state.currentStep) {
      case 0: // Basic Info
        if (opportunity.title.isEmpty) {
          errors['title'] = 'Title is required';
        } else if (opportunity.title.length > 255) {
          errors['title'] = 'Title must be less than 255 characters';
        }
        if (opportunity.description.isEmpty) {
          errors['description'] = 'Description is required';
        } else if (opportunity.description.length > 2000) {
          errors['description'] = 'Description must be less than 2000 characters';
        }
      case 1: // Details
        if (opportunity.cityId.isEmpty) {
          errors['city'] = 'City is required';
        }
        if (opportunity.startDate.isBefore(DateTime.now())) {
          errors['startDate'] = 'Start date must be in the future';
        }
        if (opportunity.endDate != null &&
            opportunity.endDate!.isBefore(opportunity.startDate)) {
          errors['endDate'] = 'End date must be after start date';
        }
      case 2: // Offer
        if (opportunity.hasReward &&
            (opportunity.rewardDescription?.isEmpty ?? true)) {
          errors['reward'] = 'Reward description is required when offering a reward';
        }
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(fieldErrors: {});
    return true;
  }

  /// Submit the opportunity
  Future<bool> submit() async {
    final opportunity = state.opportunity;
    if (opportunity == null) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final created = await _service.createOpportunity(opportunity);
      state = state.copyWith(
        opportunity: created,
        isSubmitting: false,
        isSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      // Convert Map<String, List<String>>? to Map<String, String>
      final fieldErrors = <String, String>{};
      if (e.error.errors != null) {
        for (final entry in e.error.errors!.entries) {
          if (entry.value.isNotEmpty) {
            fieldErrors[entry.key] = entry.value.first;
          }
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        error: e.error.message,
        fieldErrors: fieldErrors,
      );
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.message,
      );
      return false;
    } on Exception catch (e) {
      debugPrint('Submit opportunity error: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  /// Reset the form
  void reset() {
    state = OpportunityFormState(
      opportunity: Opportunity(
        title: '',
        type: OpportunityType.event,
        description: '',
        cityId: '',
        startDate: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true, fieldErrors: {});
  }
}

/// Provider for opportunity form
final opportunityFormProvider =
    NotifierProvider<OpportunityFormNotifier, OpportunityFormState>(
        OpportunityFormNotifier.new);

/// Provider for user's opportunities list
final myOpportunitiesProvider =
    AsyncNotifierProvider<MyOpportunitiesNotifier, List<Opportunity>>(
        MyOpportunitiesNotifier.new);

/// Notifier for user's opportunities
class MyOpportunitiesNotifier extends AsyncNotifier<List<Opportunity>> {
  @override
  Future<List<Opportunity>> build() async {
    final service = ref.read(opportunityServiceProvider);
    return service.getMyOpportunities();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final service = ref.read(opportunityServiceProvider);
    state = await AsyncValue.guard(service.getMyOpportunities);
  }

  Future<bool> delete(String id) async {
    try {
      final service = ref.read(opportunityServiceProvider);
      await service.deleteOpportunity(id);

      // Remove from local list
      final current = state.hasValue ? state.value! : <Opportunity>[];
      state = AsyncData(
        current.where((Opportunity o) => o.id != id).toList(),
      );
      return true;
    } on Exception catch (e) {
      debugPrint('Delete opportunity error: $e');
      return false;
    }
  }
}
