import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/missions/models/mission.dart';

void main() {
  test('treats mission as completed when completed_at is set but completed key is missing', () {
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
  });
}
