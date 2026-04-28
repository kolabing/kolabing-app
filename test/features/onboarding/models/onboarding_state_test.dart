import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_photo.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';

void main() {
  test('business payload includes primary venue location and photos', () {
    const data = OnboardingData(
      userType: UserType.business,
      name: 'Sol Studio',
      type: 'business-type-id',
      typeSlug: 'cafe',
      typeName: 'Cafe',
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
      venueName: 'Sol Studio Rooftop',
      venueType: 'restaurant',
      venueCapacity: 120,
      venuePhotos: [
        OnboardingPhoto(
          base64: 'abc123',
          fileName: 'venue.jpg',
          mimeType: 'image/jpeg',
        ),
      ],
      about: 'Neighborhood hangout for creator events.',
      phone: '+34612345678',
      instagram: 'solstudio',
      website: 'https://solstudio.com',
    );

    final payload = data.toBusinessPayload();
    final primaryVenue = payload['primary_venue'] as Map<String, dynamic>;
    final photos = primaryVenue['photos'] as List<dynamic>;

    expect(payload['city_id'], 'city-1');
    expect(primaryVenue['name'], 'Sol Studio Rooftop');
    expect(primaryVenue['venue_type'], 'restaurant');
    expect(primaryVenue['place_id'], 'place-123');
    expect(
      primaryVenue['formatted_address'],
      'Carrer de Mallorca 1, Barcelona',
    );
    expect(photos, ['data:image/jpeg;base64,abc123']);
  });

  test('business payload keeps up to three business categories', () {
    const data = OnboardingData(
      userType: UserType.business,
      name: 'Sol Studio',
      businessTypeIds: ['1', '2', '3'],
      businessTypeSlugs: ['cafe', 'coworking', 'events'],
      businessTypeNames: ['Cafe', 'Coworking', 'Events'],
      location: PlaceSuggestion(
        placeId: 'place-123',
        title: 'Sol Studio',
        formattedAddress: 'Carrer de Mallorca 1, Barcelona',
        city: 'Barcelona',
      ),
      venueName: 'Sol Studio Rooftop',
      venueType: 'restaurant',
      venueCapacity: 120,
      venuePhotos: [
        OnboardingPhoto(
          base64: 'abc123',
          fileName: 'venue.jpg',
          mimeType: 'image/jpeg',
        ),
      ],
    );

    final payload = data.toBusinessPayload();

    expect(payload['business_types'], ['cafe', 'coworking', 'events']);
    expect(payload['business_type'], 'cafe');
    expect(data.isStep4Complete, isTrue);
    expect(data.isComplete, isTrue);
  });
}
