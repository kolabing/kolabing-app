import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/widgets/kolab_review_card.dart';

void main() {
  testWidgets('community review card does not show venue preference', (
    WidgetTester tester,
  ) async {
    final kolab = Kolab.empty(IntentType.communitySeeking).copyWith(
      preferredCity: 'Barcelona',
      area: 'Gracia',
      venuePreference: VenuePreference.businessProvides,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 800,
                child: KolabReviewCard(kolab: kolab, onEditSection: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Venue'), findsNothing);
    expect(find.text('Business Provides'), findsNothing);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
  });

  testWidgets('community review card humanizes underscored community tags', (
    WidgetTester tester,
  ) async {
    final kolab = Kolab.empty(
      IntentType.communitySeeking,
    ).copyWith(communityTypes: const ['Run_Club']);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 800,
                child: KolabReviewCard(kolab: kolab, onEditSection: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Run Club'), findsOneWidget);
    expect(find.text('Run_Club'), findsNothing);
  });
}
