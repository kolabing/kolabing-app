import '../../../config/environment.dart';

const String _kolabingShareHost = Environment.shareHost;

String buildOpportunitySharePath(String opportunityId, {bool apply = false}) =>
    Uri(
      path: '/c/$opportunityId',
      queryParameters: apply ? const <String, String>{'apply': '1'} : null,
    ).toString();

Uri buildOpportunityShareUri(String opportunityId, {bool apply = false}) =>
    Uri.https(
      _kolabingShareHost,
      '/c/$opportunityId',
      apply ? const <String, String>{'apply': '1'} : null,
    );

String buildOpportunityShareMessage({
  required String title,
  required String opportunityId,
}) =>
    'Check out "$title" on Kolabing: '
    '${buildOpportunityShareUri(opportunityId)}';
