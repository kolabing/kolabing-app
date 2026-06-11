import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/identity_provider.dart';
import '../services/identity_service.dart';

/// Reusable `@handle` input with a live availability check (`GET
/// /handle/available`) and a format hint. Used by attendee onboarding step 1
/// and Edit Profile. Reports the lowercased handle and whether it is currently
/// "OK to submit" (valid format AND available, OR unchanged from [initialHandle]).
///
/// Debounces the availability query and self-gates a backend 404: when the
/// endpoint is undeployed the field still validates format and reports OK on a
/// well-formed handle (the server re-checks uniqueness on write).
class HandleField extends ConsumerStatefulWidget {
  const HandleField({
    required this.controller,
    required this.onChanged,
    this.initialHandle,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;

  /// `(handle, isOk)` — handle is lowercased; isOk gates the parent's submit.
  final void Function(String handle, bool isOk) onChanged;

  /// The user's current handle (Edit Profile). When the input equals this we
  /// treat it as available without re-checking (it's already theirs).
  final String? initialHandle;
  final bool enabled;

  @override
  ConsumerState<HandleField> createState() => _HandleFieldState();
}

class _HandleFieldState extends ConsumerState<HandleField> {
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _query = _normalize(widget.controller.text);
    _emit();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  String _normalize(String raw) {
    var v = raw.trim().toLowerCase();
    if (v.startsWith('@')) v = v.substring(1);
    return v;
  }

  void _onTextChanged() {
    final normalized = _normalize(widget.controller.text);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _query = normalized);
      _emit();
    });
  }

  bool get _isUnchanged =>
      widget.initialHandle != null &&
      _query.isNotEmpty &&
      _query == widget.initialHandle!.toLowerCase();

  void _emit() {
    final validFormat = IdentityService.isValidHandleFormat(_query);
    // When unchanged or the format is valid and we can't reach the server, we
    // optimistically allow submit; the availability watcher refines this in
    // build() once the future resolves.
    final ok = _isUnchanged || validFormat;
    widget.onChanged(_query, ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validFormat = IdentityService.isValidHandleFormat(_query);
    final availabilityAsync = (_query.isEmpty || _isUnchanged || !validFormat)
        ? null
        : ref.watch(handleAvailabilityProvider(_query));

    Widget? suffix;
    String? hint;
    Color hintColor = KolabingColors.onSurfaceVariant;

    if (_query.isEmpty) {
      hint = l10n.handleFieldHint;
    } else if (!validFormat) {
      hint = l10n.handleFieldFormatError;
      hintColor = KolabingColors.error;
    } else if (_isUnchanged) {
      hint = l10n.handleFieldYours;
      hintColor = KolabingColors.onSurfaceVariant;
    } else if (availabilityAsync != null) {
      availabilityAsync.when(
        loading: () {
          suffix = const _Spinner();
          hint = l10n.handleFieldChecking;
        },
        error: (_, _) {
          // Self-gate: backend unreachable/undeployed → no hard error, allow
          // submit (server re-validates uniqueness on write).
          hint = l10n.handleFieldHint;
        },
        data: (result) {
          if (result == null) {
            hint = l10n.handleFieldHint;
          } else if (result.available) {
            suffix = const Icon(
              LucideIcons.checkCircle,
              size: 18,
              color: KolabingColors.success,
            );
            hint = l10n.handleFieldAvailable;
            hintColor = KolabingColors.success;
          } else {
            suffix = const Icon(
              LucideIcons.xCircle,
              size: 18,
              color: KolabingColors.error,
            );
            hint = result.suggestions.isNotEmpty
                ? l10n.handleFieldTakenWithSuggestion(result.suggestions.first)
                : l10n.handleFieldTaken;
            hintColor = KolabingColors.error;
          }
        },
      );
      // Re-emit OK based on the resolved availability.
      final ok = availabilityAsync.maybeWhen(
        data: (r) => r == null || r.available,
        // While loading, block submit; on error, allow (server re-checks).
        error: (_, _) => true,
        orElse: () => false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_query, ok && validFormat);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_@]')),
          ],
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: KolabingColors.onSurface,
          ),
          decoration: InputDecoration(
            prefixText: '@',
            prefixStyle: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            hintText: l10n.handleFieldPlaceholder,
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: KolabingSpacing.sm),
                    child: suffix,
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: KolabingColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KolabingRadius.sm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm + 2,
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            hint!,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: hintColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(KolabingSpacing.sm),
    child: SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: KolabingColors.primary,
      ),
    ),
  );
}
