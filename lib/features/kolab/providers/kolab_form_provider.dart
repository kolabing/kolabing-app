import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Hide NegotiationTrigger here — both kolab.dart and opportunity.dart export
// the same shape. Provider stays on the kolab.dart definition for writes.
import 'package:kolabing_app/features/opportunity/models/opportunity.dart'
    hide NegotiationTrigger;

import '../../../utils/remote_media_url.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../profile/providers/gallery_provider.dart';
import '../enums/intent_type.dart';
import '../enums/need_type.dart';
import '../enums/product_type.dart';
import '../enums/venue_type.dart';
import '../models/kolab.dart';
import '../services/kolab_service.dart';

// =============================================================================
// Form State
// =============================================================================

/// Form state for creating/editing a Kolab.
@immutable
class KolabFormState {
  const KolabFormState({
    required this.kolab,
    this.intentType,
    this.currentStep = 0,
    this.totalSteps = 6,
    this.isEditing = false,
    this.isSubmitting = false,
    this.isPublishing = false,
    this.isSuccess = false,
    this.requiresSubscription = false,
    this.error,
    this.fieldErrors = const {},
    this.recipientCommunityId,
  });

  final IntentType? intentType;
  final int currentStep;
  final int totalSteps;
  final Kolab kolab;
  final bool isEditing;
  final bool isSubmitting;
  final bool isPublishing;
  final bool isSuccess;
  final bool requiresSubscription;
  final String? error;
  final Map<String, String> fieldErrors;

  /// When set, the Kolab is being sent as a direct proposal to a specific
  /// community (e.g. from the Send-Kolab CTA on a public community profile).
  /// The publish endpoint receives this so the backend can scope visibility
  /// or notify the recipient.
  final String? recipientCommunityId;

  bool get canGoBack => currentStep > 0;
  bool get canGoNext => currentStep < totalSteps - 1;
  bool get isReviewStep => currentStep == totalSteps - 1;
  bool get hasIntent => intentType != null;

  KolabFormState copyWith({
    IntentType? intentType,
    int? currentStep,
    int? totalSteps,
    Kolab? kolab,
    bool? isEditing,
    bool? isSubmitting,
    bool? isPublishing,
    bool? isSuccess,
    bool? requiresSubscription,
    String? error,
    Map<String, String>? fieldErrors,
    String? recipientCommunityId,
    bool clearError = false,
    bool clearIntent = false,
    bool clearRecipientCommunityId = false,
  }) => KolabFormState(
    intentType: clearIntent ? null : (intentType ?? this.intentType),
    currentStep: currentStep ?? this.currentStep,
    totalSteps: totalSteps ?? this.totalSteps,
    kolab: kolab ?? this.kolab,
    isEditing: isEditing ?? this.isEditing,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isPublishing: isPublishing ?? this.isPublishing,
    isSuccess: isSuccess ?? this.isSuccess,
    requiresSubscription: requiresSubscription ?? this.requiresSubscription,
    error: clearError ? null : (error ?? this.error),
    fieldErrors: fieldErrors ?? this.fieldErrors,
    recipientCommunityId: clearRecipientCommunityId
        ? null
        : (recipientCommunityId ?? this.recipientCommunityId),
  );
}

// =============================================================================
// Form Notifier
// =============================================================================

class KolabFormNotifier extends Notifier<KolabFormState> {
  late final KolabService _service;

  @override
  KolabFormState build() {
    _service = ref.read(kolabServiceProvider);
    return KolabFormState(kolab: Kolab.empty(IntentType.communitySeeking));
  }

  // ---------------------------------------------------------------------------
  // Intent Selection
  // ---------------------------------------------------------------------------

  /// Stash a recipient community id from the Send-Kolab CTA so the publish
  /// payload can scope the Kolab to that community (C9 follow-up).
  void setRecipientCommunityId(String? id) {
    final trimmed = id?.trim();
    state = state.copyWith(
      recipientCommunityId: (trimmed == null || trimmed.isEmpty)
          ? null
          : trimmed,
      clearRecipientCommunityId: trimmed == null || trimmed.isEmpty,
    );
  }

