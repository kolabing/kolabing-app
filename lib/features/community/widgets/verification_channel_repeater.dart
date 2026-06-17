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
    case VerificationChannelType.email:
      return l10n.verificationChannelEmail;
    case VerificationChannelType.phone:
      return l10n.verificationChannelPhone;
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
    case VerificationChannelType.email:
      return LucideIcons.mail;
    case VerificationChannelType.phone:
      return LucideIcons.phone;
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
  // Email: a basic local@domain.tld shape.
  if (type == VerificationChannelType.email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
  // Phone: digits (optionally a leading +), spaces / dashes / parens allowed,
  // at least 6 digits.
  if (type == VerificationChannelType.phone) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return RegExp(r'^\+?[0-9\s().-]+$').hasMatch(value) && digits.length >= 6;
  }
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

/// Best-effort launch URI for a channel value (used by the public-icons rows).
/// Returns null when the value can't be turned into a launchable link.
Uri? channelLaunchUri(VerificationChannelType type, String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  switch (type) {
    case VerificationChannelType.email:
      return Uri(scheme: 'mailto', path: value);
    case VerificationChannelType.phone:
      final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
      return Uri(scheme: 'tel', path: digits);
    case VerificationChannelType.whatsapp:
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (value.startsWith('http')) return Uri.tryParse(value);
      return Uri.tryParse('https://wa.me/$digits');
    case VerificationChannelType.instagram:
      if (value.startsWith('http')) return Uri.tryParse(value);
      return Uri.tryParse(
        'https://instagram.com/${value.replaceFirst('@', '')}',
      );
    case VerificationChannelType.tiktok:
      if (value.startsWith('http')) return Uri.tryParse(value);
      return Uri.tryParse('https://tiktok.com/@${value.replaceFirst('@', '')}');
    case VerificationChannelType.telegram:
      if (value.startsWith('http')) return Uri.tryParse(value);
      return Uri.tryParse('https://t.me/${value.replaceFirst('@', '')}');
    case VerificationChannelType.strava:
    case VerificationChannelType.flaire:
    case VerificationChannelType.skool:
    case VerificationChannelType.website:
      if (value.startsWith('http')) return Uri.tryParse(value);
      return Uri.tryParse('https://$value');
  }
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
    this.showPublicToggle = false,
    this.minChannels = 0,
    this.allowedTypes,
  });

  /// The current channels.
  final List<VerificationChannel> channels;

  /// Called with the full updated list on any add / edit / remove / toggle.
  final ValueChanged<List<VerificationChannel>> onChanged;

  /// Whether to render the section label above the rows.
  final bool showLabel;

  /// Whether each row shows the public eye toggle (profile manage sheet only;
  /// onboarding omits it and sends is_public:false).
  final bool showPublicToggle;

  /// Minimum number of rows that must remain (remove is hidden at the floor).
  final int minChannels;

  /// Restrict the type dropdown + the add-default to this subset (e.g. the
  /// Contact group passes [email, phone]). Null = all types.
  final List<VerificationChannelType>? allowedTypes;

  List<VerificationChannelType> get _types =>
      allowedTypes ?? VerificationChannelType.values;

  void _addChannel() {
    // Default a new row to the first unused allowed type, else the first.
    final used = channels.map((c) => c.type).toSet();
    final next = _types.firstWhere(
      (t) => !used.contains(t),
      orElse: () => _types.first,
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
            allowedTypes: _types,
            showPublicToggle: showPublicToggle,
            canRemove: channels.length > minChannels,
            onTypeChanged: (type) =>
                _updateAt(i, channels[i].copyWith(type: type)),
            onUrlChanged: (url) => _updateAt(i, channels[i].copyWith(url: url)),
            onPublicChanged: (isPublic) =>
                _updateAt(i, channels[i].copyWith(isPublic: isPublic)),
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
    required this.onPublicChanged,
    required this.onRemove,
    required this.showPublicToggle,
    required this.canRemove,
    required this.allowedTypes,
    super.key,
  });

  final VerificationChannel channel;
  final List<VerificationChannelType> allowedTypes;
  final ValueChanged<VerificationChannelType> onTypeChanged;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<bool> onPublicChanged;
  final VoidCallback onRemove;
  final bool showPublicToggle;
  final bool canRemove;

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

  TextInputType get _keyboardType {
    switch (widget.channel.type) {
      case VerificationChannelType.email:
        return TextInputType.emailAddress;
      case VerificationChannelType.phone:
      case VerificationChannelType.whatsapp:
        return TextInputType.phone;
      default:
        return TextInputType.url;
    }
  }

  String _hint(AppLocalizations l10n) {
    switch (widget.channel.type) {
      case VerificationChannelType.email:
        return l10n.verificationChannelEmailHint;
      case VerificationChannelType.phone:
        return l10n.verificationChannelPhoneHint;
      default:
        return l10n.verificationChannelUrlHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = Row(
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
              for (final type in {widget.channel.type, ...widget.allowedTypes})
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
            keyboardType: _keyboardType,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: _hint(l10n),
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
        // Remove (hidden at the minimum floor)
        if (widget.canRemove)
          IconButton(
            tooltip: l10n.verificationRemoveChannel,
            onPressed: widget.onRemove,
            icon: Icon(LucideIcons.x, size: 18, color: context.colors.error),
          )
        else
          const SizedBox(width: 48),
      ],
    );

    if (!widget.showPublicToggle) return row;

    // Public eye toggle rendered under the row (manage sheet only).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        InkWell(
          onTap: () => widget.onPublicChanged(!widget.channel.isPublic),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: KolabingSpacing.xxs,
            ),
            child: Row(
              children: [
                Icon(
                  widget.channel.isPublic
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff,
                  size: 16,
                  color: widget.channel.isPublic
                      ? context.colors.primary
                      : context.colors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.verificationPublicToggleLabel,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Switch(
                  value: widget.channel.isPublic,
                  onChanged: widget.onPublicChanged,
                  activeThumbColor: context.colors.primary,
                  activeTrackColor: context.colors.primary.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
