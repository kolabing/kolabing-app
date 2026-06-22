import 'package:flutter/material.dart';

import '../config/constants/layout.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

/// The three visual intents of [KolabingButton].
enum KolabingButtonVariant {
  /// Yellow fill, ink label, drop shadow — primary CTAs.
  primary,

  /// White fill, warm border, ink label, soft shadow — paired secondary actions.
  secondary,

  /// Ink fill, yellow label — dark accent CTAs (e.g. inside the referral card).
  dark,
}

/// Size presets for [KolabingButton].
enum KolabingButtonSize {
  /// Default full-width CTA — height 56, horizontal padding 24.
  defaultSize,

  /// Compact paired/row button — height 48, horizontal padding 16.
  compact,

  /// Small inline button — height 44, horizontal padding 14.
  small,
}

/// Kolabing unified CTA button — single source of truth for all three variants.
///
/// Replace any locally-styled yellow, white, or dark CTA with this widget.
/// The visual spec lives here; screens only supply label / onPressed / variant.
///
/// Use [size] for automatic height + padding:
///   [KolabingButtonSize.defaultSize] — 56 px, 24 px h-padding (full-width CTA)
///   [KolabingButtonSize.compact]     — 48 px, 16 px h-padding (paired row buttons)
///   [KolabingButtonSize.small]       — 44 px, 14 px h-padding (inline)
///
/// You may still pass [height] explicitly; it takes precedence over [size].
class KolabingButton extends StatefulWidget {
  const KolabingButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = KolabingButtonVariant.primary,
    this.size = KolabingButtonSize.defaultSize,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final KolabingButtonVariant variant;
  final KolabingButtonSize size;

  /// Optional leading icon widget. Stroke/fill is set automatically to match the label color.
  final Widget? icon;

  /// Optional trailing icon widget (e.g. → arrow).
  final Widget? trailingIcon;

  final bool isLoading;
  final bool isDisabled;

  /// Button width. Defaults to full-width (`double.infinity`).
  /// Pass a fixed value when placing buttons in a Row.
  final double width;

  /// Override height. If null, derived from [size].
  final double? height;

  @override
  State<KolabingButton> createState() => _KolabingButtonState();
}

class _KolabingButtonState extends State<KolabingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _liftController;
  late final Animation<double> _liftAnim;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _liftAnim = Tween<double>(begin: 0, end: -2).animate(
      CurvedAnimation(parent: _liftController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _liftController.dispose();
    super.dispose();
  }

  bool get _isActive =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  void _onTapDown(TapDownDetails _) {
    if (_isActive) _liftController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (_isActive) _liftController.reverse();
  }

  void _onTapCancel() {
    if (_isActive) _liftController.reverse();
  }

  double get _resolvedHeight => widget.height ??
      switch (widget.size) {
        KolabingButtonSize.defaultSize => KolabingLayout.buttonHeight,
        KolabingButtonSize.compact => 48,
        KolabingButtonSize.small => 44,
      };

  double get _resolvedHPad => switch (widget.size) {
    KolabingButtonSize.defaultSize => 24,
    KolabingButtonSize.compact => 16,
    KolabingButtonSize.small => 14,
  };

  double get _resolvedIconSize => switch (widget.size) {
    KolabingButtonSize.defaultSize => 18,
    KolabingButtonSize.compact => 16,
    KolabingButtonSize.small => 15,
  };

  Color _fill(KolabingColorTokens colors) => switch (widget.variant) {
    KolabingButtonVariant.primary => colors.primary,
    KolabingButtonVariant.secondary => colors.surface,
    // Fixed dark fill (NOT the theme-adaptive colors.ink, which flips to
    // near-white in dark mode and would leave the yellow label unreadable).
    KolabingButtonVariant.dark => KolabingColors.ink,
  };

  // Always ink black on primary/secondary — never amber or tinted.
  // Dark variant keeps yellow label (legible on black fill).
  Color _labelColor(KolabingColorTokens colors) => switch (widget.variant) {
    KolabingButtonVariant.primary => KolabingColors.ink,
    KolabingButtonVariant.secondary => KolabingColors.ink,
    KolabingButtonVariant.dark => colors.primary,
  };

  List<BoxShadow>? get _shadows => switch (widget.variant) {
    KolabingButtonVariant.primary => KolabingShadows.designButtonShadow,
    KolabingButtonVariant.secondary => KolabingShadows.buttonSecondaryShadow,
    KolabingButtonVariant.dark => null,
  };

  BorderSide? _border(KolabingColorTokens colors) {
    if (widget.variant == KolabingButtonVariant.secondary) {
      return BorderSide(color: colors.outlineVariant, width: 1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = _fill(colors);
    final labelColor = _labelColor(colors);
    final border = _border(colors);
    final h = _resolvedHeight;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _liftAnim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _liftAnim.value),
          child: child,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: _isActive ? _shadows : null,
          ),
          child: SizedBox(
            width: widget.width,
            height: h,
            child: _buildButton(h, fill, labelColor, border),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      double h, Color fill, Color labelColor, BorderSide? border) {
    final iconSize = _resolvedIconSize;

    final shape = border != null
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: border,
          )
        : const StadiumBorder();

    return ElevatedButton(
      onPressed: _isActive ? widget.onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: labelColor,
        disabledBackgroundColor: fill.withValues(alpha: 0.5),
        disabledForegroundColor: labelColor.withValues(alpha: 0.5),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        splashFactory: InkRipple.splashFactory,
        minimumSize: Size(0, h),
        maximumSize: Size(
            widget.width.isInfinite ? double.infinity : widget.width, h),
        padding: EdgeInsets.symmetric(horizontal: _resolvedHPad),
        shape: shape,
        textStyle: switch (widget.size) {
          KolabingButtonSize.defaultSize => KolabingTextStyles.buttonLabelLg,
          KolabingButtonSize.compact => KolabingTextStyles.buttonLabelMd,
          KolabingButtonSize.small =>
            KolabingTextStyles.buttonLabelMd.copyWith(fontSize: 13),
        },
      ).copyWith(
        // Subtle ripple: 6% on press, 4% on hover — keeps lift as the primary feedback
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return labelColor.withValues(alpha: 0.06);
          }
          if (states.contains(WidgetState.hovered)) {
            return labelColor.withValues(alpha: 0.04);
          }
          return null;
        }),
      ),
      child: widget.isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: labelColor,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: labelColor, size: iconSize),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  IconTheme(
                    data: IconThemeData(color: labelColor, size: iconSize),
                    child: widget.trailingIcon!,
                  ),
                ],
              ],
            ),
    );
  }
}

/// Convenience alias — keeps existing [KolabingPrimaryButton] call-sites working
/// without any changes. Delegates to [KolabingButton] with [KolabingButtonVariant.primary].
class KolabingPrimaryButton extends StatelessWidget {
  const KolabingPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) => KolabingButton(
        label: label,
        onPressed: onPressed,
        variant: KolabingButtonVariant.primary,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        width: width,
        height: height,
      );
}