  /// Select an intent type and reset the form for that flow. Preserves any
  /// stashed `recipientCommunityId` so the Send-Kolab CTA's target survives
  /// the intent reset.
  void selectIntent(IntentType intent) {
    final initialKolab = _buildInitialKolab(intent);
    final preservedRecipient = state.recipientCommunityId;
    state = KolabFormState(
      intentType: intent,
      currentStep: 0,
      totalSteps: intent.totalSteps,
      kolab: initialKolab,
      recipientCommunityId: preservedRecipient,
    );
  }

  /// Load an existing kolab into the unified flow for editing.
  void initForEdit(Kolab kolab) {
    final normalizedKolab = _normalizeKolabForSubmit(kolab);
    state = KolabFormState(
      intentType: normalizedKolab.intentType,
      currentStep: 0,
      totalSteps: normalizedKolab.intentType.totalSteps,
      kolab: normalizedKolab,
      isEditing: true,
    );
  }

  Kolab _buildInitialKolab(IntentType intent) {
    final onboardingState = ref.read(onboardingProvider);
    final businessProfile = _readBusinessProfile();
    final primaryVenue = businessProfile?.primaryVenue;

    var kolab = Kolab.empty(intent);

    if (intent == IntentType.communitySeeking) {
      kolab = kolab.copyWith(venuePreference: VenuePreference.noVenue);
    }

    final preferredCity =
        primaryVenue?.city ??
        businessProfile?.city?.name ??
        onboardingState?.location?.city ??
        onboardingState?.cityName ??
        '';

    kolab = kolab.copyWith(preferredCity: preferredCity);

    if (intent == IntentType.venuePromotion) {
      kolab = kolab.copyWith(
        venueName: primaryVenue?.name ?? onboardingState?.venueName,
        venueType: _resolveVenueType(
          primaryVenue?.venueType ?? onboardingState?.venueType,
        ),
        capacity: primaryVenue?.capacity ?? onboardingState?.venueCapacity,
        venueAddress:
            primaryVenue?.formattedAddress ??
            onboardingState?.location?.formattedAddress,
      );
    }

    return kolab;
  }

  BusinessProfile? _readBusinessProfile() {
    try {
      // ProfileProvider holds the freshest /me/profile payload (includes
      // primary_venue). Fall back to the auth user only if profile is
      // unavailable (e.g. immediately after sign-in before refresh).
      return ref.read(profileProvider).profile?.businessProfile ??
          ref.read(authProvider).user?.businessProfile;
    } on Exception {
      return null;
    }
  }

  /// Whether a default photo (profile gallery or, for venue Kolabs, the
  /// venue's own photos) exists that the Media step can fall back on instead
  /// of hard-blocking when `kolab.media` is still empty.
  bool _hasUsableDefaultPhoto(Kolab kolab) {
    if (kolab.media.isNotEmpty) return true;
    try {
      if (ref.read(galleryProvider).photos.isNotEmpty) return true;
    } on Exception {
      // Gallery not loaded yet — fall through to the venue-photo check.
    }
    if (kolab.intentType == IntentType.venuePromotion) {
      final venuePhotos = _readBusinessProfile()?.primaryVenue?.photos;
      if (venuePhotos != null && venuePhotos.isNotEmpty) return true;
    }
    return false;
  }

  VenueType? _resolveVenueType(String? rawType) {
    if (rawType == null || rawType.isEmpty) return null;
    try {
      return VenueType.fromString(rawType);
    } on Exception {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void nextStep() {
    if (!validateCurrentStep()) return;
    if (state.canGoNext) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
        fieldErrors: {},
      );
    }
  }

