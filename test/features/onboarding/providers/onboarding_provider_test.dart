import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/onboarding/models/business_type.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';

void main() {
  test('business onboarding caps selected categories at three', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(onboardingProvider.notifier);
    notifier.initialize(UserType.business);

    const types = [
      BusinessType(id: '1', name: 'Cafe', slug: 'cafe'),
      BusinessType(id: '2', name: 'Coworking', slug: 'coworking'),
      BusinessType(id: '3', name: 'Events', slug: 'events'),
      BusinessType(id: '4', name: 'Retail', slug: 'retail'),
    ];

    notifier.toggleBusinessType(types[0]);
    notifier.toggleBusinessType(types[1]);
    notifier.toggleBusinessType(types[2]);
    notifier.toggleBusinessType(types[3]);

    final state = container.read(onboardingProvider)!;

    expect(state.businessTypeIds, ['1', '2', '3']);
    expect(state.businessTypeSlugs, ['cafe', 'coworking', 'events']);
    expect(state.businessTypeNames, ['Cafe', 'Coworking', 'Events']);
  });
}
