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

  group('Kolab expects/offersInReturn (dynamic deliverable slugs)', () {
    test('expects and offersInReturn round-trip as plain slug strings', () {
      final kolab = Kolab.empty(IntentType.venuePromotion).copyWith(
        expects: ['tagged_stories', 'minimum_attendance'],
        offersInReturn: ['social_media'],
      );

      final json = kolab.toJson();
      expect(json['expects'], ['tagged_stories', 'minimum_attendance']);
      expect(json['offers_in_return'], ['social_media']);

      final parsed = Kolab.fromJson(json);
      expect(parsed.expects, ['tagged_stories', 'minimum_attendance']);
      expect(parsed.offersInReturn, ['social_media']);
    });

    test('an unrecognized deliverable slug round-trips unchanged, never miscoded', () {
      // A slug the app has never seen (e.g. a brand-new admin-added option)
      // must survive parsing untouched -- not silently collapse to some
      // other option's slug.
      final kolab = Kolab.fromJson(const {
        'expects': ['brand_new_admin_option'],
        'offers_in_return': ['another_unknown_option'],
      });

      expect(kolab.expects, ['brand_new_admin_option']);
      expect(kolab.offersInReturn, ['another_unknown_option']);
    });
  });
}
