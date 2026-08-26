// Guardrails for the merged community page's leader block (#174).
//
// The old Community tab spread management down the page behind twenty separate
// `canManage` checks, so "is this row supposed to be here?" had twenty answers.
// Manage is now one block: present for a manager, absent for anyone else. These
// tests hold that line, because a management row leaking to a member is a
// permission bug, not a cosmetic one.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/community/models/community.dart';
import 'package:kolabing_app/features/community/widgets/community_manage_sections.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Community _community({int? memberCount = 12}) => Community(
  id: 'c1',
  ownerProfileId: 'owner-1',
  name: 'Real Run Club',
  slug: 'real-run-club',
  type: CommunityType.running,
  typeSlug: 'run_club',
  memberCount: memberCount,
  inviteUrl: 'https://kolabing.com/join/real-run-club',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1125, 2001); // 375x667 @3x
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: KolabingTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a manager gets every management row', (tester) async {
    await _pump(
      tester,
      CommunityManageSection(
        community: _community(),
        canManage: true,
        onOpenEvents: () {},
        onOpenRewards: () {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('MANAGE'), findsOneWidget);
    for (final key in const [
      Key('communityManageMembers'),
      Key('communityManageTiers'),
      Key('communityManageRewards'),
      Key('communityManageEvents'),
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: '$key must be offered');
    }
  });

  testWidgets('a non-manager gets no management block at all', (tester) async {
    await _pump(
      tester,
      CommunityManageSection(
        community: _community(),
        canManage: false,
        onOpenEvents: () {},
        onOpenRewards: () {},
      ),
    );

    // Absent, not merely disabled: no heading, no rows.
    expect(find.text('MANAGE'), findsNothing);
    for (final key in const [
      Key('communityManageMembers'),
      Key('communityManageTiers'),
      Key('communityManageRewards'),
      Key('communityManageEvents'),
    ]) {
      expect(find.byKey(key), findsNothing, reason: '$key must not leak');
    }
  });

  testWidgets('the action row is one full-width invite button', (tester) async {
    await _pump(tester, CommunityActionRow(community: _community()));

    expect(tester.takeException(), isNull);
    expect(find.text('Invite link'), findsOneWidget);
    // "New event" was here and came out: creating an event is not why a leader
    // opens this page, and Manage -> Events is one tap away.
    expect(find.text('New event'), findsNothing);
    // Full width, not half a row with a gap beside nothing.
    expect(
      tester.getSize(find.byType(CommunityActionRow)).width,
      greaterThan(300),
    );
  });

  testWidgets('identity names the community and its meta line', (tester) async {
    await _pump(tester, CommunityIdentity(community: _community()));

    expect(find.text('Real Run Club'), findsOneWidget);
    // `run_club` humanised, then the member count — one quiet line, not chips.
    expect(find.textContaining('Run Club'), findsWidgets);
    expect(find.textContaining('12'), findsOneWidget);
  });
}
