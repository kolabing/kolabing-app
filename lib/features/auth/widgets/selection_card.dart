import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/constants/radius.dart';
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

    // White surface for every state, in line with the Explore / My Kolabs
    // card shells — selection and disabled states are conveyed through
    // the border + shadow, not by tinting the whole card.
    const bgColor = Colors.white;
    final borderColor = isActive
        ? context.colors.softYellowBorder
        : const Color(0xFFEAE6DE);
    final borderWidth = isActive ? 1.5 : 1.0;
    final boxShadow = isActive
        ? [
            BoxShadow(
              color: context.colors.softYellowBorder.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ]
        : isDisabled
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isPressed ? 0.08 : 0.06,
              ),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ];

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
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: KolabingRadius.borderRadiusLg,
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: boxShadow,
            ),
            child: Row(
              children: [
                // Left icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? context.colors.softYellow.withValues(alpha: 0.5)
                        : context.colors.softYellow,
                    borderRadius: KolabingRadius.borderRadiusSm,
                  ),
                  child: Icon(
                    _icon,
                    size: 20,
                    color: isDisabled
                        ? context.colors.onSurfaceVariant.withValues(alpha: 0.5)
                        : context.colors.onSurface,
                  ),
                ),

                const SizedBox(width: 16),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _title(context),
                              style: KolabingTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDisabled
                                    ? context.colors.onSurfaceVariant
                                    : context.colors.onSurface,
                              ),
                            ),
                          ),
                          if (hasBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.softYellow,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: context.colors.softYellowBorder,
                                ),
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
                      const SizedBox(height: 4),
                      Text(
                        _description(context),
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: isDisabled
                              ? context.colors.onSurfaceVariant
                                  .withValues(alpha: 0.5)
                              : context.colors.onSurfaceVariant,
                          height: 1.35,
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
                      color: context.colors.softYellowBorder,
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
