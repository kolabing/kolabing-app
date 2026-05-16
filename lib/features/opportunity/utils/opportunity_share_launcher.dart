import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'opportunity_share.dart';

typedef OpportunityShareInvoker =
    Future<ShareResult> Function(String text, {Rect? sharePositionOrigin});
typedef OpportunityShareCopyText = Future<void> Function(String text);
typedef OpportunityShareFallbackMessage = void Function(String message);

class OpportunityShareLauncher {
  const OpportunityShareLauncher({
    this.share = Share.share,
    this.copyText = _copyText,
  });

  final OpportunityShareInvoker share;
  final OpportunityShareCopyText copyText;

  Future<void> launchOpportunityShare({
    required String title,
    required String opportunityId,
    required OpportunityShareFallbackMessage onFallbackMessage,
    Rect? sharePositionOrigin,
  }) async {
    final opportunityUrl = buildOpportunityShareUri(opportunityId).toString();

    try {
      final result = await share(
        buildOpportunityShareMessage(
          title: title,
          opportunityId: opportunityId,
        ),
        sharePositionOrigin: sharePositionOrigin,
      );

      if (result.status == ShareResultStatus.unavailable) {
        await copyText(opportunityUrl);
        onFallbackMessage('Sharing is unavailable. Opportunity link copied.');
      }
    } on Exception {
      await copyText(opportunityUrl);
      onFallbackMessage('Could not open share sheet. Opportunity link copied.');
    }
  }

  static Future<void> _copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
