import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/widgets/selection_card.dart';

void main() {
  testWidgets('disabled attendee card shows coming soon and ignores taps', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionCard(
            userType: SelectionUserType.attendee,
            isEnabled: false,
            badgeLabel: 'COMING SOON',
            descriptionOverride:
                'Event discovery and check-ins are coming soon',
            onTap: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.text("I'M AN ATTENDEE"), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(
      find.text('Event discovery and check-ins are coming soon'),
      findsOneWidget,
    );

    await tester.tap(find.byType(SelectionCard));
    await tester.pumpAndSettle();

    expect(tapCount, 0);
  });
}
