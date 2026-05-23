import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/community/screens/create_opportunity_screen.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_form_provider.dart';
import 'package:kolabing_app/features/opportunity/utils/opportunity_share_launcher.dart';

void main() {
  testWidgets(
    'publish success uses saved opportunity and share CTA uses injected launcher',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          opportunityFormProvider.overrideWith(
            _TestOpportunityFormNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final shareLauncher = _RecordingOpportunityShareLauncher();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: CreateOpportunityScreen(
              opportunityShareLauncher: shareLauncher,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PUBLISH'), findsOneWidget);

      await tester.tap(find.text('PUBLISH'));
      await tester.pumpAndSettle();

      expect(find.text('Opportunity Published!'), findsOneWidget);
      expect(find.text('SHARE'), findsOneWidget);

      await tester.tap(find.text('SHARE'));
      await tester.pumpAndSettle();

      expect(shareLauncher.lastTitle, 'Sunset Rooftop Collab');
      expect(shareLauncher.lastOpportunityId, 'opp-42');
      expect(shareLauncher.lastSharePositionOrigin, isNotNull);
    },
  );
}

class _TestOpportunityFormNotifier extends OpportunityFormNotifier {
  static final Opportunity _draftOpportunity = Opportunity.empty().copyWith(
    title: 'Draft Title',
    description: 'Draft description',
    categories: const ['Food'],
    businessOffer: const BusinessOffer(venue: true),
    communityDeliverables: const CommunityDeliverables(
      socialMediaContent: true,
    ),
    availabilityMode: AvailabilityMode.oneTime,
    preferredCity: 'Madrid',
    status: OpportunityStatus.draft,
  );

  static final Opportunity _publishedOpportunity = _draftOpportunity.copyWith(
    id: 'opp-42',
    title: 'Sunset Rooftop Collab',
    status: OpportunityStatus.published,
  );

  @override
  OpportunityFormState build() =>
      OpportunityFormState(currentStep: 4, opportunity: _draftOpportunity);

  @override
  Future<bool> saveAndPublish() async {
    state = state.copyWith(
      isPublishing: false,
      isSuccess: true,
      opportunity: _publishedOpportunity,
    );
    return true;
  }

  @override
  void reset() {
    state = OpportunityFormState(
      currentStep: 4,
      opportunity: _draftOpportunity,
    );
  }
}

class _RecordingOpportunityShareLauncher extends OpportunityShareLauncher {
  _RecordingOpportunityShareLauncher();

  String? lastTitle;
  String? lastOpportunityId;
  Rect? lastSharePositionOrigin;

  @override
  Future<void> launchOpportunityShare({
    required String title,
    required String opportunityId,
    required OpportunityShareFallbackMessage onFallbackMessage,
    Rect? sharePositionOrigin,
  }) async {
    lastTitle = title;
    lastOpportunityId = opportunityId;
    lastSharePositionOrigin = sharePositionOrigin;
  }
}
