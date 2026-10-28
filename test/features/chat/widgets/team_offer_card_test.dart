import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/chat/models/kolabing_team_offer.dart';
import 'package:kolabing_app/features/chat/widgets/team_offer_card.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

KolabingTeamOffer _offer({String status = 'sent', bool canRespond = true}) =>
    KolabingTeamOffer(
      id: 'o1',
      kind: 'community_apply',
      status: status,
      title: 'Host your run club at Cafe Mallorca',
      venueName: 'Cafe Mallorca',
      whatCommunityGets: 'Free coffee for 30 runners',
      canRespond: canRespond,
    );

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('an open offer shows Accept and Not now, and each calls back', (
    tester,
  ) async {
    var accepted = 0;
    var declined = 0;
    await tester.pumpWidget(
      _host(
        TeamOfferCard(
          offer: _offer(),
          onAccept: () => accepted++,
          onDecline: () => declined++,
        ),
      ),
    );

    expect(find.text('Host your run club at Cafe Mallorca'), findsOneWidget);
    expect(find.text('Cafe Mallorca'), findsOneWidget);
    expect(
      find.text('The community gets: Free coffee for 30 runners'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('team-offer-accept')));
    await tester.tap(find.byKey(const ValueKey('team-offer-decline')));
    expect(accepted, 1);
    expect(declined, 1);
  });

  testWidgets('while busy neither button fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        TeamOfferCard(
          offer: _offer(),
          busy: true,
          onAccept: () => taps++,
          onDecline: () => taps++,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('team-offer-accept')),
      warnIfMissed: false,
    );
    await tester.tap(
      find.byKey(const ValueKey('team-offer-decline')),
      warnIfMissed: false,
    );
    expect(taps, 0);
  });

  testWidgets('an answered offer shows its status and no buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TeamOfferCard(
          offer: _offer(status: 'accepted', canRespond: false),
          onAccept: () {},
          onDecline: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('team-offer-accept')), findsNothing);
    expect(find.byKey(const ValueKey('team-offer-decline')), findsNothing);
    expect(find.text('Accepted'), findsOneWidget);
  });
}
