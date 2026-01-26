import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';

/// City list item for city selection
class CityListItem extends StatefulWidget {
  const CityListItem({
    required this.id,
    required this.name,
    required this.onTap,
    super.key,
    this.country,
    this.isSelected = false,
  });

  /// City ID
  final String id;

  /// City name
  final String name;

  /// Country name
  final String? country;

  /// Whether this item is selected
  final bool isSelected;

  /// Callback when tapped
  final VoidCallback onTap;

  @override
  State<CityListItem> createState() => _CityListItemState();
}

class _CityListItemState extends State<CityListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? KolabingColors.softYellow
                : (_isPressed
                    ? KolabingColors.surfaceVariant
                    : KolabingColors.surface),
            border: Border(
              left: BorderSide(
                color:
                    widget.isSelected ? KolabingColors.primary : Colors.transparent,
                width: 4,
              ),
              bottom: const BorderSide(
                color: KolabingColors.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Location icon
              Icon(
                LucideIcons.mapPin,
                size: 24,
                color: widget.isSelected
                    ? KolabingColors.primary
                    : KolabingColors.textTertiary,
              ),
              const SizedBox(width: 12),

              // City info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    if (widget.country != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.country!,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Checkmark or arrow
              Icon(
                widget.isSelected ? LucideIcons.check : LucideIcons.chevronRight,
                size: 20,
                color: widget.isSelected
                    ? KolabingColors.primary
                    : KolabingColors.textTertiary,
              ),
            ],
          ),
        ),
      );
}
