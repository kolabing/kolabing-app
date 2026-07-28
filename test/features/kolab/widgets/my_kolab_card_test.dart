import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/widgets/my_kolab_card.dart';

void main() {
  testWidgets('action labels stay on a single line on compact widths', (
    tester,
  ) async {
    final kolab = Kolab.empty(IntentType.communitySeeking).copyWith(
      id: 'kolab-42',
      status: 'published',
      title: 'Sunday Run',
      preferredCity: 'Barcelona',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(size: Size(320, 800)),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: MyKolabCard(
                  kolab: kolab,
                  onView: () {},
                  onEdit: () {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // For a published kolab, only VIEW is rendered as a text button.
    // EDIT and CLOSE are secondary icon-only buttons (no text label).
    // The button wraps its label in a FittedBox(scaleDown) rather than
    // fading/ellipsis-truncating — the whole icon+label group shrinks
    // together instead of clipping, so there's no separate Text.overflow to
    // assert here (see KolabingButton._buildButton).
    final text = tester.widget<Text>(find.text('VIEW'));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    expect(find.byType(FittedBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long title, many chips and many actions do not overflow at 320px',
    (tester) async {
      final kolab = Kolab.empty(IntentType.communitySeeking).copyWith(
        id: 'kolab-99',
        status: 'published',
        title:
            'Sunday Morning Community Run Through Ciutadella Park And Beach Promenade',
        preferredCity: 'Barcelona',
        availabilityStart: DateTime(2026, 6, 14),
        availabilityEnd: DateTime(2026, 6, 28),
        communityTypes: const ['sports_club', 'wellness'],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(size: Size(320, 800)),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SizedBox(
                  width: 320,
                  child: MyKolabCard(
                    kolab: kolab,
                    onView: () {},
                    onEdit: () {},
                    onClose: () {},
                    onDelete: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Title is truncated to 2 lines.
      final titleText = tester.widget<Text>(find.text(kolab.title));
      expect(titleText.maxLines, 2);
      expect(titleText.overflow, TextOverflow.ellipsis);
    },
  );
}
