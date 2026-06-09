import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

/// User type for selection cards
enum SelectionUserType { business, community, attendee }

/// Compact row-style selection option for account type.
///
/// Shows a small icon on the left, stacked title + description in the
/// centre, and a soft check indicator on the right when selected.
class SelectionCard extends StatefulWidget {
  const SelectionCard({
    required this.userType,
    required this.onTap,
    super.key,
    this.isSelected = false,
    this.isEnabled = true,
    this.badgeLabel,
    this.descriptionOverride,
  });

  final SelectionUserType userType;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isEnabled;
  final String? badgeLabel;
  final String? descriptionOverride;

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  IconData get _icon {
    switch (widget.userType) {
      case SelectionUserType.business:
        return LucideIcons.briefcase;
      case SelectionUserType.community:
        return LucideIcons.users;
      case SelectionUserType.attendee:
        return LucideIcons.star;
    }
  }

  String _title(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (widget.userType) {
      case SelectionUserType.business:
        return l10n.selectionCardBusinessTitle;
      case SelectionUserType.community:
        return l10n.selectionCardCommunityTitle;
      case SelectionUserType.attendee:
        return l10n.selectionCardAttendeeTitle;
    }
  }

  String _description(BuildContext context) {
    final override = widget.descriptionOverride;
    if (override != null && override.trim().isNotEmpty) return override;

    final l10n = AppLocalizations.of(context);
    switch (widget.userType) {
      case SelectionUserType.business:
        return l10n.selectionCardBusinessDescription;
      case SelectionUserType.community:
        return l10n.selectionCardCommunityDescription;
      case SelectionUserType.attendee:
        return l10n.selectionCardAttendeeDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBadge =
        widget.badgeLabel != null && widget.badgeLabel!.trim().isNotEmpty;
    final isActive = widget.isSelected;
    final isDisabled = !widget.isEnabled;

    // Selected: very soft yellow tint + slightly stronger border
    final bgColor = isActive
        ? const Color(0xFFFFF8DC) // warm cream-yellow, lighter than #FFE28C
        : context.colors.surface;
    final borderColor = isActive
        ? const Color(0xFFFFE28C)
        : isDisabled
        ? context.colors.darkBorder.withValues(alpha: 0.5)
        : context.colors.darkBorder;
    final borderWidth = isActive ? 1.5 : 1.0;
    final shadowOpacity = isActive
        ? 0.12
        : _isPressed
        ? 0.08
        : 0.05;

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      selected: widget.isSelected,
      label: AppLocalizations.of(context).selectionCardSemanticLabel(
        _title(context),
        _description(context),
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _isPressed ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFE28C).withValues(alpha: 0.55)
                        : context.colors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icon,
                    size: 18,
                    color: isDisabled
                        ? context.colors.onSurfaceVariant.withValues(alpha: 0.5)
                        : context.colors.onSurface,
                  ),
                ),

                const SizedBox(width: 14),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            _title(context),
                            style: KolabingTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? context.colors.onSurfaceVariant
                                  : context.colors.onSurface,
                            ),
                          ),
                          if (hasBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.softYellow,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.badgeLabel!,
                                style: KolabingTextStyles.button.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: context.colors.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _description(context),
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: isDisabled
                              ? context.colors.onSurfaceVariant
                                  .withValues(alpha: 0.5)
                              : context.colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right indicator
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isActive ? 1.0 : 0.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE28C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
