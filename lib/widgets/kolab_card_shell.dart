// lib/widgets/kolab_card_shell.dart
//
// Shared card shell used by every "My Kolabs" list card:
//   - White surface, subtle border + two-layer shadow
//   - Two-column layout: left column for body content + primary action,
//     right column for an image thumbnail + small secondary actions
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';

class KolabCardShell extends StatelessWidget {
  const KolabCardShell({
    required this.body,
    required this.initials,
    super.key,
    this.primaryAction,
    this.secondaryActions = const [],
    this.imageUrl,
    this.onTap,
  });

  /// Main card content (status badge, title, chips, etc.).
  final Widget body;

  /// Optional primary action button (e.g. VIEW/EDIT/PUBLISH), placed at the
  /// bottom of the left column.
  final Widget? primaryAction;

  /// Optional small icon buttons placed under the image thumbnail.
  final List<Widget> secondaryActions;

  /// Network image URL for the thumbnail.
  final String? imageUrl;

  /// Fallback initials shown in the placeholder when there is no image.
  final String initials;

  /// If provided, wraps the whole card in an InkWell.
  final VoidCallback? onTap;

  static const double _imageWidth = 108.0;
  static const double _imageHeight = 98.0;

  @override
  Widget build(BuildContext context) {
    Widget shell = Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left column: body content ───────────────────────────────
              Expanded(child: body),
              const SizedBox(width: 12),
              // ── Right column: image thumbnail ───────────────────────────
              _CardThumbnail(
                imageUrl: imageUrl,
                initials: initials,
                width: _imageWidth,
                height: _imageHeight,
              ),
            ],
          ),
          // ── Bottom row: primary action + secondary icon buttons ────────
          if (primaryAction != null || secondaryActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (primaryAction != null) Expanded(child: primaryAction!),
                for (final action in secondaryActions) ...[
                  const SizedBox(width: 8),
                  action,
                ],
              ],
            ),
          ],
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
      child: ClipRRect(
        borderRadius: KolabingRadius.borderRadiusLg,
        child: shell,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal thumbnail — NOT exported; use KolabCardShell instead.
// ---------------------------------------------------------------------------

class _CardThumbnail extends StatelessWidget {
  const _CardThumbnail({
    required this.initials,
    required this.width,
    required this.height,
    this.imageUrl,
  });

  final String? imageUrl;
  final String initials;
  final double width;
  final double height;

  static const _borderRadius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      imageWidget = _placeholder();
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        border: Border.all(color: const Color(0xFFEAE6DE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: _borderRadius, child: imageWidget),
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