  void previousStep() {
    if (state.canGoBack) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
        fieldErrors: {},
      );
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(
        currentStep: step,
        clearError: true,
        fieldErrors: {},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Core Info
  // ---------------------------------------------------------------------------

  void updateTitle(String title) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(title: title),
      clearError: true,
    );
  }

  void updateDescription(String description) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(description: description),
      clearError: true,
    );
  }

  /// H2: short one-line headline pinned to the discovery card.
  void updateOfferHeadline(String? headline) {
    final trimmed = headline?.trim();
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        offerHeadline: trimmed?.isEmpty ?? true ? null : trimmed,
        clearOfferHeadline: trimmed == null || trimmed.isEmpty,
      ),
      clearError: true,
    );
  }

  /// H3: long-form public offer shown on the kolab detail.
  void updateBaseOffer(String? baseOffer) {
    final trimmed = baseOffer?.trim();
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        baseOffer: trimmed?.isEmpty ?? true ? null : trimmed,
        clearBaseOffer: trimmed == null || trimmed.isEmpty,
      ),
      clearError: true,
    );
  }

  /// New goal step: what the Kolab is meant to achieve, shown as a badge on
  /// Review.
  void updateGoal(String? goal) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        goal: goal,
        clearGoal: goal == null,
      ),
      clearError: true,
    );
  }

  /// H3: negotiation triggers (gated until a community applies).
  void updateNegotiationTriggers(List<NegotiationTrigger> triggers) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(negotiationTriggers: triggers),
      clearError: true,
    );
  }

  void updatePreferredCity(String city) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(preferredCity: city),
      clearError: true,
    );
  }

  void updateArea(String? area) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(area: area, clearArea: area == null),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Media
  // ---------------------------------------------------------------------------

  void addMedia(KolabMedia media) {
    final updated = [...state.kolab.media, media];
    state = state.copyWith(
      kolab: state.kolab.copyWith(media: updated),
      clearError: true,
    );
  }

  void removeMedia(int index) {
    final updated = List<KolabMedia>.from(state.kolab.media)..removeAt(index);
    state = state.copyWith(
      kolab: state.kolab.copyWith(media: updated),
      clearError: true,
    );
  }

  void updateMedia(List<KolabMedia> media) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(media: media),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Availability
  // ---------------------------------------------------------------------------

  void updateAvailabilityMode(AvailabilityMode mode) {
    final kolab = state.kolab;
    var start = kolab.availabilityStart;
    var end = kolab.availabilityEnd;

    // Pre-fill a one-time kolab with sensible default dates (tomorrow → one
    // month later) so the range isn't empty; still fully editable.
    if (mode == AvailabilityMode.oneTime && start == null) {
      final tomorrow =
          DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
      start = tomorrow;
      end ??= DateTime(tomorrow.year, tomorrow.month + 1, tomorrow.day);
    }

    // Immediate is always-available-from-today; no date picker is shown for
    // it, so default the start date to today so submission validates.
    if (mode == AvailabilityMode.immediate) {
      start = DateUtils.dateOnly(DateTime.now());
    }

    state = state.copyWith(
      kolab: kolab.copyWith(
        availabilityMode: mode,
        availabilityStart: start,
        availabilityEnd: end,
        recurringDays: mode != AvailabilityMode.recurring ? const [] : null,
      ),
      clearError: true,
    );
  }

  void updateAvailabilityStart(DateTime date) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(availabilityStart: date),
      clearError: true,
    );
  }

  void updateAvailabilityEnd(DateTime date) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(availabilityEnd: date),
      clearError: true,
    );
  }

  void updateSelectedTime(TimeOfDay? time) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        selectedTime: time,
        clearSelectedTime: time == null,
      ),
      clearError: true,
    );
  }

  void toggleRecurringDay(int day) {
    final days = List<int>.from(state.kolab.recurringDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days
        ..add(day)
        ..sort();
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(recurringDays: days),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Community Seeking
  // ---------------------------------------------------------------------------

  void toggleNeed(NeedType need) {
    final needs = List<NeedType>.from(state.kolab.needs);
    if (needs.contains(need)) {
      needs.remove(need);
    } else {
      needs.add(need);
    }
    state = state.copyWith(
      kolab: _syncVenuePreferenceForNeeds(state.kolab, needs),
      clearError: true,
    );
  }

  void updateNeeds(List<NeedType> needs) {
    state = state.copyWith(
      kolab: _syncVenuePreferenceForNeeds(state.kolab, needs),
      clearError: true,
    );
  }

  void toggleCommunityType(String type) {
    final types = List<String>.from(state.kolab.communityTypes);
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(communityTypes: types),
      clearError: true,
    );
  }

  void updateCommunityTypes(List<String> types) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(communityTypes: types),
      clearError: true,
    );
  }

  void updateCommunitySize(int? size) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        communitySize: size,
        clearCommunitySize: size == null,
      ),
      clearError: true,
    );
  }

  void updateTypicalAttendance(int? attendance) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        typicalAttendance: attendance,
        clearTypicalAttendance: attendance == null,
      ),
      clearError: true,
    );
  }

  void toggleOfferInReturn(String slug) {
    final offers = List<String>.from(state.kolab.offersInReturn);
    if (offers.contains(slug)) {
      offers.remove(slug);
    } else {
      offers.add(slug);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(offersInReturn: offers),
      clearError: true,
    );
  }

  void updateOffersInReturn(List<String> offers) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(offersInReturn: offers),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Venue Promotion
  // ---------------------------------------------------------------------------

  void updateVenueName(String? name) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        venueName: name,
        clearVenueName: name == null,
      ),
      clearError: true,
    );
  }

  void updateVenueType(VenueType? type) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        venueType: type,
        clearVenueType: type == null,
      ),
      clearError: true,
    );
  }

  void updateCapacity(int? capacity) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        capacity: capacity,
        clearCapacity: capacity == null,
      ),
      clearError: true,
    );
  }

  void updateVenueAddress(String? address) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        venueAddress: address,
        clearVenueAddress: address == null,
      ),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Product Promotion
  // ---------------------------------------------------------------------------

  void updateProductName(String? name) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        productName: name,
        clearProductName: name == null,
      ),
      clearError: true,
    );
  }

  void updateProductType(ProductType? type) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        productType: type,
        clearProductType: type == null,
      ),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Offering & Seeking (Business flows)
  // ---------------------------------------------------------------------------

  void toggleOffering(String item) {
    final list = List<String>.from(state.kolab.offering);
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(offering: list),
      clearError: true,
    );
  }

  void updateOffering(List<String> offering) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(offering: offering),
      clearError: true,
    );
  }

  void toggleSeekingCommunity(String community) {
    final list = List<String>.from(state.kolab.seekingCommunities);
    if (list.contains(community)) {
      list.remove(community);
    } else {
      list.add(community);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(seekingCommunities: list),
      clearError: true,
    );
  }

  void updateSeekingCommunities(List<String> communities) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(seekingCommunities: communities),
      clearError: true,
    );
  }

  void updateMinCommunitySize(int? size) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(
        minCommunitySize: size,
        clearMinCommunitySize: size == null,
      ),
      clearError: true,
    );
  }

  void toggleExpect(String slug) {
    final list = List<String>.from(state.kolab.expects);
    if (list.contains(slug)) {
      list.remove(slug);
    } else {
      list.add(slug);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(expects: list),
      clearError: true,
    );
  }

  void toggleHighlight(String slug) {
    final list = List<String>.from(state.kolab.highlights);
    if (list.contains(slug)) {
      list.remove(slug);
    } else {
      list.add(slug);
    }
    state = state.copyWith(
      kolab: state.kolab.copyWith(highlights: list),
      clearError: true,
    );
  }

  void updateExpects(List<String> expects) {
    state = state.copyWith(
      kolab: state.kolab.copyWith(expects: expects),
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Field Updates - Past Events
  // ---------------------------------------------------------------------------

  void addPastEvent(PastEvent event) {
    final events = [...state.kolab.pastEvents, event];
    state = state.copyWith(
      kolab: state.kolab.copyWith(pastEvents: events),
      clearError: true,
    );
  }

  void removePastEvent(int index) {
    final events = List<PastEvent>.from(state.kolab.pastEvents)
      ..removeAt(index);
    state = state.copyWith(
      kolab: state.kolab.copyWith(pastEvents: events),
      clearError: true,
    );
  }

  void updatePastEvent(int index, PastEvent event) {
    final events = List<PastEvent>.from(state.kolab.pastEvents);
    if (index < events.length) {
      events[index] = event;
      state = state.copyWith(
        kolab: state.kolab.copyWith(pastEvents: events),
        clearError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool validateCurrentStep() {
    final kolab = state.kolab;
    final intent = state.intentType;
    if (intent == null) return false;

    final errors = <String, String>{};

    switch (intent) {
      case IntentType.communitySeeking:
        _validateCommunitySeekingStep(state.currentStep, kolab, errors);
      case IntentType.venuePromotion:
        _validateVenuePromotionStep(state.currentStep, kolab, errors);
      case IntentType.productPromotion:
        _validateProductPromotionStep(state.currentStep, kolab, errors);
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(fieldErrors: {});
    return true;
  }

  void _validateCommunitySeekingStep(
    int step,
    Kolab kolab,
    Map<String, String> errors,
  ) {
    switch (step) {
      case 0: // What do you need?
        if (kolab.needs.isEmpty) {
          errors['needs'] = 'Select at least 1 need';
        }
      case 1: // About your community
        // community_types + community_size are inherited from the community
        // profile (set at onboarding), so they are NOT asked/validated here.
        // Only typical_attendance is a per-kolab input.
        if (kolab.typicalAttendance == null || kolab.typicalAttendance! <= 0) {
          errors['typical_attendance'] =
              'Typical attendance must be greater than 0';
        }
      case 2: // Your Kolab details
        if (kolab.title.isEmpty) {
          errors['title'] = 'Title is required';
        }
        if (kolab.description.isEmpty) {
          errors['description'] = 'Description is required';
        }
        if (kolab.offersInReturn.isEmpty) {
          errors['offers_in_return'] = 'Select at least 1 deliverable';
        }
      case 3: // Availability & Location
        if (kolab.availabilityMode == null) {
          errors['availability_mode'] = 'Select an availability mode';
        } else {
          switch (kolab.availabilityMode!) {
            case AvailabilityMode.oneTime:
              if (kolab.availabilityStart == null) {
                errors['availability_start'] =
                    'Pick a start date for your availability window';
              }
              if (kolab.availabilityEnd == null) {
                errors['availability_end'] =
                    'Pick an end date for your availability window';
              }
              if (kolab.selectedTime == null) {
                errors['selected_time'] = 'Select a time for your availability';
              }
            case AvailabilityMode.recurring:
              if (kolab.recurringDays.isEmpty) {
                errors['recurring_day'] = 'Select at least 1 recurring day';
              }
              if (kolab.selectedTime == null) {
                errors['selected_time'] = 'Select a time for your availability';
              }
            case AvailabilityMode.immediate:
              // Business-Kolab-only mode; unreachable on the
              // community-seeking flow's availability picker.
              break;
          }
        }
        if (kolab.preferredCity.isEmpty) {
          errors['preferred_city'] = 'Preferred city is required';
        }
      case 4: // Media (optional)
        // No required validation for media step
        break;
      case 5: // Review
        // Review step has no additional validation
        break;
    }
  }

  void _validateVenuePromotionStep(
    int step,
    Kolab kolab,
    Map<String, String> errors,
  ) {
    switch (step) {
      case 0: // Campaign copy only — venue meta inherited from onboarding profile
        if (kolab.title.isEmpty) {
          errors['title'] = 'Title is required';
        }
        if (kolab.description.isEmpty) {
          errors['description'] = 'Description is required';
        }
        // H2: offer headline is required on venue promotion.
        if (kolab.offerHeadline == null ||
            kolab.offerHeadline!.trim().isEmpty) {
          errors['offer_headline'] =
              'Add a one-line offer headline (e.g. "20% off Tuesdays")';
        }
      case 1: // Goal (optional — encouraged, not blocking)
        break;
      case 2: // Media
        // Soft requirement: don't block when a default photo exists
        // (profile gallery or venue photos) — Next stays enabled and the
        // Media screen shows a tip instead of a hard error in that case.
        if (kolab.media.isEmpty && !_hasUsableDefaultPhoto(kolab)) {
          errors['media'] = 'Add at least 1 photo';
        }
      case 3: // What you offer
        if (kolab.offering.isEmpty) {
          errors['offering'] = 'Select at least 1 offering';
        }
        if (kolab.baseOffer == null || kolab.baseOffer!.trim().isEmpty) {
          errors['base_offer'] = 'Describe your offer so communities know what to expect';
        }
      case 4: // Seeking communities
        // No required validation
        break;
      case 5: // Expectations
        // No required validation
        break;
      case 6: // Availability
        if (kolab.availabilityMode == null) {
          errors['availability_mode'] = 'Select an availability mode';
        } else if (kolab.availabilityStart == null) {
          errors['availability_start'] =
              'Pick a start date for your availability window';
        } else {
          final isImmediate = kolab.availabilityMode == AvailabilityMode.immediate;
          final floor = isImmediate
              ? DateUtils.dateOnly(DateTime.now())
              : DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
          final start = DateUtils.dateOnly(kolab.availabilityStart!);
          if (start.isBefore(floor)) {
            errors['availability_start'] = isImmediate
                ? 'Start date cannot be in the past'
                : 'Start date must be tomorrow or later';
          }
        }
      case 7: // Review
        // Review step has no additional validation
        break;
    }
  }

  void _validateProductPromotionStep(
    int step,
    Kolab kolab,
    Map<String, String> errors,
  ) {
    switch (step) {
      case 0: // Product details
        if (kolab.title.isEmpty) {
          errors['title'] = 'Title is required';
        }
        if (kolab.productName == null || kolab.productName!.isEmpty) {
          errors['product_name'] = 'Product name is required';
        }
        if (kolab.productType == null) {
          errors['product_type'] = 'Select a product type';
        }
        if (kolab.description.isEmpty) {
          errors['description'] = 'Description is required';
        }
        if (kolab.preferredCity.isEmpty) {
          errors['preferred_city'] = 'Preferred city is required';
        }
        // H2: offer headline is required on product promotion.
        if (kolab.offerHeadline == null ||
            kolab.offerHeadline!.trim().isEmpty) {
          errors['offer_headline'] =
              'Add a one-line offer headline (e.g. "Free with any 5+ order")';
        }
      case 1: // Goal (optional — encouraged, not blocking)
        break;
      case 2: // Media
        // Soft requirement: don't block when a default photo exists
        // (profile gallery or venue photos) — Next stays enabled and the
        // Media screen shows a tip instead of a hard error in that case.
        if (kolab.media.isEmpty && !_hasUsableDefaultPhoto(kolab)) {
          errors['media'] = 'Add at least 1 photo';
        }
      case 3: // What you offer
        if (kolab.offering.isEmpty) {
          errors['offering'] = 'Select at least 1 offering';
        }
        if (kolab.baseOffer == null || kolab.baseOffer!.trim().isEmpty) {
          errors['base_offer'] = 'Describe your offer so communities know what to expect';
        }
      case 4: // Seeking communities
        // No required validation
        break;
      case 5: // Expectations
        // No required validation
        break;
      case 6: // Availability
        if (kolab.availabilityMode == null) {
          errors['availability_mode'] = 'Select an availability mode';
        } else if (kolab.availabilityStart == null) {
          errors['availability_start'] =
              'Pick a start date for your availability window';
        } else {
          final isImmediate = kolab.availabilityMode == AvailabilityMode.immediate;
          final floor = isImmediate
              ? DateUtils.dateOnly(DateTime.now())
              : DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
          final start = DateUtils.dateOnly(kolab.availabilityStart!);
          if (start.isBefore(floor)) {
            errors['availability_start'] = isImmediate
                ? 'Start date cannot be in the past'
                : 'Start date must be tomorrow or later';
          }
        }
      case 7: // Review
        // Review step has no additional validation
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  /// Save as draft.
  Future<bool> saveDraft() async {
    // Re-entry guard: ignore rapid double-taps while a submission is in flight.
    if (state.isSubmitting || state.isPublishing) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      requiresSubscription: false,
    );

    try {
      final kolabToPersist = _normalizeKolabForSubmit(state.kolab);
      state = state.copyWith(kolab: kolabToPersist);
      Kolab result;
      if (state.isEditing && state.kolab.id != null) {
        result = await _service.update(state.kolab.id!, kolabToPersist);
      } else {
        result = await _service.create(kolabToPersist);
      }
      state = state.copyWith(
        kolab: result,
        isSubmitting: false,
        isSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('Save draft API error: $e');
      _handleApiError(e, isPublishing: false);
      return false;
    } on Exception catch (e) {
      debugPrint('Save draft error: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Save and publish.
  Future<bool> saveAndPublish() async {
    // Re-entry guard: ignore rapid double-taps while a submission is in flight.
    if (state.isSubmitting || state.isPublishing) return false;

    state = state.copyWith(
      isPublishing: true,
      clearError: true,
      requiresSubscription: false,
    );

    debugPrint(
      '[B1B7] saveAndPublish start: isEditing=${state.isEditing} '
      'kolabId=${state.kolab.id} mediaCount=${state.kolab.media.length} '
      'mediaTypes=${state.kolab.media.map((m) => m.type).toSet().toList()}',
    );

    try {
      final kolabToPersist = _normalizeKolabForSubmit(state.kolab);
      state = state.copyWith(kolab: kolabToPersist);
      Kolab saved;
      if (state.isEditing && state.kolab.id != null) {
        saved = await _service.update(state.kolab.id!, kolabToPersist);
      } else {
        saved = await _service.create(kolabToPersist);
      }
      debugPrint('[B1B7] save ok: id=${saved.id} status=${saved.status}');

      // Persist the saved record immediately and flip to edit-mode so a
      // subsequent retry (e.g. publish fails below) updates the existing
      // draft instead of creating a duplicate.
      state = state.copyWith(kolab: saved, isEditing: true);

      // Publish the saved kolab. recipientCommunityId is passed only when set
      // (Send-Kolab CTA flow) so the backend can scope visibility / notify
      // the recipient.
      final published = await _service.publish(
        saved.id!,
        saved,
        recipientCommunityId: state.recipientCommunityId,
      );
      debugPrint(
        '[B1B7] publish ok: id=${published.id} status=${published.status}',
      );

      // Backend safety net (B1): if the server returned 200 but the kolab is
      // still a draft, treat it as a subscription block so the existing
      // paywall flow kicks in instead of silently leaving the user stranded.
      if (published.status != 'published') {
        debugPrint(
          '[B1B7] publish returned non-published status=${published.status} — '
          'treating as subscription requirement',
        );
        state = state.copyWith(
          kolab: published,
          isPublishing: false,
          requiresSubscription: true,
        );
        return false;
      }

      state = state.copyWith(
        kolab: published,
        isPublishing: false,
        isSuccess: true,
      );
      return true;
    } on ApiException catch (e) {
      debugPrint(
        '[B1B7] ApiException: status=${e.error.statusCode} '
        'requiresSubscription=${e.error.requiresSubscription} '
        'message=${e.error.message} '
        'fieldErrors=${e.error.errors?.keys.toList() ?? []}',
      );
      _handleApiError(e, isPublishing: true);
      return false;
    } on Exception catch (e) {
      debugPrint('[B1B7] unexpected: $e');
      state = state.copyWith(isPublishing: false, error: e.toString());
      return false;
    }
  }

  /// Handle API errors — extract field errors for 422, subscription for 402
  void _handleApiError(ApiException e, {required bool isPublishing}) {
    final apiError = e.error;

    // 402 — subscription required
    if (apiError.requiresSubscription || apiError.statusCode == 402) {
      state = state.copyWith(
        isSubmitting: false,
        isPublishing: false,
        requiresSubscription: true,
      );
      return;
    }

    // 422 — validation errors
    if (apiError.isValidationError && apiError.errors != null) {
      final fieldErrors = <String, String>{};
      for (final entry in apiError.errors!.entries) {
        final friendly = apiError.getFriendlyFieldError(entry.key);
        if (friendly != null) {
          fieldErrors[entry.key] = friendly;
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        isPublishing: false,
        error: apiError.allErrorMessages,
        fieldErrors: fieldErrors,
      );
      return;
    }

    // Other API errors
    state = state.copyWith(
      isSubmitting: false,
      isPublishing: false,
      error: apiError.allErrorMessages,
    );
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void reset() {
    // Drop the recipientCommunityId as well — a new Send-Kolab session will
    // set it again via setRecipientCommunityId.
    state = KolabFormState(kolab: Kolab.empty(IntentType.communitySeeking));
  }

  void clearSubscriptionRequirement() {
    if (!state.requiresSubscription) {
      return;
    }

    state = state.copyWith(requiresSubscription: false);
  }

  Kolab _syncVenuePreferenceForNeeds(Kolab kolab, List<NeedType> needs) {
    if (!needs.contains(NeedType.venue)) {
      return kolab.copyWith(
        needs: needs,
        venuePreference: VenuePreference.noVenue,
      );
    }

    return kolab.copyWith(
      needs: needs,
      venuePreference: kolab.venuePreference ?? VenuePreference.noVenue,
    );
  }

  Kolab _normalizeKolabForSubmit(Kolab kolab) {
    final normalizedAvailability = kolab.availabilityMode == null
        ? null
        : AvailabilityMode.fromString(kolab.availabilityMode!.toApiValue());
    final normalizedKolab = kolab.copyWith(
      availabilityMode: normalizedAvailability,
      media: kolab.media
          .map(
            (media) => media.copyWith(
              url: normalizeRemoteMediaUrl(media.url),
            ),
          )
          .where((media) => media.url.isNotEmpty)
          .toList(growable: false),
    );

    if (normalizedKolab.intentType != IntentType.communitySeeking) {
      return normalizedKolab;
    }

    return _syncVenuePreferenceForNeeds(normalizedKolab, normalizedKolab.needs);
  }
}

/// Provider for the Kolab creation/editing form.
final kolabFormProvider = NotifierProvider<KolabFormNotifier, KolabFormState>(
  KolabFormNotifier.new,
);
