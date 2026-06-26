import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/kolab/screens/business/media_screen.dart';

Widget _wrap(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MediaScreen()),
      ),
    );

void main() {
  testWidgets('shows two choice cards when no photo is selected yet', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(kolabFormProvider.notifier).selectIntent(IntentType.productPromotion);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Upload my photo'), findsOneWidget);
    expect(find.text('Use default cover'), findsOneWidget);
    expect(
      find.text('Kolabs need a cover image. You can upload your own or use a Kolabing default.'),
      findsOneWidget,
    );
    // No hard error shown on initial load.
    expect(find.text('Add at least 1 photo'), findsNothing);

    // The "Use default cover" card shows a local preview thumbnail of the
    // bundled default-cover asset for the active intent type.
    final previewImage = tester.widgetList<Image>(find.byType(Image)).firstWhere(
          (image) => (image.image as AssetImage).assetName ==
              'assets/images/defaults/product_cover_1.png',
        );
    expect(previewImage, isNotNull);
  });

  testWidgets('tapping "Use default cover" adds a badged default photo and hides the choice cards', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(kolabFormProvider.notifier).selectIntent(IntentType.venuePromotion);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use default cover'));
    await tester.pumpAndSettle();

    expect(find.text('Upload my photo'), findsNothing);
    expect(find.text('Use default cover'), findsNothing);
    expect(find.text('Default'), findsOneWidget);
    expect(container.read(kolabFormProvider).kolab.media.single.isDefaultCover, isTrue);
  });
}
