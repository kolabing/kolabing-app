import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/missions/models/mission.dart';

void main() {
  test(
    'treats mission as completed when completed_at is set but completed key is missing',
    () {
      final mission = Mission.fromJson({
        'id': '1',
        'slug': 'test-mission',
        'name': 'Test',
        'category': 'onboarding',
        'points': 10,
        'target_value': 1,
        'progress_count': 1,
        'completed_at': '2026-06-20T10:00:00Z',
      });

      expect(mission.completed, isTrue);
    },
  );

  test(
    'treats mission as completed when completed is literally true and completed_at is absent',
    () {
      final mission = Mission.fromJson({
        'id': '1',
        'slug': 'test-mission',
        'name': 'Test',
        'category': 'onboarding',
        'points': 10,
        'target_value': 1,
        'progress_count': 1,
        'completed': true,
      });

      expect(mission.completed, isTrue);
    },
  );

  test(
    'treats mission as not completed when both completed and completed_at are absent',
    () {
      final mission = Mission.fromJson({
        'id': '1',
        'slug': 'test-mission',
        'name': 'Test',
        'category': 'onboarding',
        'points': 10,
        'target_value': 1,
        'progress_count': 0,
      });

      expect(mission.completed, isFalse);
    },
  );

  test(
    'treats mission as not completed when completed_at is unparseable and completed is absent',
    () {
      final mission = Mission.fromJson({
        'id': '1',
        'slug': 'test-mission',
        'name': 'Test',
        'category': 'onboarding',
        'points': 10,
        'target_value': 1,
        'progress_count': 0,
        'completed_at': 'soon',
      });

      expect(mission.completed, isFalse);
    },
  );
}
