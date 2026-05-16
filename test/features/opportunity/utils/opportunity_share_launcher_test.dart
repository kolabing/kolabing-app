import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/opportunity/utils/opportunity_share_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  test('launchOpportunityShare shares the canonical message', () async {
    var sharedMessage = '';
    Rect? sharedOrigin;
    var copiedText = '';
    String? fallbackMessage;

    final launcher = OpportunityShareLauncher(
      share: (String text, {Rect? sharePositionOrigin}) async {
        sharedMessage = text;
        sharedOrigin = sharePositionOrigin;
        return const ShareResult('shared', ShareResultStatus.success);
      },
      copyText: (String text) async {
        copiedText = text;
      },
    );

    const shareOrigin = Rect.fromLTWH(10, 20, 30, 40);

    await launcher.launchOpportunityShare(
      title: 'Sunset Rooftop Collab',
      opportunityId: 'opp-42',
      sharePositionOrigin: shareOrigin,
      onFallbackMessage: (String message) {
        fallbackMessage = message;
      },
    );

    expect(
      sharedMessage,
      'Check out "Sunset Rooftop Collab" on Kolabing: '
      'https://kolabing.com/c/opp-42',
    );
    expect(sharedOrigin, shareOrigin);
    expect(copiedText, isEmpty);
    expect(fallbackMessage, isNull);
  });

  test('launchOpportunityShare copies URL when share is unavailable', () async {
    var copiedText = '';
    String? fallbackMessage;

    final launcher = OpportunityShareLauncher(
      share: (String text, {Rect? sharePositionOrigin}) async =>
          ShareResult.unavailable,
      copyText: (String text) async {
        copiedText = text;
      },
    );

    await launcher.launchOpportunityShare(
      title: 'Sunset Rooftop Collab',
      opportunityId: 'opp-42',
      onFallbackMessage: (String message) {
        fallbackMessage = message;
      },
    );

    expect(copiedText, 'https://kolabing.com/c/opp-42');
    expect(fallbackMessage, 'Sharing is unavailable. Opportunity link copied.');
  });

  test('launchOpportunityShare copies URL when share throws', () async {
    var copiedText = '';
    String? fallbackMessage;

    final launcher = OpportunityShareLauncher(
      share: (String text, {Rect? sharePositionOrigin}) async {
        throw Exception('share failed');
      },
      copyText: (String text) async {
        copiedText = text;
      },
    );

    await launcher.launchOpportunityShare(
      title: 'Sunset Rooftop Collab',
      opportunityId: 'opp-42',
      onFallbackMessage: (String message) {
        fallbackMessage = message;
      },
    );

    expect(copiedText, 'https://kolabing.com/c/opp-42');
    expect(
      fallbackMessage,
      'Could not open share sheet. Opportunity link copied.',
    );
  });
}
