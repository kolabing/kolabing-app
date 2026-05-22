import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants/radius.dart';

/// Reusable wrapper that Gaussian-blurs its [child] when [enabled] is true.
///
/// Used to obscure the COMMUNITY identity (name and logo) on Explore for a
/// free (non-subscribed) business, per `docs/ROLES-AND-PERMISSIONS.md`
/// golden rules 4 & 5 and §2.5:
///
/// > A free business sees every Kolab detail; ONLY the community's name and
/// > logo are blurred (not hidden, not hard-blocked). Subscribing reveals it.
///
/// The blur is purely CLIENT-SIDE. The backend returns the full identity to
/// every viewer by design (see `docs/ROLES-BACKEND-DB-MAP.md` §4), so there is
/// no server-provided blur flag — the caller decides via [enabled].
///
/// When [enabled] is false the child is returned untouched (a community viewer,
/// or a subscribed business, must never see a blur). This keeps the widget safe
/// to wrap unconditionally at the call site.
class BlurredIdentity extends StatelessWidget {
  const BlurredIdentity({
    required this.child,
    required this.enabled,
    this.sigma = 8.0,
    this.showLockHint = false,
    this.hintLabel = 'Subscribe to reveal',
    this.borderRadius,
    super.key,
  });

  /// The widget to blur (a logo image, a name [Text], etc.).
  final Widget child;

  /// When true the child is Gaussian-blurred; when false it renders as-is.
  final bool enabled;

  /// Blur strength. Higher values obscure more. Tuned conservatively so the
  /// shape/colour of a logo is still hinted at but never legible.
  final double sigma;

  /// When true, overlays a small lock + "Subscribe to reveal" affordance on top
  /// of the blurred child. Use this on the larger surface (e.g. the logo) and
  /// leave it off for inline blurred text to avoid clutter.
  final bool showLockHint;

  /// Label shown next to the lock icon when [showLockHint] is true.
  final String hintLabel;

  /// Optional clip applied to the blur so it does not bleed past rounded
  /// corners (e.g. a circular avatar). When null no extra clip is applied;
  /// callers that already clip (ClipOval / ClipRRect) can leave this null.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Subscribed business or any community viewer: never blur.
    if (!enabled) return child;

    // ImageFiltered blurs the child's own pixels in place (cheaper and more
    // predictable than BackdropFilter, which samples whatever is painted
    // behind it). This keeps the blur scoped strictly to the identity element.
    Widget blurred = ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );

    if (borderRadius != null) {
      blurred = ClipRRect(borderRadius: borderRadius!, child: blurred);
    }

    if (!showLockHint) {
      return blurred;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        blurred,
        // Subtle "Subscribe to reveal" affordance so the blur reads as an
        // intentional paywall preview, not a broken image.
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius:
                borderRadius ?? BorderRadius.circular(KolabingRadius.round),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    hintLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
