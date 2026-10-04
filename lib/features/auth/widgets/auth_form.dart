import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';

// The form pieces shared by the logged-out screens (Login, Forgot password),
// so their fields, CTAs and links look and behave the same.

const Color _kYellow = KolabingColors.primary;
const Color _kYellowDeep = KolabingColors.primaryDark;
const Color _kInk = KolabingColors.ink;
const Color _kInkBody = KolabingColors.inkBody;
const Color _kMuted = KolabingColors.muted;
const Color _kAmber = KolabingColors.amber;
const Color _kInputBorder = KolabingColors.outlineVariant;
const Color _kInputFill = KolabingColors.surface;
const Color _kDivider = Color(0xFFE1D9C8);

const double _kFieldRadius = 16;

/// Text style for what the user types into an auth field.
TextStyle get authFieldTextStyle =>
    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: _kInk);

/// White, rounded, hairline-bordered field; ink border on focus.
InputDecoration authFieldDecoration(
  BuildContext context, {
  required IconData prefixIcon,
  String? hint,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kFieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: _kMuted.withValues(alpha: 0.7),
    ),
    prefixIcon: Icon(prefixIcon, color: _kMuted, size: 19),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: _kInputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: border(_kInputBorder),
    enabledBorder: border(_kInputBorder),
    disabledBorder: border(_kInputBorder),
    focusedBorder: border(_kInk, 1.6),
    errorBorder: border(context.colors.error),
    focusedErrorBorder: border(context.colors.error, 1.6),
    errorStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: context.colors.error,
    ),
  );
}

/// The label above a field.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _kInkBody,
      ),
    ),
  );
}

/// A small amber text link, e.g. "Forgot password?" on a label row.
class AuthInlineLink extends StatelessWidget {
  const AuthInlineLink({
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isEnabled ? onTap : null,
    style: TextButton.styleFrom(
      foregroundColor: _kInk,
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        // Explicit: the app's TextButton theme adds letter spacing.
        letterSpacing: 0,
        color: isEnabled ? _kAmber : _kMuted,
      ),
    ),
  );
}

/// "—— or continue with ——"
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: _kDivider, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kMuted,
          ),
        ),
      ),
      const Expanded(child: Divider(color: _kDivider, thickness: 1)),
    ],
  );
}

/// "Prompt? Action →" — the whole row is the button, so a tap on the prompt
/// counts too.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.prompt,
    required this.action,
    required this.onTap,
    this.isEnabled = true,
    this.inkKey,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;
  final bool isEnabled;

  /// Key on the tappable InkWell, for tests.
  final Key? inkKey;

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: inkKey,
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    prompt,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                    decoration: TextDecoration.underline,
                    decorationColor: _kYellowDeep,
                    decorationThickness: 2.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: _kInk),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A soft yellow halo around a field while it has focus.
class AuthFocusGlow extends StatelessWidget {
  const AuthFocusGlow({required this.focused, required this.child, super.key});

  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_kFieldRadius),
      boxShadow: [
        BoxShadow(
          color: _kYellow.withValues(alpha: focused ? 0.75 : 0),
          spreadRadius: focused ? 4 : 0,
        ),
      ],
    ),
    child: child,
  );
}

/// The primary action: an ink pill with a yellow label and arrow, a spinner
/// while loading and a check on success.
class AuthPrimaryCta extends StatefulWidget {
  const AuthPrimaryCta({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showSuccess = false,
    this.isEnabled = true,
    this.showArrow = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool showSuccess;
  final bool isEnabled;
  final bool showArrow;

  @override
  State<AuthPrimaryCta> createState() => _AuthPrimaryCtaState();
}

class _AuthPrimaryCtaState extends State<AuthPrimaryCta> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isEnabled && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (widget.isLoading) {
      content = const SizedBox(
        key: ValueKey('loading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_kYellow),
        ),
      );
    } else if (widget.showSuccess) {
      content = const Icon(
        Icons.check_rounded,
        key: ValueKey('success'),
        size: 24,
        color: _kYellow,
      );
    } else {
      // Scales down rather than overflowing for long translations.
      content = FittedBox(
        key: const ValueKey('label'),
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kYellow,
              ),
            ),
            if (widget.showArrow) ...[
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: _kYellow,
              ),
            ],
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.isEnabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: widget.isEnabled || widget.isLoading ? 1 : 0.45,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _kInk,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _kInk.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
