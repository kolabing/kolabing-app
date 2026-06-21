import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/onboarding_state.dart';

void main() {
  group('OnboardingData.missingFields', () {
    test('empty community lists name, type and city', () {
      const data = OnboardingData(userType: UserType.community);
      expect(data.missingFields, [
        OnboardingField.name,
        OnboardingField.communityType,
        OnboardingField.communityCity,
      ]);
      expect(data.isComplete, isFalse);
    });

    test('complete community has no missing fields', () {
      const data = OnboardingData(
        userType: UserType.community,
        name: 'Real Run Club',
        type: 'running',
        cityId: 'bcn',
      );
      expect(data.missingFields, isEmpty);
      expect(data.isComplete, isTrue);
    });

    test('community missing only the city names the city', () {
      const data = OnboardingData(
        userType: UserType.community,
        name: 'Real Run Club',
        type: 'running',
      );
      expect(data.missingFields, [OnboardingField.communityCity]);
    });

    test(
      'empty venue business lists address, name, category, venue + photos',
      () {
        const data = OnboardingData(
          userType: UserType.business,
          hasVenue: true,
        );
        expect(
          data.missingFields,
          containsAll(<OnboardingField>[
            OnboardingField.businessAddress,
            OnboardingField.name,
            OnboardingField.businessCategory,
            OnboardingField.venueType,
            OnboardingField.venueCapacity,
            OnboardingField.venuePhotos,
          ]),
        );
      },
    );

    test('product business (no venue) lists name, category and cities', () {
      const data = OnboardingData(userType: UserType.business, hasVenue: false);
      expect(data.missingFields, [
        OnboardingField.name,
        OnboardingField.businessCategory,
        OnboardingField.targetCities,
      ]);
    });

    test('missingFields is empty exactly when isComplete is true', () {
      const incomplete = OnboardingData(userType: UserType.community);
      expect(incomplete.missingFields.isEmpty, incomplete.isComplete);
    });
  });
}
