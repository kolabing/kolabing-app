import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../features/discovery/models/discovery_item.dart';
import '../features/multi_kolab/models/multi_kolab_enums.dart';
import '../features/multi_kolab/models/multi_kolab_role_offer.dart';
import '../l10n/app_localizations.dart';

/// The resolved, presentation-ready content of ONE Explore offer card.
///
/// Both ordinary Kolab offers and Multi-Kolab partner roles are rendered by
/// the single [ExploreSwipeCard] widget; they differ only in how this view
/// model is built. That keeps one visual hierarchy, one spacing/colour/type
/// scale, one image + fallback treatment and one match-badge implementation
/// for every card in the feed.
@immutable
class ExploreCardData {
  const ExploreCardData({
    required this.title,
    required this.metaLocation,
    this.imageUrls = const <String>[],
    this.identityLogoUrl,
    this.fallbackInitial = '?',
    this.matchScore,
    this.showMultiKolabBadge = false,
    this.metaPrimary,
    this.offerLine,
    this.chips = const <String>[],
  });

  /// Ordinary Kolab offer — the pre-existing card content, unchanged.
  factory ExploreCardData.fromOffer(
    DiscoveryItem item, {
    required AppLocalizations l10n,
    required bool showKolabFirst,
    required bool hideCreatorIdentity,
  }) {
    final isBusinessExploreCommunityCard =
        showKolabFirst && item.isCommunityRequest;
    final badges = item.primaryBadges;
    final cover = item.coverPhotoUrl;
    final avatar = item.creatorProfile.avatarUrl;

    final imageUrls = <String>[];
    if (cover != null && cover.isNotEmpty) {
      imageUrls.add(cover);
    } else if (avatar != null && avatar.isNotEmpty) {
      imageUrls.add(avatar);
    }

    // Only an avatar used AS the cover fallback counts as the identity logo
    // (that's the image the paywall blurs).
    final usingAvatarFallback = cover == null || cover.isEmpty;
    final identityLogoUrl =
        usingAvatarFallback && avatar != null && avatar.isNotEmpty
        ? avatar
        : null;

    return ExploreCardData(
      title: item.creatorProfile.displayName,
      metaPrimary: badges.isNotEmpty
          ? badges.first
          : (item.isBusinessOffer
                ? l10n.exploreSwipeCardBusinessOffer
                : l10n.exploreSwipeCardCommunityRequest),
      metaLocation: item.locationLabel,
      imageUrls: imageUrls,
      identityLogoUrl: identityLogoUrl,
      fallbackInitial:
          !hideCreatorIdentity && item.creatorProfile.displayName.isNotEmpty
          ? item.creatorProfile.displayName[0].toUpperCase()
          : '?',
      matchScore: item.match?.score,
      offerLine: isBusinessExploreCommunityCard
          ? item.communityOfferLine
          : item.displayHeadline,
      chips: badges,
    );
  }

  /// One open Multi-Kolab partner role, mapped onto the same card slots:
  /// role title is the primary title, the parent event + city form the meta
  /// row, the structured "looking for" copy takes the offer line, and the
  /// remaining supporting facts become chips.
  factory ExploreCardData.fromMultiKolabRole(
    MultiKolabRoleOffer role, {
    required AppLocalizations l10n,
  }) {
    final cover = role.coverPhotoUrl;
    final avatar = role.organizerAvatarUrl;
    final imageUrls = <String>[];
    if (cover != null && cover.isNotEmpty) {
      imageUrls.add(cover);
    } else if (avatar != null && avatar.isNotEmpty) {
      imageUrls.add(avatar);
    }

    final chips = <String>[
      // Only worth showing when the role genuinely has several positions —
      // "1 spot open" on a single-position role is noise.
      if (role.positionsNeeded > 1 && role.positionsRemaining > 0)
        l10n.multiKolabRoleSpotsOpen(role.positionsRemaining),
      if (role.compensationType case final compensation?)
        multiKolabCompensationLabel(compensation, l10n),
      if (multiKolabRoleDateLabel(role) case final dateLabel?) dateLabel,
      if (role.viewerHasApplied) l10n.multiKolabRoleAppliedChip,
    ];

    final initialSource = role.eventTitle.trim().isNotEmpty
        ? role.eventTitle.trim()
        : role.roleTitle.trim();

    return ExploreCardData(
      title: role.roleTitle,
      metaPrimary: role.eventTitle.isNotEmpty ? role.eventTitle : null,
      metaLocation: role.city ?? '',
      imageUrls: imageUrls,
      fallbackInitial: initialSource.isNotEmpty
          ? initialSource[0].toUpperCase()
          : '?',
      matchScore: role.matchScore,
      showMultiKolabBadge: true,
      offerLine: multiKolabRolePartnerRequestCopy(role, l10n),
      chips: chips,
    );
  }

  final String title;

  /// Leading half of the secondary meta row (ordinary: category; role:
  /// parent event title).
  final String? metaPrimary;
  final String metaLocation;
  final List<String> imageUrls;

  /// The image (if any) that represents the creator's identity and must be
  /// blurred behind the business paywall. Null when no image is identity.
  final String? identityLogoUrl;
  final String fallbackInitial;
  final int? matchScore;
  final bool showMultiKolabBadge;
  final String? offerLine;
  final List<String> chips;
}

/// The structured "looking for X" copy for a role.
///
/// Built entirely from structured data — a `{key,label}` partner-type
/// request when the organizer named one, otherwise an open-ended line
/// derived from the role's eligible account type. Never parsed out of the
/// role's free-text fields.
String multiKolabRolePartnerRequestCopy(
  MultiKolabRoleOffer role,
  AppLocalizations l10n,
) {
  final lookingFor = role.lookingFor;
  if (lookingFor != null) {
    return l10n.multiKolabRoleLookingFor(lookingFor.label);
  }
  return switch (role.eligibleAccountType) {
    MultiKolabEligibleAccountType.business =>
      l10n.multiKolabRoleOpenToAnyBusiness,
    MultiKolabEligibleAccountType.community =>
      l10n.multiKolabRoleOpenToAnyCommunity,
    MultiKolabEligibleAccountType.either => l10n.multiKolabRoleOpenToAnyPartner,
  };
}

String multiKolabCompensationLabel(
  MultiKolabCompensationType type,
  AppLocalizations l10n,
) => switch (type) {
  MultiKolabCompensationType.paid => l10n.multiKolabCompensationPaid,
  MultiKolabCompensationType.sponsoredInKind =>
    l10n.multiKolabCompensationSponsoredInKind,
  MultiKolabCompensationType.valueExchange =>
    l10n.multiKolabCompensationValueExchange,
  MultiKolabCompensationType.negotiable =>
    l10n.multiKolabCompensationNegotiable,
};

/// Prefers the backend's pre-formatted availability copy, falling back to a
/// short formatted event date. Null when the role carries neither.
String? multiKolabRoleDateLabel(MultiKolabRoleOffer role) {
  final label = role.availabilityLabel?.trim();
  if (label != null && label.isNotEmpty) return label;
  final date = role.eventDate;
  if (date == null) return null;
  return DateFormat.MMMd().format(date);
}
