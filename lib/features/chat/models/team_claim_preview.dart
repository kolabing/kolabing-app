import 'kolabing_team_offer.dart';

/// What the claim screen shows before the owner signs in (SERR-1344): the offer
/// card and whose page it is. Wire shape: backend
/// `GET /kolabing-team/claim/{token}`.
class TeamClaimPreview {
  const TeamClaimPreview({
    required this.offer,
    required this.profileName,
    required this.profileType,
    required this.expired,
    required this.claimable,
  });

  factory TeamClaimPreview.fromJson(Map<String, dynamic> json) =>
      TeamClaimPreview(
        offer: KolabingTeamOffer.fromJson(
          json['offer'] as Map<String, dynamic>,
        ),
        profileName: json['profile_name'] as String? ?? '',
        profileType: json['profile_type'] as String? ?? '',
        expired: json['expired'] as bool? ?? false,
        claimable: json['claimable'] as bool? ?? false,
      );

  final KolabingTeamOffer offer;
  final String profileName;

  /// `business` or `community`.
  final String profileType;
  final bool expired;
  final bool claimable;
}
