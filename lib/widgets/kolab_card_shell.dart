// lib/widgets/kolab_card_shell.dart
//
// Shared card shell used by every "My Kolabs" list card:
//   - White surface, subtle border + two-layer shadow
//   - Right-side image that fades into the card (full card height)
//   - Body content is inset so text never overlaps the image
//   - Optional footer (action buttons) spans the FULL card width,
//     sitting on top of the image with no clipping
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';

class KolabCardShell extends StatelessWidget {
  const KolabCardShell({
    required this.body,
    required this.initials,
    super.key,
    this.footer,
    this.imageUrl,
    this.onTap,
  });

  /// Main card content (status badge, title, chips, etc.).
  final Widget body;

  /// Optional row of buttons shown at the bottom, spanning the full card width.
  final Widget? footer;

  /// Network image URL for the right-side visual.
  final String? imageUrl;

  /// Fallback initials shown in the placeholder when there is no image.
  final String initials;

  /// If provided, wraps the whole card in an InkWell.
  final VoidCallback? onTap;

  static const double _imageWidth = 108.0;
  static const double _imageGap = 8.0;

  @override
  Widget build(BuildContext context) {
    Widget shell = ClipRRect(
      borderRadius: KolabingRadius.borderRadiusLg,
      child: Stack(
        children: [
          // ── Content column (defines card height) ──────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Reserve space on the right for the image so body text
                // never overlaps it; footer ignores this padding.
                padding: const EdgeInsets.fromLTRB(
                  16,
                  15,
                  _imageWidth + _imageGap,
                  10,
                ),
                child: body,
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: footer,
                )
              else
                const SizedBox(height: 14),
            ],
          ),
          // ── Right image – stretches full card height via Positioned ────
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _CardFadeImage(
              imageUrl: imageUrl,
              initials: initials,
              width: _imageWidth,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      shell = Material(
        color: Colors.transparent,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: KolabingRadius.borderRadiusLg,
          child: shell,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: const Color(0xFFEAE6DE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: shell,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal fade image — NOT exported; use KolabCardShell instead.
// ---------------------------------------------------------------------------

class _CardFadeImage extends StatelessWidget {
  const _CardFadeImage({
    required this.initials,
    required this.width,
    this.imageUrl,
  });

  final String? imageUrl;
  final String initials;
  final double width;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      imageWidget = _placeholder();
    }

    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          // Left-to-right white fade — blends image into card
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.40, 0.75, 1.0],
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9E6), Color(0xFFFFE28C)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5C4A12),
          ),
        ),
      );
}
