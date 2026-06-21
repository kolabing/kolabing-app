import 'package:flutter/material.dart';

import '../config/constants/layout.dart';
import '../config/theme/color_tokens.dart';
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
class KolabingButton extends StatelessWidget {
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

  double get _resolvedHeight => height ?? switch (size) {
    KolabingButtonSize.defaultSize => KolabingLayout.buttonHeight,
    KolabingButtonSize.compact => 48,
    KolabingButtonSize.small => 44,
  };

  double get _resolvedHPad => switch (size) {
    KolabingButtonSize.defaultSize => 24,
    KolabingButtonSize.compact => 16,
    KolabingButtonSize.small => 14,
  };

  double get _resolvedIconSize => switch (size) {
    KolabingButtonSize.defaultSize => 18,
    KolabingButtonSize.compact => 16,
    KolabingButtonSize.small => 15,
  };

  // ---------------------------------------------------------------------------
  // Derived style properties per variant — require context.colors to adapt
  // ---------------------------------------------------------------------------

  Color _fill(KolabingColorTokens colors) => switch (variant) {
    KolabingButtonVariant.primary => colors.primary,
    KolabingButtonVariant.secondary => colors.surface,
    KolabingButtonVariant.dark => colors.ink,
  };

  Color _labelColor(KolabingColorTokens colors) => switch (variant) {
    KolabingButtonVariant.primary => colors.onPrimary,
    KolabingButtonVariant.secondary => colors.ink,
    KolabingButtonVariant.dark => colors.primary,
  };

  List<BoxShadow>? get _shadows => switch (variant) {
    KolabingButtonVariant.primary => KolabingShadows.designButtonShadow,
    KolabingButtonVariant.secondary => KolabingShadows.buttonSecondaryShadow,
    KolabingButtonVariant.dark => null,
  };

  BorderSide? _border(KolabingColorTokens colors) {
    if (variant == KolabingButtonVariant.secondary) {
      return BorderSide(color: colors.hairline, width: 1);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = _fill(colors);
    final labelColor = _labelColor(colors);
    final border = _border(colors);
    final isActive = !isDisabled && !isLoading && onPressed != null;
    final h = _resolvedHeight;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: isActive ? _shadows : null,
      ),
      child: SizedBox(
        width: width,
        height: h,
        child: _buildButton(isActive, h, fill, labelColor, border),
      ),
    );
  }

  Widget _buildButton(bool isActive, double h, Color fill, Color labelColor, BorderSide? border) {
    final iconSize = _resolvedIconSize;
    return ElevatedButton(
      onPressed: isActive ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: labelColor,
        disabledBackgroundColor: fill.withValues(alpha: 0.5),
        disabledForegroundColor: labelColor.withValues(alpha: 0.5),
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: Size(0, h),
        maximumSize: Size(width.isInfinite ? double.infinity : width, h),
        padding: EdgeInsets.symmetric(horizontal: _resolvedHPad),
        shape: border != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: border,
              )
            : const StadiumBorder(),
        textStyle: switch (size) {
          KolabingButtonSize.defaultSize => KolabingTextStyles.buttonLabelLg,
          KolabingButtonSize.compact => KolabingTextStyles.buttonLabelMd,
          KolabingButtonSize.small => KolabingTextStyles.buttonLabelMd.copyWith(fontSize: 13),
        },
      ),
      child: isLoading
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
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: labelColor, size: iconSize),
                    child: icon!,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  IconTheme(
                    data: IconThemeData(color: labelColor, size: iconSize),
                    child: trailingIcon!,
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
