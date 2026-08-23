import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/category_style.dart';
import 'package:kolabing_app/config/theme/color_tokens.dart';

void main() {
  group('canonicalKey', () {
    test('casing does not matter', () {
      expect(CategoryStyleResolver.canonicalKey('Sports'), 'sports');
      expect(CategoryStyleResolver.canonicalKey('sports'), 'sports');
      expect(CategoryStyleResolver.canonicalKey('SPORTS'), 'sports');
      expect(CategoryStyleResolver.canonicalKey('  Sports  '), 'sports');
    });

    test('separators and ampersands normalise to the same key', () {
      const variants = <String>[
        'Food & Drink',
        'food & drink',
        'Food And Drink',
        'food_and_drink',
        'food-and-drink',
        'FOOD  AND   DRINK',
      ];
      for (final v in variants) {
        expect(
          CategoryStyleResolver.canonicalKey(v),
          'food and drink',
          reason: v,
        );
      }
    });

    test('apostrophes collapse rather than split', () {
      expect(
        CategoryStyleResolver.canonicalKey("Women's Group"),
        'womens group',
      );
      expect(
        CategoryStyleResolver.canonicalKey('womens_group'),
        'womens group',
      );
      expect(
        CategoryStyleResolver.canonicalKey('WOMEN’S GROUP'),
        'womens group',
      );
    });

    test('empty and symbol-only input never throws', () {
      expect(CategoryStyleResolver.canonicalKey(''), '');
      expect(CategoryStyleResolver.canonicalKey('   '), '');
      expect(CategoryStyleResolver.canonicalKey('---'), '');
    });
  });

  group('bucketFor', () {
    /// The regression this fallback exists for: the `.contains(...)` matchers
    /// that used to live in the card widgets coloured compound labels, and the
    /// exact-match-only resolver that replaced them sent every one of them to
    /// neutral grey.
    test('compound labels resolve to the head noun', () {
      expect(
        CategoryStyleResolver.bucketFor('Fitness Community'),
        isNot(CategoryBucket.unknown),
      );
      expect(
        CategoryStyleResolver.bucketFor('Sports Facility'),
        CategoryBucket.sports,
      );
      expect(
        CategoryStyleResolver.bucketFor('Run Club'),
        CategoryStyleResolver.bucketFor('running'),
      );
    });

    /// Word-level rather than substring, so a longer word that merely contains
    /// a keyword is not miscoloured.
    test('a keyword inside a longer word does not match', () {
      expect(CategoryStyleResolver.bucketFor('party'), CategoryBucket.unknown);
      expect(
        CategoryStyleResolver.bucketFor('barbershop'),
        CategoryBucket.unknown,
      );
    });

    test('spelling variants land in the same bucket', () {
      for (final v in <String>['Sports', 'sports', 'SPORTS']) {
        expect(CategoryStyleResolver.bucketFor(v), CategoryBucket.sports);
      }
      for (final v in <String>[
        'Food & Drink',
        'Food And Drink',
        'food_and_drink',
        'food-and-drink',
      ]) {
        expect(
          CategoryStyleResolver.bucketFor(v),
          CategoryBucket.foodAndDrink,
          reason: v,
        );
      }
    });

    test('each requested bucket is reachable', () {
      expect(
        CategoryStyleResolver.bucketFor('Wellness'),
        CategoryBucket.wellness,
      );
      expect(
        CategoryStyleResolver.bucketFor('Creative'),
        CategoryBucket.creative,
      );
      expect(
        CategoryStyleResolver.bucketFor("Women's Group"),
        CategoryBucket.womensGroup,
      );
      expect(
        CategoryStyleResolver.bucketFor('Business'),
        CategoryBucket.businessVenue,
      );
      expect(
        CategoryStyleResolver.bucketFor('Venue'),
        CategoryBucket.businessVenue,
      );
    });

    test('unknown / new backend values fall back to neutral, never throw', () {
      for (final v in <String>[
        '',
        'Quantum Basket Weaving',
        'some_new_backend_category',
        '🎈',
        'sportsball',
      ]) {
        expect(
          CategoryStyleResolver.bucketFor(v),
          CategoryBucket.unknown,
          reason: v,
        );
      }
    });

    test('unrelated labels sharing a substring are not merged', () {
      // "bar" is food & drink, "barber" is not silently merged into it.
      expect(
        CategoryStyleResolver.bucketFor('Bar'),
        CategoryBucket.foodAndDrink,
      );
      expect(
        CategoryStyleResolver.bucketFor('Barbershop'),
        CategoryBucket.unknown,
      );
    });
  });

  group('styleFor', () {
    test('resolves distinct colours per bucket in light mode', () {
      const c = KolabingColorTokens.light;
      expect(
        CategoryStyleResolver.styleFor('Sports', c).background,
        c.categoryChipSportsBg,
      );
      expect(
        CategoryStyleResolver.styleFor('Food & Drink', c).foreground,
        c.categoryChipFoodText,
      );
      expect(
        CategoryStyleResolver.styleFor('nonsense', c).background,
        c.categoryChipNeutralBg,
      );
    });

    test('every bucket resolves a non-transparent pair in both themes', () {
      for (final tokens in <KolabingColorTokens>[
        KolabingColorTokens.light,
        KolabingColorTokens.night,
      ]) {
        for (final bucket in CategoryBucket.values) {
          final style = CategoryStyleResolver.styleForBucket(bucket, tokens);
          expect(style.background.a, 1.0, reason: '$bucket');
          expect(style.foreground.a, 1.0, reason: '$bucket');
          expect(style.background, isNot(style.foreground), reason: '$bucket');
        }
      }
    });
  });
}
