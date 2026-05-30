import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../models/onboarding_state.dart';

/// Summary card showing all collected onboarding data
class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.data, super.key});

  final OnboardingData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inlineItemWidth = constraints.maxWidth >= 360
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KolabingColors.darkBorder),
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KolabingColors.surfaceVariant,
                    border: Border.all(
                      color: data.photoBase64 != null
                          ? KolabingColors.primary
                          : KolabingColors.darkBorder,
                      width: 2,
                    ),
                    image: data.photoBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(data.photoBase64!)),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name ?? 'No name',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.isBusiness ? data.businessTypesSummary : (data.typeName ?? 'Unknown type')} \u2022 ${data.location?.city ?? data.cityName ?? 'Unknown city'}',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data.about != null ||
                data.venueName != null ||
                data.phone != null ||
                data.instagram != null ||
                data.tiktok != null ||
                data.website != null) ...[
              const SizedBox(height: 16),
              const Divider(color: KolabingColors.darkBorder, height: 1),
              const SizedBox(height: 16),
              if (data.isBusiness &&
                  data.venueName != null &&
                  data.venueName!.isNotEmpty) ...[
                _SummaryDetailItem(
                  icon: LucideIcons.building2,
                  text: data.venueName!,
                ),
                if (data.location != null &&
                    data.location!.formattedAddress.trim().isNotEmpty)
                  _SummaryDetailItem(
                    icon: LucideIcons.mapPin,
                    text: data.location!.formattedAddress,
                  ),
                if (data.location != null)
                  _SummaryDetailItem(
                    icon: LucideIcons.mapPin,
                    text: data.location!.city,
                  ),
                if (data.venueCapacity != null)
                  _SummaryDetailItem(
                    icon: LucideIcons.users,
                    text: 'Capacity ${data.venueCapacity}',
                  ),
                if (data.venuePhotos.isNotEmpty)
                  _SummaryDetailItem(
                    icon: LucideIcons.image,
                    text: '${data.venuePhotos.length} venue photo(s)',
                  ),
              ],
              if (data.about != null && data.about!.isNotEmpty) ...[
                Text(
                  data.about!,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: KolabingColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (data.phone != null && data.phone!.isNotEmpty)
                    _SummaryInlineItem(
                      icon: LucideIcons.phone,
                      text: data.phone!,
                      width: inlineItemWidth,
                    ),
                  if (data.instagram != null && data.instagram!.isNotEmpty)
                    _SummaryInlineItem(
                      icon: LucideIcons.instagram,
                      text: '@${data.instagram}',
                      width: inlineItemWidth,
                    ),
                  if (data.tiktok != null && data.tiktok!.isNotEmpty)
                    _SummaryInlineItem(
                      icon: LucideIcons.music,
                      text: '@${data.tiktok}',
                      width: inlineItemWidth,
                    ),
                  if (data.website != null && data.website!.isNotEmpty)
                    _SummaryInlineItem(
                      icon: LucideIcons.globe,
                      text: data.website!.replaceFirst('https://', ''),
                      width: inlineItemWidth,
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _SummaryDetailItem extends StatelessWidget {
  const _SummaryDetailItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: KolabingColors.textTertiary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: KolabingColors.onSurfaceVariant,
              height: 1.35,
            ),
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}

class _SummaryInlineItem extends StatelessWidget {
  const _SummaryInlineItem({
    required this.icon,
    required this.text,
    required this.width,
  });

  final IconData icon;
  final String text;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Row(
      children: [
        Icon(icon, size: 16, color: KolabingColors.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}
