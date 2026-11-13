import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/chat/models/kolabing_team_offer.dart';
import 'package:kolabing_app/features/chat/models/team_claim_preview.dart';
import 'package:kolabing_app/features/chat/screens/team_claim_screen.dart';
import 'package:kolabing_app/features/chat/services/team_claim_service.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

class _FakeClaimService implements TeamClaimService {
  _FakeClaimService({this.preview_, this.error});

  final TeamClaimPreview? preview_;
  final TeamClaimException? error;

  @override
  Future<TeamClaimPreview> preview(String token) async {
    if (error != null) throw error!;
    return preview_!;
  }
}

TeamClaimPreview _preview({bool expired = false, bool claimable = true}) =>
    TeamClaimPreview(
      offer: const KolabingTeamOffer(
        id: 'o1',
        kind: 'community_apply',
        status: 'sent',
        title: 'Host your run club at Cafe Mallorca',
        message: 'We think your club fits this venue.',
      ),
      profileName: 'Poblenou Padel Crew',
      profileType: 'community',
      expired: expired,
      claimable: claimable,
    );

Widget _host(TeamClaimService service) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: TeamClaimScreen(token: 'tok', service: service),
  ),
);

void main() {
  testWidgets('the claim screen names the page, shows the offer and the '
      'delete-after-claiming line', (tester) async {
    await tester.pumpWidget(_host(_FakeClaimService(preview_: _preview())));
    await tester.pumpAndSettle();

    expect(find.textContaining('Poblenou Padel Crew'), findsOneWidget);
    expect(find.text('Host your run club at Cafe Mallorca'), findsOneWidget);
    expect(
      find.text(
        'You can delete this page whenever you like after you claim it.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('team-claim-google')), findsOneWidget);
  });

  testWidgets('an expired offer cannot be claimed and says why', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_FakeClaimService(preview_: _preview(expired: true, claimable: false))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team-claim-expired')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-claim-google')), findsNothing);
  });

  testWidgets('an unknown or used link shows the invalid message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _FakeClaimService(
          error: const TeamClaimException('nope', statusCode: 404),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team-claim-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-claim-google')), findsNothing);
  });
}
