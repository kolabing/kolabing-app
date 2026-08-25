import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';
import '../l10n/app_localizations.dart';

/// Instagram / TikTok / website, wherever a host or a community shows theirs.
///
/// `community_profiles` and `business_profiles` store handles, not URLs, so the
/// handle-to-URL shapes here match what the profile screens have always used.
/// Each link is self-gated: an absent handle renders nothing rather than a dead
/// icon, and with no handles at all the row disappears entirely.
class SocialLinksRow extends StatelessWidget {
  const SocialLinksRow({
    super.key,
    this.instagram,
    this.tiktok,
    this.website,
    this.compact = false,
  });

  final String? instagram;
  final String? tiktok;
  final String? website;

  /// Icons only, no handles — for a dense identity block.
  final bool compact;

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  bool get hasAny => _has(instagram) || _has(tiktok) || _has(website);

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        if (_has(instagram))
          _SocialChip(
            icon: LucideIcons.instagram,
            label: '@${instagram!.trim()}',
            url: 'https://instagram.com/${instagram!.trim()}',
            compact: compact,
          ),
        if (_has(tiktok))
          _SocialChip(
            icon: LucideIcons.music,
            label: '@${tiktok!.trim()}',
            url: 'https://tiktok.com/@${tiktok!.trim()}',
            compact: compact,
          ),
        if (_has(website))
          _SocialChip(
            icon: LucideIcons.globe,
            label: l10n.commonWebsite,
            url: website!.trim(),
            compact: compact,
          ),
      ],
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({
    required this.icon,
    required this.label,
    required this.url,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String url;
  final bool compact;

  Future<void> _open() async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: _open,
    borderRadius: BorderRadius.circular(KolabingRadius.round),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : KolabingSpacing.xs,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.onSurface),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
