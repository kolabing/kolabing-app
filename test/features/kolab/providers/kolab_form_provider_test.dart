import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/kolab/enums/deliverable_type.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/enums/need_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

void main() {
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
      offersInReturn: const [DeliverableType.socialMedia],
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
  });
}
