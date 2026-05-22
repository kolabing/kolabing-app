import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 800)),
        child: MaterialApp(
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
    );

    for (final label in ['VIEW', 'EDIT', 'CLOSE']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
      expect(text.overflow, TextOverflow.fade);
    }
  });
}
