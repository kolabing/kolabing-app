import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/widgets/profile_link.dart';

/// The invariant worth pinning is the *absence* of a tap target, not the
/// navigation: a free business sees a community's name and logo blurred and must
/// not reach the profile behind them (ROLES §2.5). A blurred identity that still
/// ripples under the finger tells the viewer exactly what the blur is hiding and
/// that it is one tap away.
Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  ),
);

void main() {
  testWidgets('links the identity when there is somewhere to go', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const ProfileLink(
        profileId: 'profile-1',
        child: Text("Daniel's Community"),
      ),
    );

    expect(find.text("Daniel's Community"), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('the paywall veto removes the tap target entirely', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const ProfileLink(
        profileId: 'profile-1',
        enabled: false,
        child: Text("Daniel's Community"),
      ),
    );

    // Still rendered — the free state is blur, never a hole in the page.
    expect(find.text("Daniel's Community"), findsOneWidget);
    // But not a door.
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('no ids means no tap target', (WidgetTester tester) async {
    await _pump(tester, const ProfileLink(child: Text('Unknown creator')));

    expect(find.text('Unknown creator'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('an empty id is treated as no id, not as a route', (
    WidgetTester tester,
  ) async {
    // Pushing `/profile/` would 404 and read as a broken link.
    await _pump(
      tester,
      const ProfileLink(profileId: '', communityId: '', child: Text('Partner')),
    );

    expect(find.byType(InkWell), findsNothing);
  });

  group('canOpen', () {
    test('needs at least one non-empty id', () {
      expect(ProfileLink.canOpen(), isFalse);
      expect(ProfileLink.canOpen(profileId: '', communityId: ''), isFalse);
      expect(ProfileLink.canOpen(profileId: 'p1'), isTrue);
      expect(ProfileLink.canOpen(communityId: 'c1'), isTrue);
    });
  });
}
