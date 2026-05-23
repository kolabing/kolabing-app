import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Maps a category name (or slug) to its SVG asset path.
///
/// Keyword matching is case-insensitive and partial. The first match wins.
String categoryIconAsset(String name) {
  const assetBase = 'assets/icons/categories';

  const map = <String, String>{
    // Café / coffee
    'cafe': 'cafe',
    'coffee': 'cafe',
    // Restaurant / dining
    'restaurant': 'restaurant',
    'dining': 'restaurant',
    'bistro': 'restaurant',
    // Bar / pub
    'bar': 'bar',
    'pub': 'bar',
    'lounge': 'bar',
    'cocktail': 'bar',
    // Gym / fitness
    'gym': 'gym',
    'fitness': 'gym',
    'crossfit': 'gym',
    'weight': 'gym',
    // Yoga / meditation
    'yoga': 'yoga',
    'meditation': 'yoga',
    'pilates': 'yoga',
    // Running
    'run': 'running',
    'marathon': 'running',
    'jogging': 'running',
    // Cycling
    'cycling': 'cycling',
    'bike': 'cycling',
    'bicycle': 'cycling',
    'mtb': 'cycling',
    // Music
    'music': 'music',
    'band': 'music',
    'concert': 'music',
    'dj': 'music',
    'song': 'music',
    'choir': 'music',
    // Art
    'art': 'art',
    'design': 'art',
    'paint': 'art',
    'illustration': 'art',
    'creative': 'art',
    // Sports (general)
    'sport': 'sports',
    'football': 'sports',
    'basketball': 'sports',
    'soccer': 'sports',
    'tennis': 'sports',
    'padel': 'sports',
    'volleyball': 'sports',
    'swim': 'sports',
    'surf': 'sports',
    // Wellness / health lifestyle
    'wellness': 'wellness',
    'organic': 'wellness',
    'vegan': 'wellness',
    'mindful': 'wellness',
    'holistic': 'wellness',
    // Tech / startup
    'tech': 'tech',
    'software': 'tech',
    'startup': 'tech',
    'coding': 'tech',
    'developer': 'tech',
    // Education
    'educat': 'education',
    'school': 'education',
    'tutor': 'education',
    'book': 'education',
    'reading': 'education',
    'learn': 'education',
    'academ': 'education',
    // Gaming
    'gaming': 'gaming',
    'game': 'gaming',
    'esport': 'gaming',
    // Social / community
    'social': 'social',
    'community': 'social',
    'network': 'social',
    'meetup': 'social',
    'neighbor': 'social',
    'local': 'social',
    // Fashion / style
    'fashion': 'fashion',
    'style': 'fashion',
    'clothing': 'fashion',
    'wear': 'fashion',
    // Food / general food culture
    'food': 'food',
    'foodie': 'food',
    'catering': 'food',
    'culinar': 'food',
    'cooking': 'food',
    'chef': 'food',
    'bakery': 'food',
    'pastry': 'food',
    'dessert': 'food',
    'pizza': 'food',
    'burger': 'food',
    'sushi': 'food',
    // Outdoor / nature
    'outdoor': 'outdoor',
    'hiking': 'outdoor',
    'hik': 'outdoor',
    'camping': 'outdoor',
    'nature': 'outdoor',
    'trail': 'outdoor',
    'mountain': 'outdoor',
    // Travel
    'travel': 'travel',
    'tour': 'travel',
    'tourism': 'travel',
    'adventure': 'travel',
    // Coworking / workspace
    'coworking': 'coworking',
    'co-working': 'coworking',
    'workspace': 'coworking',
    'office': 'coworking',
    // Retail / shop
    'retail': 'retail',
    'shop': 'retail',
    'store': 'retail',
    'market': 'retail',
    'boutique': 'retail',
    // Beauty / salon / spa
    'beauty': 'beauty',
    'salon': 'beauty',
    'spa': 'beauty',
    'makeup': 'beauty',
    'cosmetic': 'beauty',
    // Health / medical
    'health': 'health',
    'clinic': 'health',
    'medical': 'health',
    'hospital': 'health',
    'pharmacy': 'health',
    'dental': 'health',
    'mental': 'health',
    'wellbeing': 'health',
  };

  final lower = name.toLowerCase();
  for (final entry in map.entries) {
    if (lower.contains(entry.key)) {
      return '$assetBase/category-${entry.value}.svg';
    }
  }
  return '$assetBase/category-default.svg';
}

/// Renders a category icon as an SVG at the given [size].
///
/// Falls back to [category-default.svg] for unrecognised names.
/// Pass an explicit [assetPath] to bypass keyword matching.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.name,
    super.key,
    this.size = 32,
    this.assetPath,
  });

  final String name;
  final double size;

  /// Override the auto-resolved asset path.
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath ?? categoryIconAsset(name);
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
