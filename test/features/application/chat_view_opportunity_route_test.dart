import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/application/screens/chat_screen.dart';

void main() {
  group('chatViewOpportunityRoute', () {
    test(
      'creator (business) opens the application submission, not the offer',
      () {
        final route = chatViewOpportunityRoute(
          viewerIsCreator: true,
          applicationId: 'app-1',
          opportunityId: 'opp-9',
        );
        // ApplicationReviewScreen — community's submission, no "Apply now" CTA.
        expect(route, '/application/app-1');
      },
    );

    test('applicant (community) opens the offer they applied to', () {
      final route = chatViewOpportunityRoute(
        viewerIsCreator: false,
        applicationId: 'app-1',
        opportunityId: 'opp-9',
      );
      expect(route, '/community/explore/offer/opp-9');
    });
  });
}
