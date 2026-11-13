import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolabing_app/features/chat/services/pending_team_link.dart';

void main() {
  const route = '/team-offer/0191a2b3-c4d5-7e6f-8a9b-0c1d2e3f4a5b';

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('only a team offer route can be parked', () async {
    await PendingTeamLink.save('/settings/delete-account');
    expect(await PendingTeamLink.take(), isNull);

    await PendingTeamLink.save('/team-offer/../../admin');
    expect(await PendingTeamLink.take(), isNull);
  });

  test('a parked route comes back once', () async {
    await PendingTeamLink.save(route);

    expect(await PendingTeamLink.take(), route);
    expect(await PendingTeamLink.take(), isNull);
  });

  test('a tampered stored value is dropped, not opened', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pending_team_link_route': '/profile/delete',
    });

    expect(await PendingTeamLink.take(), isNull);
  });
}
