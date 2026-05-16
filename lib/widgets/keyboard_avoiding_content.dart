import 'package:flutter/material.dart';

/// Animates content above the on-screen keyboard and removes the consumed
/// inset from descendants to avoid double handling.
class KeyboardAvoidingContent extends StatelessWidget {
  const KeyboardAvoidingContent({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: duration,
      curve: curve,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}
