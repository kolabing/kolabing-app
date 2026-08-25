/// The layout for an onboarding step whose job is "search a list and pick from
/// it" — the three city steps today.
///
/// It exists because the same layout bug shipped in all three of them. Each was
/// a `Scaffold > SafeArea > Column` with a fixed header, a fixed title block, a
/// fixed search field, an `Expanded` list and a fixed footer button — and
/// `Scaffold.resizeToAvoidBottomInset` left at its default `true`. Open the
/// keyboard and the body shrinks by ~336dp while every child except the list
/// keeps its height, so on a 393×852 phone the list was left 27dp and on
/// anything smaller the `Column` overflowed and **the Continue button painted
/// on top of the search field** (#163).
///
/// Two rules fix the class of bug rather than the three instances:
///
/// 1. `resizeToAvoidBottomInset: false`, so the body height never changes and
///    an overflow is not arithmetically possible;
/// 2. the keyboard's height is reserved *inside* the flexible child, so the
///    results — the only thing that should ever shrink — are what give up the
///    space, and no arrangement of chrome can push the column past its box.
///
/// On top of that it does the thing a search step should do: **while the field
/// has focus, everything that is not the search collapses.** The step counter,
/// the progress dots, the title, the subtitle and the footer button answer no
/// question the reader is asking mid-word, and folding them hands roughly 200dp
/// back to the results — six rows instead of half a row. They all return the
/// moment focus leaves, which is the same moment a choice gets made.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

class OnboardingSearchStep extends StatefulWidget {
  const OnboardingSearchStep({
    required this.searchHint,
    required this.onQueryChanged,
    required this.results,
    super.key,
    this.chrome,
    this.headline,
    this.aboveResults,
    this.footer,
    this.horizontalPadding = KolabingSpacing.lg,
  });

  /// The step header — back row, step counter, progress. Folded away while the
  /// reader is typing.
  final Widget? chrome;

  /// Title and subtitle. Folded away while the reader is typing.
  final Widget? headline;

  /// A label or banner between the field and the results ("Popular cities",
  /// the business step's selection counter). Stays put: it describes what the
  /// reader is looking at.
  final Widget? aboveResults;

  /// The results area — the caller's list and its loading / empty / error
  /// states. Gets every pixel the fixed children do not need.
  final Widget results;

  /// The primary action. Folded away while the reader is typing: it sits behind
  /// the keyboard and cannot be reached, and hiding it is what buys the results
  /// their last hundred pixels.
  final Widget? footer;

  final String searchHint;
  final ValueChanged<String> onQueryChanged;
  final double horizontalPadding;

  @override
  State<OnboardingSearchStep> createState() => _OnboardingSearchStepState();
}

class _OnboardingSearchStepState extends State<OnboardingSearchStep> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    widget.onQueryChanged(value);
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    // Read the inset directly rather than via the Scaffold: with
    // resizeToAvoidBottomInset off, this is the only thing that knows how much
    // of the screen the keyboard is standing on.
    //
    // Focus OR a live inset: the keyboard animates in over ~250ms and the fold
    // has to be ahead of it, not racing it. A nonzero inset means the screen is
    // already smaller, whoever holds focus.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final searching = _focusNode.hasFocus || keyboardInset > 0;

    return Scaffold(
      backgroundColor: context.colors.background,
      // The one line that makes the overflow impossible.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.chrome != null)
              _Collapsible(visible: !searching, child: widget.chrome!),
            if (widget.headline != null)
              _Collapsible(visible: !searching, child: widget.headline!),

            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.horizontalPadding,
                searching ? KolabingSpacing.sm : 0,
                widget.horizontalPadding,
                KolabingSpacing.sm,
              ),
              child: _SearchField(
                controller: _controller,
                focusNode: _focusNode,
                hint: widget.searchHint,
                onChanged: _onChanged,
                onClear: _hasText ? _clear : null,
              ),
            ),

            if (widget.aboveResults != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.horizontalPadding,
                  0,
                  widget.horizontalPadding,
                  KolabingSpacing.xs,
                ),
                child: widget.aboveResults!,
              ),

            // The keyboard is reserved INSIDE the flexible child, never as a
            // rigid sibling. A `SizedBox(height: inset)` next to `Expanded`
            // reintroduces the original bug: for one frame — chrome still
            // unfolding, inset already full — the fixed children can exceed the
            // body and the Column overflows again. Padding within the Expanded
            // cannot: the box is whatever is left over, and the inset only ever
            // squeezes the list inside it, down to zero if it must.
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: widget.results,
              ),
            ),

            if (widget.footer != null)
              _Collapsible(visible: !searching, child: widget.footer!),
          ],
        ),
      ),
    );
  }
}

/// Folds a fixed-height child out of the column, and fades it while it goes.
///
/// `AnimatedSize` alone would slide the content; the fade stops the title
/// reading as though it fell off the top of the screen.
class _Collapsible extends StatelessWidget {
  const _Collapsible({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: visible ? child : const SizedBox(width: double.infinity),
    ),
  );
}

/// The search field, owned here so all three steps search the same way.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    // Search, then close: the reader's next move is to pick from the list, and
    // the list is what the keyboard is covering.
    onSubmitted: (_) => FocusScope.of(context).unfocus(),
    style: KolabingTextStyles.bodyMedium.copyWith(
      color: context.colors.onSurface,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.textTertiary,
      ),
      prefixIcon: Icon(
        LucideIcons.search,
        size: 20,
        color: context.colors.textTertiary,
      ),
      suffixIcon: onClear == null
          ? null
          : IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 20,
                color: context.colors.textTertiary,
              ),
              onPressed: onClear,
            ),
      filled: true,
      fillColor: context.colors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        borderSide: BorderSide(color: context.colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        borderSide: BorderSide(color: context.colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        borderSide: BorderSide(color: context.colors.primaryDark, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
    ),
  );
}

/// The results area's non-list states, placed just under the field rather than
/// centred in a box the keyboard is standing on. "No cities found" centred in
/// the old layout was invisible exactly when it mattered.
class OnboardingSearchMessage extends StatelessWidget {
  const OnboardingSearchMessage({
    required this.text,
    super.key,
    this.icon,
    this.action,
  });

  final String text;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.lg,
      vertical: KolabingSpacing.lg,
    ),
    child: Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 32, color: context.colors.textTertiary),
          const SizedBox(height: KolabingSpacing.sm),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: KolabingSpacing.sm),
          action!,
        ],
      ],
    ),
  );
}
