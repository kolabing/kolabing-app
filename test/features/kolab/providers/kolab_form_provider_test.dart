import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/enums/need_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

class _TestProfileNotifier extends ProfileNotifier {
  @override
  ProfileState build() =>
      const ProfileState(isLoading: false, isInitialized: true);
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initForEdit loads an existing kolab into the form state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final kolab = Kolab(
      id: 'kolab-42',
      intentType: IntentType.communitySeeking,
      status: 'draft',
      title: 'Barcelona Brunch Club',
      description: 'Looking for a coffee partner for our founder meetup.',
      preferredCity: 'Barcelona',
      needs: const [NeedType.sponsor],
      communityTypes: const ['Founders'],
      communitySize: 120,
      typicalAttendance: 45,
      offersInReturn: const ['social_media'],
      media: const [
        KolabMedia(url: 'https://example.com/photo.jpg', type: 'photo'),
      ],
      availabilityMode: AvailabilityMode.oneTime,
      availabilityStart: DateTime(2026, 5, 10),
      availabilityEnd: DateTime(2026, 5, 10),
      selectedTime: const TimeOfDay(hour: 19, minute: 30),
    );

    container.read(kolabFormProvider.notifier).initForEdit(kolab);

    final state = container.read(kolabFormProvider);
    expect(state.isEditing, isTrue);
    expect(state.intentType, IntentType.communitySeeking);
    expect(state.totalSteps, IntentType.communitySeeking.totalSteps);
    expect(state.currentStep, 0);
    expect(state.kolab.id, 'kolab-42');
    expect(state.kolab.title, 'Barcelona Brunch Club');
    expect(state.kolab.media.single.url, 'https://example.com/photo.jpg');
    expect(state.kolab.venuePreference, VenuePreference.noVenue);
  });

  group('community seeking logistics validation', () {
    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(_TestProfileNotifier.new),
          authProvider.overrideWith(_TestAuthNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    KolabFormNotifier buildCommunitySeekingNotifier(
      ProviderContainer container,
    ) {
      final notifier = container.read(kolabFormProvider.notifier)
        ..selectIntent(IntentType.communitySeeking)
        ..goToStep(3);
      return notifier;
    }

    test('one-time mode requires start, end, and time', () {
      final container = createContainer();
      final notifier = buildCommunitySeekingNotifier(container)
        ..updateAvailabilityMode(AvailabilityMode.oneTime)
        ..updatePreferredCity('Barcelona');

      expect(notifier.validateCurrentStep(), isFalse);
      expect(container.read(kolabFormProvider).fieldErrors, {
        'availability_start': 'Pick a start date for your availability window',
        'availability_end': 'Pick an end date for your availability window',
        'selected_time': 'Select a time for your availability',
      });
    });

    test('recurring mode requires at least one recurring day and time', () {
      final container = createContainer();
      final notifier = buildCommunitySeekingNotifier(container)
        ..updateAvailabilityMode(AvailabilityMode.recurring)
        ..updatePreferredCity('Barcelona');

      expect(notifier.validateCurrentStep(), isFalse);
      expect(container.read(kolabFormProvider).fieldErrors, {
        'recurring_day': 'Select at least 1 recurring day',
        'selected_time': 'Select a time for your availability',
      });
    });

    test('legacy flexible edit normalizes to one-time mode', () {
      final container = createContainer();
      final legacyKolab = Kolab.empty(IntentType.communitySeeking).copyWith(
        availabilityMode: AvailabilityMode.fromString('flexible'),
        availabilityStart: DateTime(2026, 5, 20),
        availabilityEnd: DateTime(2026, 5, 21),
      );

      container.read(kolabFormProvider.notifier).initForEdit(legacyKolab);

      expect(
        container.read(kolabFormProvider).kolab.availabilityMode,
        AvailabilityMode.oneTime,
      );
    });

    test('all logistics modes still require preferred city', () {
      final modes = <AvailabilityMode, void Function(KolabFormNotifier)>{
        AvailabilityMode.oneTime: (notifier) {
          notifier
            ..updateAvailabilityStart(DateTime(2026, 5, 20))
            ..updateAvailabilityEnd(DateTime(2026, 5, 21))
            ..updateSelectedTime(const TimeOfDay(hour: 18, minute: 0));
        },
        AvailabilityMode.recurring: (notifier) {
          notifier
            ..toggleRecurringDay(1)
            ..updateSelectedTime(const TimeOfDay(hour: 18, minute: 0));
        },
      };

      for (final entry in modes.entries) {
        final container = createContainer();
        final notifier = buildCommunitySeekingNotifier(container)
          ..updateAvailabilityMode(entry.key);
        entry.value(notifier);

        expect(notifier.validateCurrentStep(), isFalse);
        expect(container.read(kolabFormProvider).fieldErrors, {
          'preferred_city': 'Preferred city is required',
        });
      }
    });

    test('venue need no longer blocks publish in the community flow', () {
      final container = createContainer();
      final notifier = buildCommunitySeekingNotifier(container)
        ..updateNeeds(const [NeedType.venue])
        ..updateAvailabilityMode(AvailabilityMode.oneTime)
        ..updateAvailabilityStart(DateTime(2026, 5, 20))
        ..updateAvailabilityEnd(DateTime(2026, 5, 21))
        ..updateSelectedTime(const TimeOfDay(hour: 18, minute: 0))
        ..updatePreferredCity('Barcelona');

      expect(notifier.validateCurrentStep(), isTrue);
      expect(container.read(kolabFormProvider).fieldErrors, isEmpty);
      expect(
        container.read(kolabFormProvider).kolab.venuePreference,
        VenuePreference.noVenue,
      );
    });

    test('non-venue needs default venue preference to no venue', () {
      final container = createContainer();
      container.read(kolabFormProvider.notifier)
        ..selectIntent(IntentType.communitySeeking)
        ..updateNeeds(const [NeedType.sponsor]);

      expect(
        container.read(kolabFormProvider).kolab.venuePreference,
        VenuePreference.noVenue,
      );
    });
  });
}
