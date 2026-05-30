import 'package:flutter/material.dart';

/// Kolabing border radius values
///
/// Consistent border radius values for rounded corners throughout the app.
abstract final class KolabingRadius {
  /// Extra small radius - 4px
  static const double xs = 4;

  /// Small radius - 8px
  static const double sm = 8;

  /// Medium radius - 12px
  static const double md = 12;

  /// Large radius - 16px
  static const double lg = 16;

  /// Extra large radius - 24px
  static const double xl = 24;

  /// Extra extra large radius - 32px
  static const double xxl = 32;

  /// Fully rounded (pills) - 9999px
  static const double round = 9999;

  // ---------------------------------------------------------------------------
  // BorderRadius convenience getters
  // ---------------------------------------------------------------------------

  /// Extra small BorderRadius - 4px all corners
  static BorderRadius get borderRadiusXs => BorderRadius.circular(xs);

  /// Small BorderRadius - 8px all corners
  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);

  /// Medium BorderRadius - 12px all corners
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);

  /// Large BorderRadius - 16px all corners
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);

  /// Extra large BorderRadius - 24px all corners
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);

  /// Extra extra large BorderRadius - 32px all corners
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(xxl);

  /// Fully rounded BorderRadius
  static BorderRadius get borderRadiusRound => BorderRadius.circular(round);
}
