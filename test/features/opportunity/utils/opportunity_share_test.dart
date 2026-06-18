import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/environment.dart';
import 'package:kolabing_app/features/opportunity/utils/opportunity_share.dart';

void main() {
  // Host comes from config (flavor-dependent), not a hardcoded literal.
  const shareHost = Environment.shareHost;

  test('buildOpportunitySharePath returns the canonical in-app path', () {
    expect(buildOpportunitySharePath('opp-42'), '/c/opp-42');
  });

  test('buildOpportunitySharePath appends apply=1 when requested', () {
    expect(
      buildOpportunitySharePath('opp-42', apply: true),
      '/c/opp-42?apply=1',
    );
  });

  test('buildOpportunityShareUri returns the canonical web URI', () {
    expect(
      buildOpportunityShareUri('opp-42'),
      Uri.parse('https://$shareHost/c/opp-42'),
    );
  });

  test('buildOpportunityShareUri appends apply=1 when requested', () {
    expect(
      buildOpportunityShareUri('opp-42', apply: true),
      Uri.parse('https://$shareHost/c/opp-42?apply=1'),
    );
  });

  test('buildOpportunityShareMessage includes the title and web URL', () {
    expect(
      buildOpportunityShareMessage(
        title: 'Sunset Rooftop Collab',
        opportunityId: 'opp-42',
      ),
      'Check out "Sunset Rooftop Collab" on Kolabing: '
      'https://$shareHost/c/opp-42',
    );
  });
}
