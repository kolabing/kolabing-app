import 'package:flutter/widgets.dart';

/// Reusable fade + translate animation combinator for auth screen staggered entries.
///
/// Wraps a child in a combined opacity + translate animation.
/// Pass pre-built `Animation<double>` and `Animation<Offset>` from the screen's
/// AnimationController.
class AuthFadeSlide extends StatelessWidget {
  const AuthFadeSlide({
    required this.opacity,
    required this.offset,
    required this.child,
    super.key,
  });

  final Animation<double> opacity;
  final Animation<Offset> offset;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([opacity, offset]),
    builder: (context, c) => Opacity(
      opacity: opacity.value.clamp(0.0, 1.0),
      child: Transform.translate(offset: offset.value, child: c),
    ),
    child: child,
  );
}

/// Simplified variant — opacity only, no slide offset needed.
class AuthFadeOnly extends StatelessWidget {
  const AuthFadeOnly({
    required this.opacity,
    required this.child,
    super.key,
  });

  final Animation<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: opacity,
    builder: (context, c) => Opacity(
      opacity: opacity.value.clamp(0.0, 1.0),
      child: c,
    ),
    child: child,
  );
}
