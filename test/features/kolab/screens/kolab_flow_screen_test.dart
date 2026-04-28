import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/kolab/screens/kolab_flow_screen.dart';

void main() {
  testWidgets(
    'kolab flow shows the paywall when publishing requires a subscription',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [kolabFormProvider.overrideWith(_TestKolabFormNotifier.new)],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(kolabFormProvider.notifier) as _TestKolabFormNotifier;
      notifier.selectIntent(IntentType.communitySeeking);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: KolabFlowScreen()),
        ),
      );

      await tester.pumpAndSettle();

      notifier.requireSubscription();
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(
        find.textContaining('Subscribe to create unlimited requests'),
        findsOneWidget,
      );
    },
  );
}

class _TestKolabFormNotifier extends KolabFormNotifier {
  void requireSubscription() {
    state = state.copyWith(requiresSubscription: true);
  }
}
