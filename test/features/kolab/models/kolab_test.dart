import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';

void main() {
  group('Kolab goal/highlights', () {
    test('goal and highlights round-trip through toJson/fromJson', () {
      final kolab = Kolab.empty(IntentType.venuePromotion).copyWith(
        goal: 'more_visits',
        highlights: ['good_location', 'free_samples'],
      );

      final json = kolab.toJson();
      expect(json['goal'], 'more_visits');
      expect(json['highlights'], ['good_location', 'free_samples']);

      final parsed = Kolab.fromJson(json);
      expect(parsed.goal, 'more_visits');
      expect(parsed.highlights, ['good_location', 'free_samples']);
    });

    test('goal and highlights default to null/empty and are omitted from toJson', () {
      final kolab = Kolab.empty(IntentType.venuePromotion);

      expect(kolab.goal, isNull);
      expect(kolab.highlights, isEmpty);
      expect(kolab.toJson().containsKey('goal'), isFalse);
      expect(kolab.toJson().containsKey('highlights'), isFalse);
    });
  });
}
