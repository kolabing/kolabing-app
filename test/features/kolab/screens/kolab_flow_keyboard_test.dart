import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/kolab/screens/kolab_flow_screen.dart';

void main() {
  testWidgets(
    'tapping outside an input dismisses the keyboard in the kolab flow',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(kolabFormProvider.notifier)
          .selectIntent(IntentType.venuePromotion);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KolabFlowScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.pump();

      final editableTextFinder = find.byType(EditableText).first;
      expect(
        tester.widget<EditableText>(editableTextFinder).focusNode.hasFocus,
        isTrue,
      );

      await tester.tap(find.text('PROMOTION DETAILS'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(editableTextFinder).focusNode.hasFocus,
        isFalse,
      );
    },
  );
}
