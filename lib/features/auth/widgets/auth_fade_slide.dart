import 'package:flutter/widgets.dart';

/// Reusable fade + translate animation combinator for auth screen staggered entries.
///
/// Wraps a child in a combined opacity + translate animation using Flutter's
/// composited `FadeTransition` and `SlideTransition` for GPU-efficient rendering.
/// Opacity values outside [0, 1] are clamped by FadeTransition internally.
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
  Widget build(BuildContext context) => FadeTransition(
    opacity: opacity,
    child: AnimatedBuilder(
      animation: offset,
      builder: (context, c) =>
          Transform.translate(offset: offset.value, child: c),
      child: child,
    ),
  );
}

/// Simplified variant — opacity fade only, no translation.
class AuthFadeOnly extends StatelessWidget {
  const AuthFadeOnly({required this.opacity, required this.child, super.key});

  final Animation<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: opacity, child: child);
}
