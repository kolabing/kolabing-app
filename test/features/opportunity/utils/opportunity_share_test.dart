import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/opportunity/utils/opportunity_share.dart';

void main() {
  test('buildOpportunitySharePath returns the canonical in-app path', () {
    expect(buildOpportunitySharePath('opp-42'), '/c/opp-42');
  });

  test('buildOpportunitySharePath appends apply=1 when requested', () {
    expect(
      buildOpportunitySharePath('opp-42', apply: true),
      '/c/opp-42?apply=1',
    );
  });

  test('buildOpportunityShareMessage includes the title and web URL', () {
    expect(
      buildOpportunityShareMessage(
        title: 'Sunset Rooftop Collab',
        opportunityId: 'opp-42',
      ),
      'Check out "Sunset Rooftop Collab" on Kolabing: '
      'https://kolabing.com/c/opp-42',
    );
  });
}
