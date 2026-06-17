import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/verification_channel.dart';

/// Localized label for a verification channel type.
String verificationChannelLabel(
  AppLocalizations l10n,
  VerificationChannelType type,
) {
  switch (type) {
    case VerificationChannelType.instagram:
      return l10n.verificationChannelInstagram;
    case VerificationChannelType.strava:
      return l10n.verificationChannelStrava;
    case VerificationChannelType.whatsapp:
      return l10n.verificationChannelWhatsapp;
    case VerificationChannelType.telegram:
      return l10n.verificationChannelTelegram;
    case VerificationChannelType.flaire:
      return l10n.verificationChannelFlaire;
    case VerificationChannelType.skool:
      return l10n.verificationChannelSkool;
    case VerificationChannelType.tiktok:
      return l10n.verificationChannelTiktok;
    case VerificationChannelType.website:
      return l10n.verificationChannelWebsite;
  }
}

/// Incidental UI-chrome icon per channel type (Lucide is correct here — these
/// are fixed platform channels, NOT a user-managed taxonomy, see
/// docs/ICONS-AND-IMAGES.md §3).
IconData verificationChannelIcon(VerificationChannelType type) {
  switch (type) {
    case VerificationChannelType.instagram:
      return LucideIcons.instagram;
    case VerificationChannelType.strava:
      return LucideIcons.activity;
    case VerificationChannelType.whatsapp:
      return LucideIcons.messageCircle;
    case VerificationChannelType.telegram:
      return LucideIcons.send;
    case VerificationChannelType.flaire:
      return LucideIcons.sparkles;
    case VerificationChannelType.skool:
      return LucideIcons.graduationCap;
    case VerificationChannelType.tiktok:
      return LucideIcons.music2;
    case VerificationChannelType.website:
      return LucideIcons.globe;
  }
}

/// Validate a channel value (URL or handle) for its type. Returns true when the
/// value is plausibly valid. `website` requires a URL-ish value; the rest accept
/// either a URL or a non-empty @handle / username.
bool isValidChannelValue(VerificationChannelType type, String raw) {
  final value = raw.trim();
  if (value.isEmpty) return false;
  final looksLikeUrl =
      value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.contains('.');
  if (type == VerificationChannelType.website) {
    return looksLikeUrl;
  }
  // Social channels: a URL or an @handle / plain username (>= 2 chars).
  if (looksLikeUrl) return true;
  final handle = value.replaceFirst('@', '');
  return handle.length >= 2;
}

/// A dynamic repeater of verification channels. Each row is a type dropdown +
/// a URL/handle field + a remove (✕). An "Add link" button appends a new row.
///
/// Fully controlled: it never owns the list — it calls [onChanged] with the new
/// list on every edit. Used by both community onboarding and the profile edit.
class VerificationChannelRepeater extends StatelessWidget {
  const VerificationChannelRepeater({
    required this.channels,
    required this.onChanged,
    super.key,
    this.showLabel = true,
  });

  /// The current channels.
  final List<VerificationChannel> channels;

  /// Called with the full updated list on any add / edit / remove.
  final ValueChanged<List<VerificationChannel>> onChanged;

  /// Whether to render the section label above the rows.
  final bool showLabel;

  void _addChannel() {
    // Default a new row to the first unused type, else website.
    final used = channels.map((c) => c.type).toSet();
    final next = VerificationChannelType.values.firstWhere(
      (t) => !used.contains(t),
      orElse: () => VerificationChannelType.website,
    );
    onChanged([...channels, VerificationChannel(type: next, url: '')]);
  }

  void _removeAt(int index) {
    final next = List<VerificationChannel>.from(channels)..removeAt(index);
    onChanged(next);
  }

  void _updateAt(int index, VerificationChannel channel) {
    final next = List<VerificationChannel>.from(channels);
    next[index] = channel;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            l10n.verificationChannelsLabel,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
        ],
        for (var i = 0; i < channels.length; i++) ...[
          _ChannelRow(
            key: ValueKey('channel-row-$i'),
            channel: channels[i],
            onTypeChanged: (type) =>
                _updateAt(i, channels[i].copyWith(type: type)),
            onUrlChanged: (url) => _updateAt(i, channels[i].copyWith(url: url)),
            onRemove: () => _removeAt(i),
          ),
          const SizedBox(height: KolabingSpacing.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addChannel,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.verificationAddChannel),
          ),
        ),
      ],
    );
  }
}

class _ChannelRow extends StatefulWidget {
  const _ChannelRow({
    required this.channel,
    required this.onTypeChanged,
    required this.onUrlChanged,
    required this.onRemove,
    super.key,
  });

  final VerificationChannel channel;
  final ValueChanged<VerificationChannelType> onTypeChanged;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onRemove;

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.channel.url);
  }

  @override
  void didUpdateWidget(_ChannelRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync if the parent replaced the url (e.g. prefill).
    if (widget.channel.url != _controller.text) {
      _controller.text = widget.channel.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Type dropdown
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<VerificationChannelType>(
            initialValue: widget.channel.type,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.outlineVariant),
              ),
            ),
            items: [
              for (final type in VerificationChannelType.values)
                DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        verificationChannelIcon(type),
                        size: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          verificationChannelLabel(l10n, type),
                          overflow: TextOverflow.ellipsis,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (type) {
              if (type != null) widget.onTypeChanged(type);
            },
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        // URL / handle field
        Expanded(
          flex: 6,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: l10n.verificationChannelUrlHint,
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.textTertiary,
              ),
              filled: true,
              fillColor: context.colors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.colors.outlineVariant),
              ),
            ),
            onChanged: widget.onUrlChanged,
          ),
        ),
        // Remove
        IconButton(
          tooltip: l10n.verificationRemoveChannel,
          onPressed: widget.onRemove,
          icon: Icon(LucideIcons.x, size: 18, color: context.colors.error),
        ),
      ],
    );
  }
}
