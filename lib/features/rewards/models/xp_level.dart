import 'package:flutter/material.dart';

/// The five community levels based on lifetime XP.
enum XpLevel {
  newCommunity(
    number: 1,
    title: 'New Community',
    minXp: 0,
    maxXp: 99,
    color: Color(0xFFBDBDBD),
  ),
  activeCommunity(
    number: 2,
    title: 'Active Community',
    minXp: 100,
    maxXp: 249,
    color: Color(0xFF81C784),
  ),
  trustedCommunity(
    number: 3,
    title: 'Trusted Community',
    minXp: 250,
    maxXp: 499,
    color: Color(0xFF4FC3F7),
  ),
  localFavorite(
    number: 4,
    title: 'Local Favorite',
    minXp: 500,
    maxXp: 999,
    color: Color(0xFFFFB74D),
  ),
  localLegend(
    number: 5,
    title: 'Local Legend',
    minXp: 1000,
    maxXp: null,
    color: Color(0xFFFFD861),
  );

  const XpLevel({
    required this.number,
    required this.title,
    required this.minXp,
    required this.maxXp,
    required this.color,
  });

  final int number;
  final String title;
  final int minXp;
  final int? maxXp; // null = no cap (top level)
  final Color color;

  /// Resolve the level for a given XP total.
  static XpLevel fromXp(int xp) {
    if (xp >= localLegend.minXp) return localLegend;
    if (xp >= localFavorite.minXp) return localFavorite;
    if (xp >= trustedCommunity.minXp) return trustedCommunity;
    if (xp >= activeCommunity.minXp) return activeCommunity;
    return newCommunity;
  }

  /// Whether this is the highest level.
  bool get isMaxLevel => maxXp == null;

  /// XP still needed to reach the next level. Zero when at max level.
  int xpToNext(int currentXp) {
    if (isMaxLevel) return 0;
    return (maxXp! + 1) - currentXp;
  }

  /// Progress within this level as 0.0–1.0.
  double progress(int currentXp) {
    if (isMaxLevel) return 1.0;
    final span = (maxXp! + 1) - minXp;
    final earned = currentXp - minXp;
    return (earned / span).clamp(0.0, 1.0);
  }

  /// Next level, or null when at max.
  XpLevel? get next {
    final idx = XpLevel.values.indexOf(this);
    if (idx >= XpLevel.values.length - 1) return null;
    return XpLevel.values[idx + 1];
  }
}
