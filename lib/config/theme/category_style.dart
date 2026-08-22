import 'package:flutter/material.dart';

import 'color_tokens.dart';

/// Semantic taxonomy buckets a category label can resolve to.
///
/// These drive **taxonomy colour only**. They must never be used to express a
/// status, a CTA, a match percentage, a date, a location, or any other piece of
/// metadata — those keep their own dedicated tokens.
enum CategoryBucket {
  sports,
  foodAndDrink,
  wellness,
  creative,
  womensGroup,
  businessVenue,

  /// Fallback for unknown / new backend categories — neutral warm cream.
  unknown,
}

/// Resolved visual styling for one category chip.
@immutable
class CategoryStyle {
  const CategoryStyle({
    required this.bucket,
    required this.background,
    required this.foreground,
  });

  final CategoryBucket bucket;
  final Color background;
  final Color foreground;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryStyle &&
          other.bucket == bucket &&
          other.background == background &&
          other.foreground == foreground;

  @override
  int get hashCode => Object.hash(bucket, background, foreground);
}

/// The single place category labels are turned into a canonical key, a semantic
/// bucket, and finally colours.
///
/// This is **UI-only**: it never mutates backend values and never participates
/// in filtering or API payloads. Unknown values resolve to
/// [CategoryBucket.unknown] and never throw.
abstract final class CategoryStyleResolver {
  /// Normalises any category identifier into a canonical lookup key.
  ///
  /// `Food & Drink`, `Food And Drink`, `food_and_drink` and `food-and-drink`
  /// all normalise to `food and drink`; `Sports`/`sports`/`SPORTS` to `sports`.
  static String canonicalKey(String raw) {
    var s = raw.toLowerCase().trim();
    // Apostrophes are dropped, not spaced: "women's" -> "womens".
    s = s.replaceAll(RegExp("[’'`]"), '');
    // Ampersand reads as the word "and".
    s = s.replaceAll('&', ' and ');
    // Any other separator becomes a space.
    s = s.replaceAll(RegExp('[^a-z0-9]+'), ' ');
    return s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Explicit alias map — only clearly-equivalent spellings of the same thing.
  /// Deliberately small: anything not listed falls back to
  /// [CategoryBucket.unknown] rather than being guessed at via substring
  /// matching.
  static const Map<String, CategoryBucket> _buckets = <String, CategoryBucket>{
    // --- sports ---
    'sports': CategoryBucket.sports,
    'sport': CategoryBucket.sports,
    'fitness': CategoryBucket.sports,
    'gym': CategoryBucket.sports,
    'running': CategoryBucket.sports,
    'run': CategoryBucket.sports,
    'cycling': CategoryBucket.sports,
    'padel': CategoryBucket.sports,
    'paddle': CategoryBucket.sports,
    'crossfit': CategoryBucket.sports,

    // --- food & drink ---
    'food and drink': CategoryBucket.foodAndDrink,
    'food drink': CategoryBucket.foodAndDrink,
    'food': CategoryBucket.foodAndDrink,
    'drink': CategoryBucket.foodAndDrink,
    'drinks': CategoryBucket.foodAndDrink,
    'cafe': CategoryBucket.foodAndDrink,
    'coffee': CategoryBucket.foodAndDrink,
    'restaurant': CategoryBucket.foodAndDrink,
    'bar': CategoryBucket.foodAndDrink,
    'gastronomy': CategoryBucket.foodAndDrink,

    // --- wellness ---
    'wellness': CategoryBucket.wellness,
    'health and wellness': CategoryBucket.wellness,
    'health': CategoryBucket.wellness,
    'yoga': CategoryBucket.wellness,
    'pilates': CategoryBucket.wellness,
    'meditation': CategoryBucket.wellness,
    'mindfulness': CategoryBucket.wellness,
    'spa': CategoryBucket.wellness,

    // --- creative ---
    'creative': CategoryBucket.creative,
    'art': CategoryBucket.creative,
    'arts': CategoryBucket.creative,
    'art and culture': CategoryBucket.creative,
    'culture': CategoryBucket.creative,
    'music': CategoryBucket.creative,
    'design': CategoryBucket.creative,
    'photography': CategoryBucket.creative,
    'film': CategoryBucket.creative,
    'dance': CategoryBucket.creative,

    // --- women's group ---
    'womens group': CategoryBucket.womensGroup,
    'women group': CategoryBucket.womensGroup,
    'womens': CategoryBucket.womensGroup,
    'women': CategoryBucket.womensGroup,

    // --- business / venue ---
    'business': CategoryBucket.businessVenue,
    'venue': CategoryBucket.businessVenue,
    'business and venue': CategoryBucket.businessVenue,
    'networking': CategoryBucket.businessVenue,
    'coworking': CategoryBucket.businessVenue,
    'startup': CategoryBucket.businessVenue,
    'entrepreneurship': CategoryBucket.businessVenue,
  };

  /// Resolves a raw backend/display label to its semantic bucket.
  static CategoryBucket bucketFor(String rawLabel) =>
      _buckets[canonicalKey(rawLabel)] ?? CategoryBucket.unknown;

  /// Resolves a raw backend/display label to its colours.
  static CategoryStyle styleFor(String rawLabel, KolabingColorTokens c) =>
      styleForBucket(bucketFor(rawLabel), c);

  /// Resolves an already-known bucket to its colours.
  static CategoryStyle styleForBucket(
    CategoryBucket bucket,
    KolabingColorTokens c,
  ) {
    final (Color bg, Color fg) = switch (bucket) {
      CategoryBucket.sports => (
        c.categoryChipSportsBg,
        c.categoryChipSportsText,
      ),
      CategoryBucket.foodAndDrink => (
        c.categoryChipFoodBg,
        c.categoryChipFoodText,
      ),
      CategoryBucket.wellness => (
        c.categoryChipWellnessBg,
        c.categoryChipWellnessText,
      ),
      CategoryBucket.creative => (
        c.categoryChipCreativeBg,
        c.categoryChipCreativeText,
      ),
      CategoryBucket.womensGroup => (
        c.categoryChipWomensBg,
        c.categoryChipWomensText,
      ),
      CategoryBucket.businessVenue => (
        c.categoryChipBusinessBg,
        c.categoryChipBusinessText,
      ),
      CategoryBucket.unknown => (
        c.categoryChipNeutralBg,
        c.categoryChipNeutralText,
      ),
    };
    return CategoryStyle(bucket: bucket, background: bg, foreground: fg);
  }

  /// Convenience: resolve straight from a [BuildContext].
  static CategoryStyle of(BuildContext context, String rawLabel) =>
      styleFor(rawLabel, context.colors);
}
