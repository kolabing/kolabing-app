import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_photo.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';

void main() {
  group('OnboardingData draft JSON round-trip', () {
    test('a fully populated business draft survives toJson/fromJson', () {
      const data = OnboardingData(
        userType: UserType.business,
        name: 'Sol Studio',
        photoBase64: 'abc123',
        photoFileName: 'logo.png',
        photoMimeType: 'image/png',
        type: 'business-type-id',
        typeSlug: 'cafe',
        typeName: 'Cafe',
        businessTypeIds: ['id-1', 'id-2'],
        businessTypeSlugs: ['cafe', 'bar'],
        businessTypeNames: ['Cafe', 'Bar'],
        hasVenue: true,
        targetCityIds: ['city-1'],
        targetCityNames: ['Barcelona'],
        offering: 'Coffee and pastries',
        productType: 'food',
        communitySize: null,
        cityId: 'city-1',
        cityName: 'Barcelona',
        location: PlaceSuggestion(
          placeId: 'place-123',
          title: 'Sol Studio',
          formattedAddress: 'Carrer de Mallorca 1, Barcelona',
          city: 'Barcelona',
          country: 'Spain',
          latitude: 41.3874,
          longitude: 2.1686,
          cityId: 'city-1',
        ),
        importedPlaceId: 'place-123',
        venueName: 'Sol Studio Rooftop',
        venueType: 'restaurant',
        venueCapacity: 120,
        venuePhotos: [
          OnboardingPhoto(
            base64: 'xyz789',
            fileName: 'venue1.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
        venuePhone: '+34600000000',
        venueWebsite: 'https://solstudio.example',
        venueOpeningHours: ['Mon-Fri 9-18'],
        venueDescription: 'A rooftop cafe',
        venuePriceLevel: 'PRICE_LEVEL_MODERATE',
        venueRating: 4.5,
        venueUserRatingsTotal: 120,
        venueGooglePlaceTypes: ['cafe', 'restaurant'],
        about: 'We serve great coffee',
        phone: '+34600000001',
        instagram: 'solstudio',
        website: 'https://solstudio.example',
        referralCode: 'FRIEND10',
        currentStep: 3,
      );

      final restored = OnboardingData.fromJson(data.toJson());

      expect(restored.userType, data.userType);
      expect(restored.name, data.name);
      expect(restored.photoBase64, data.photoBase64);
      expect(restored.businessTypeSlugs, data.businessTypeSlugs);
      expect(restored.hasVenue, data.hasVenue);
      expect(restored.targetCityIds, data.targetCityIds);
      expect(restored.location?.placeId, data.location?.placeId);
      expect(restored.location?.latitude, data.location?.latitude);
      expect(restored.venueName, data.venueName);
      expect(restored.venueCapacity, data.venueCapacity);
      expect(restored.venuePhotos.length, 1);
      expect(restored.venuePhotos.first.base64, 'xyz789');
      expect(restored.venuePhotos.first.isUploaded, true);
      expect(restored.venueRating, data.venueRating);
      expect(restored.about, data.about);
      expect(restored.referralCode, data.referralCode);
      expect(restored.currentStep, data.currentStep);
    });

    test('a blank community draft survives toJson/fromJson', () {
      const data = OnboardingData(userType: UserType.community);

      final restored = OnboardingData.fromJson(data.toJson());

      expect(restored.userType, UserType.community);
      expect(restored.name, isNull);
      expect(restored.venuePhotos, isEmpty);
      expect(restored.currentStep, 1);
    });

    test('a Google-imported venue photo survives the round-trip', () {
      final data = OnboardingData(
        userType: UserType.business,
        venuePhotos: [
          OnboardingPhoto.googleImported(
            resourceName: 'places/abc/photos/xyz',
            previewUrl: 'https://example.com/photo.jpg',
            width: 800,
            height: 600,
          ),
        ],
      );

      final restored = OnboardingData.fromJson(data.toJson());

      expect(restored.venuePhotos.first.isGoogleImported, true);
      expect(restored.venuePhotos.first.resourceName, 'places/abc/photos/xyz');
      expect(restored.venuePhotos.first.width, 800);
    });
  });
}
