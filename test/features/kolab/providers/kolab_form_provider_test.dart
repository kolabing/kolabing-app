import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/enums/venue_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/onboarding/models/place_suggestion.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';

void main() {
  test('venue promotion step 0 requires title and description', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(kolabFormProvider.notifier)
      ..selectIntent(IntentType.venuePromotion)
      ..updateVenueName('Cafe Montjuic')
      ..updateVenueType(VenueType.cafe)
      ..updateCapacity(80)
      ..updateVenueAddress('Carrer de Montjuic 42')
      ..updatePreferredCity('Barcelona');

    final isValid = notifier.validateCurrentStep();
    final state = container.read(kolabFormProvider);

    expect(isValid, isFalse);
    expect(state.fieldErrors['title'], 'Title is required');
    expect(state.fieldErrors['description'], 'Description is required');
  });

  test('kolab media serializes using the api photo type', () {
    final kolab = Kolab.empty(IntentType.venuePromotion).copyWith(
      media: const [
        KolabMedia(
          url: 'https://storage.kolabing.com/kolabs/img1.jpg',
          type: 'photo',
          sortOrder: 0,
        ),
      ],
    );

    final json = kolab.toJson();
    final media = json['media'] as List<dynamic>;
    final first = media.first as Map<String, dynamic>;

    expect(first['type'], 'photo');
  });

  test('venue promotion prefills primary venue from business onboarding', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final onboarding = container.read(onboardingProvider.notifier)
      ..initialize(UserType.business)
      ..updateLocation(
        const PlaceSuggestion(
          placeId: 'place-123',
          title: 'Sol Studio',
          formattedAddress: 'Carrer de Mallorca 1, Barcelona',
          city: 'Barcelona',
          country: 'Spain',
        ),
      )
      ..updateVenueName('Sol Studio Rooftop')
      ..updateVenueType('cafe')
      ..updateVenueCapacity(120);

    expect(onboarding, isNotNull);

    container.read(kolabFormProvider.notifier).selectIntent(
          IntentType.venuePromotion,
        );

    final state = container.read(kolabFormProvider);

    expect(state.kolab.venueName, 'Sol Studio Rooftop');
    expect(state.kolab.venueType, VenueType.cafe);
    expect(state.kolab.capacity, 120);
    expect(state.kolab.venueAddress, 'Carrer de Mallorca 1, Barcelona');
    expect(state.kolab.preferredCity, 'Barcelona');
  });
}
