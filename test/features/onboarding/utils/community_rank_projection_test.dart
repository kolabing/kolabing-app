import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/onboarding/models/community_rank.dart';
import 'package:kolabing_app/features/onboarding/utils/community_rank_projection.dart';

void main() {
  // Daniel's example in spec cbdffbbe: #13, 0 pts -> one kolab + 20
  // check-ins (80 pts) jumps to ~#6.
  const specExampleRank = CommunityRank(
    city: 'Barcelona',
    rank: 13,
    total: 40,
    points: 0,
    divisionLabel: 'Medium',
    level: 'new',
    preview: [
      CommunityRankRow(
        rank: 1,
        profileId: 'p1',
        displayName: 'Top One',
        points: 500,
        isViewer: false,
      ),
      CommunityRankRow(
        rank: 2,
        profileId: 'p2',
        displayName: 'Top Two',
        points: 300,
        isViewer: false,
      ),
      CommunityRankRow(
        rank: 3,
        profileId: 'p3',
        displayName: 'Top Three',
        points: 200,
        isViewer: false,
      ),
      CommunityRankRow(
        rank: 5,
        profileId: 'p5',
        displayName: 'Neighbour Above',
        points: 90,
        isViewer: false,
      ),
      CommunityRankRow(
        rank: 6,
        profileId: 'p6',
        displayName: 'Neighbour Below',
        points: 70,
        isViewer: false,
      ),
      CommunityRankRow(
        rank: 13,
        profileId: 'me',
        displayName: 'Me',
        points: 0,
        isViewer: true,
      ),
    ],
  );

  group('projectedPoints', () {
    test(
      'one kolab with 0 check-ins is 40 pts (kolab weight only)',
      () => expect(projectedPoints(specExampleRank, 0), 40),
    );

    test(
      'one kolab with 20 check-ins is 80 pts, matching the backend weights '
      '(40/kolab + 2/check-in)',
      () => expect(projectedPoints(specExampleRank, 20), 80),
    );
  });

  group('projectedRank', () {
    test('80 pts overtakes the 70-pt neighbour and lands at their rank + 1', () {
      // 80 >= 70 (rank 6) but 80 < 90 (rank 5), so the closest blocker still
      // ahead is rank 5 -> land at rank 6.
      expect(projectedRank(specExampleRank, 80), 6);
    });

    test('a smaller projection that clears nobody keeps the current rank', () {
      expect(projectedRank(specExampleRank, 10), 13);
    });

    test('a projection that clears every preview row reports the best shown rank', () {
      expect(projectedRank(specExampleRank, 1000), 1);
    });

    test('an empty preview window falls back to the current rank', () {
      const noPreview = CommunityRank(
        city: 'Barcelona',
        rank: 13,
        total: 40,
        points: 0,
        divisionLabel: 'Medium',
        level: 'new',
        preview: [],
      );
      expect(projectedRank(noPreview, 80), 13);
    });
  });
}
