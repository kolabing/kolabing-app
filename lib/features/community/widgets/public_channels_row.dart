import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/verification_channel.dart';
import 'verification_channel_repeater.dart';

/// A compact horizontal row of the community's PUBLIC contact/links icons.
///
/// Each icon taps through to the resolved link (mailto/tel/social URL). Rendered
/// identically for the owner and for a business viewing the community profile.
/// Renders nothing when there are no public channels.
class PublicChannelsRow extends StatelessWidget {
  const PublicChannelsRow({
    required this.channels,
    super.key,
    this.verified = false,
  });

  /// The public channels to render (already filtered to is_public on the wire).
  final List<VerificationChannel> channels;

  /// When the community is verified, the channels were part of the manual
  /// review, so render them highlighted in brand yellow (matching the tick).
  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: KolabingSpacing.sm,
      runSpacing: KolabingSpacing.sm,
      children: [
        for (final channel in channels)
          _ChannelIconButton(channel: channel, verified: verified),
      ],
    );
  }
}

class _ChannelIconButton extends StatelessWidget {
  const _ChannelIconButton({required this.channel, this.verified = false});

  final VerificationChannel channel;
  final bool verified;

  Future<void> _open() async {
    final uri = channelLaunchUri(channel.type, channel.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: channel.url,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: verified
                ? KolabingColors.primary
                : context.colors.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(
              color: verified ? KolabingColors.primary : context.colors.hairline,
            ),
          ),
          child: Icon(
            verificationChannelIcon(channel.type),
            size: 20,
            color: verified ? Colors.black : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}
