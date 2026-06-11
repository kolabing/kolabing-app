import 'package:flutter/foundation.dart';

/// Local state for the attendee onboarding flow (4 steps: You, City, Interests,
/// Join). Submitted as `PUT /onboarding/attendee`
/// `{ name, handle, city_id?, interests:[slug], community_ids:[uuid], photo? }`.
///
/// Only `name` + `handle` are required; every other field is skippable. The
/// photo is carried as base64 (+ filename/mime) and serialized to a data-URI on
/// submit, mirroring the community onboarding payload shape.
@immutable
class AttendeeOnboardingData {
  const AttendeeOnboardingData({
    this.name = '',
    this.handle = '',
    this.cityId,
    this.cityName,
    this.interests = const [],
    this.communityIds = const [],
    this.photoBase64,
    this.photoFileName,
    this.photoMimeType,
    this.currentStep = 1,
  });

  final String name;

  /// Stored lowercase, format `^[a-z0-9_]{3,20}$`. No leading `@`.
  final String handle;
  final String? cityId;
  final String? cityName;

  /// Community-type SLUGS (the values `GET /community-types` returns).
  final List<String> interests;

  /// Open communities the attendee chose to join on the Join step.
  final List<String> communityIds;
  final String? photoBase64;
  final String? photoFileName;
  final String? photoMimeType;
  final int currentStep;

  bool get hasName => name.trim().isNotEmpty;

  /// Step 1 (You) requires a name and a valid, available handle. Handle format
  /// is validated by the screen; here we only assert presence.
  bool get isStep1Complete => hasName && handle.trim().isNotEmpty;

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  /// Photo encoded as a data-URI (`data:<mime>;base64,<...>`) for the payload,
  /// matching the community onboarding contract. Null when no photo was picked.
  String? get photoDataUri {
    if (!hasPhoto) return null;
    final mime = photoMimeType ?? 'image/jpeg';
    return 'data:$mime;base64,$photoBase64';
  }

  /// `PUT /onboarding/attendee` body. Optional fields are omitted when empty so
  /// a re-run never clobbers a previously-set value with a blank.
  Map<String, dynamic> toPayload() => {
    'name': name.trim(),
    'handle': handle.trim().toLowerCase(),
    if (cityId != null) 'city_id': cityId,
    'interests': interests,
    'community_ids': communityIds,
    if (photoDataUri != null) 'photo': photoDataUri,
  };

  AttendeeOnboardingData copyWith({
    String? name,
    String? handle,
    String? cityId,
    String? cityName,
    List<String>? interests,
    List<String>? communityIds,
    String? photoBase64,
    String? photoFileName,
    String? photoMimeType,
    int? currentStep,
    bool clearPhoto = false,
    bool clearCity = false,
  }) => AttendeeOnboardingData(
    name: name ?? this.name,
    handle: handle ?? this.handle,
    cityId: clearCity ? null : (cityId ?? this.cityId),
    cityName: clearCity ? null : (cityName ?? this.cityName),
    interests: interests ?? this.interests,
    communityIds: communityIds ?? this.communityIds,
    photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
    photoFileName: clearPhoto ? null : (photoFileName ?? this.photoFileName),
    photoMimeType: clearPhoto ? null : (photoMimeType ?? this.photoMimeType),
    currentStep: currentStep ?? this.currentStep,
  );
}
