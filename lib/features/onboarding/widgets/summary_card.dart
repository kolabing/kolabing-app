import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/layout.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/onboarding_state.dart';

/// Summary card showing all collected onboarding data.
///
/// [compact] renders only the header row (avatar + name + type · city) and
/// drops the details block — used on the final step so the login fields stay
/// above the fold.
class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.data, this.compact = false, super.key});

  final OnboardingData data;
  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inlineItemWidth = constraints.maxWidth >= 360
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.hairline),
          boxShadow: [KolabingShadows.card],
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
                    color: context.colors.surfaceVariant,
                    border: Border.all(
                      color: data.photoBase64 != null
                          ? context.colors.primary
                          : context.colors.darkBorder,
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
                      ? Icon(
                          LucideIcons.user,
                          size: 24,
                          color: context.colors.textTertiary,
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
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.isBusiness ? data.businessTypesSummary : (data.typeName ?? 'Unknown type')} \u2022 ${data.location?.city ?? data.cityName ?? 'Unknown city'}',
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!compact &&
                (data.about != null ||
                    data.venueName != null ||
                    data.phone != null ||
                    data.instagram != null ||
                    data.tiktok != null ||
                    data.website != null)) ...[
              const SizedBox(height: 16),
              Divider(color: context.colors.darkBorder, height: 1),
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
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
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
          child: Icon(icon, size: 16, color: context.colors.textTertiary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
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
        Icon(icon, size: 16, color: context.colors.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}
