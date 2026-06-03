import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/enums/need_type.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/kolab/screens/community/logistics_screen.dart';
import 'package:kolabing_app/features/onboarding/models/city.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';

void main() {
  testWidgets('logistics screen hides venue preference input by default', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        citiesProvider.overrideWith(
          (ref) async => const [
            OnboardingCity(id: '1', name: 'Barcelona', country: 'Spain'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(kolabFormProvider.notifier)
        .selectIntent(IntentType.communitySeeking);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: LogisticsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Venue Preference'), findsNothing);
    expect(find.text('Business Provides'), findsNothing);
    expect(find.text('Community Provides'), findsNothing);
    expect(find.text('No Venue Needed'), findsNothing);
    expect(find.text('Preferred City'), findsOneWidget);
    expect(
      find.text('Preferred Neighbourhood / Area (optional)'),
      findsOneWidget,
    );
  });

  testWidgets(
    'logistics screen keeps venue preference hidden even when venue is needed',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          citiesProvider.overrideWith(
            (ref) async => const [
              OnboardingCity(id: '1', name: 'Barcelona', country: 'Spain'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(kolabFormProvider.notifier)
        ..selectIntent(IntentType.communitySeeking)
        ..updateNeeds(const [NeedType.venue, NeedType.sponsor]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: LogisticsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Venue Preference'), findsNothing);
      expect(find.text('Business Provides'), findsNothing);
      expect(find.text('Community Provides'), findsNothing);
    },
  );
}
