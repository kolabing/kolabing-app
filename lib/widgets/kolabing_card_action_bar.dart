import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/radius.dart';
import '../config/theme/color_tokens.dart';
import 'kolabing_button.dart';

/// The four action kinds a [KolabingCardActionBar] can render as icon pills.
///
/// Single source of truth for the action -> icon mapping; never inline a
/// Lucide icon per card.
enum KolabingCardAction { edit, share, close }

const Map<KolabingCardAction, IconData> _kCardActionIcons = {
  KolabingCardAction.edit: LucideIcons.edit3,
  KolabingCardAction.share: LucideIcons.share2,
  KolabingCardAction.close: LucideIcons.x,
};

/// Unified action row for "My Kolabs" cards: a dominant VIEW pill + up to
/// three neutral icon pills (edit/share/close), all the same height and
/// pill radius — replaces the old VIEW-button + floating-circle pattern.
class KolabingCardActionBar extends StatelessWidget {
  const KolabingCardActionBar({
    required this.onView,
    super.key,
    this.viewLabel = 'VIEW',
    this.onEdit,
    this.onShare,
    this.onClose,
  });

  final String viewLabel;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onClose;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height,
    child: Row(
      children: [
        Expanded(
          flex: 21,
          child: KolabingPrimaryButton(
            label: viewLabel,
            onPressed: onView,
            icon: const Icon(LucideIcons.eye),
            height: _height,
          ),
        ),
        if (onEdit != null) ..._iconPill(KolabingCardAction.edit, onEdit),
        if (onShare != null) ..._iconPill(KolabingCardAction.share, onShare),
        if (onClose != null) ..._iconPill(KolabingCardAction.close, onClose),
      ],
    ),
  );

  List<Widget> _iconPill(KolabingCardAction action, VoidCallback? onTap) => [
    const SizedBox(width: 10),
    Expanded(
      flex: 13,
      child: KolabingIconPillButton(
        icon: _kCardActionIcons[action]!,
        onTap: onTap,
        height: _height,
      ),
    ),
  ];
}

/// Neutral stadium-pill icon button — cardWhite fill, hairline-ish border,
/// warms to [KolabingColorTokens.pillPressedFill] on press. Never a circle.
class KolabingIconPillButton extends StatefulWidget {
  const KolabingIconPillButton({
    required this.icon,
    required this.onTap,
    super.key,
    this.height = 52,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double height;
  final String? semanticLabel;

  @override
  State<KolabingIconPillButton> createState() => _KolabingIconPillButtonState();
}

class _KolabingIconPillButtonState extends State<KolabingIconPillButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: Opacity(
          opacity: widget.onTap == null ? 0.45 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: widget.height,
            decoration: BoxDecoration(
              color: _pressed ? c.pillPressedFill : c.surface,
              borderRadius: KolabingRadius.borderRadiusPill,
              border: Border.all(color: c.controlBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 20, color: c.iconStroke),
          ),
        ),
      ),
    );
  }
}
