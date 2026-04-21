import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../models/onboarding_state.dart';

/// Summary card showing all collected onboarding data
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.data,
    super.key,
  });

  final OnboardingData data;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KolabingColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Row(
              children: [
                // Photo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KolabingColors.surfaceVariant,
                    border: Border.all(
                      color: data.photoBase64 != null
                          ? KolabingColors.primary
                          : KolabingColors.border,
                      width: 2,
                    ),
                    image: data.photoBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(data.photoBase64!),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: data.photoBase64 == null
                      ? const Icon(
                          LucideIcons.user,
                          size: 24,
                          color: KolabingColors.textTertiary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Name and type/city
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name ?? 'No name',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.typeName ?? 'Unknown type'} \u2022 ${data.location?.city ?? data.cityName ?? 'Unknown city'}',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider
            if (data.about != null ||
                data.venueName != null ||
                data.phone != null ||
                data.instagram != null ||
                data.tiktok != null ||
                data.website != null) ...[
              const SizedBox(height: 16),
              const Divider(color: KolabingColors.border, height: 1),
              const SizedBox(height: 16),

              if (data.isBusiness &&
                  data.venueName != null &&
                  data.venueName!.isNotEmpty) ...[
                _ContactItem(
                  icon: LucideIcons.building2,
                  text: data.venueName!,
                ),
                if (data.location != null)
                  _ContactItem(
                    icon: LucideIcons.mapPin,
                    text: data.location!.city,
                  ),
                if (data.venueCapacity != null)
                  _ContactItem(
                    icon: LucideIcons.users,
                    text: 'Capacity ${data.venueCapacity}',
                  ),
                if (data.venuePhotos.isNotEmpty)
                  _ContactItem(
                    icon: LucideIcons.image,
                    text: '${data.venuePhotos.length} venue photo(s)',
                  ),
              ],

              // About
              if (data.about != null && data.about!.isNotEmpty) ...[
                Text(
                  data.about!,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: KolabingColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Contact info
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (data.phone != null && data.phone!.isNotEmpty)
                    _ContactItem(
                      icon: LucideIcons.phone,
                      text: data.phone!,
                    ),
                  if (data.instagram != null && data.instagram!.isNotEmpty)
                    _ContactItem(
                      icon: LucideIcons.instagram,
                      text: '@${data.instagram}',
                    ),
                  if (data.tiktok != null && data.tiktok!.isNotEmpty)
                    _ContactItem(
                      icon: LucideIcons.music,
                      text: '@${data.tiktok}',
                    ),
                  if (data.website != null && data.website!.isNotEmpty)
                    _ContactItem(
                      icon: LucideIcons.globe,
                      text: data.website!.replaceFirst('https://', ''),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: KolabingColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: KolabingColors.textSecondary,
            ),
          ),
        ],
      );
}
