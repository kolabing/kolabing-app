/// The offer card inside a Kolabing team message (SERR-658).
///
/// Wire shape: backend `KolabingTeamOfferResource`. [kind] is
/// `community_apply` (a community is offered a Kolab to apply to) or
/// `business_propose` (a business is offered a direct proposal to a community).
class KolabingTeamOffer {
  const KolabingTeamOffer({
    required this.id,
    required this.kind,
    required this.status,
    required this.title,
    this.message,
    this.kolabId,
    this.venueName,
    this.communityLabel,
    this.proposedDate,
    this.whatBusinessGets,
    this.whatCommunityGets,
    this.canRespond = false,
    this.resultKolabId,
    this.resultApplicationId,
  });

  factory KolabingTeamOffer.fromJson(Map<String, dynamic> json) =>
      KolabingTeamOffer(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? 'community_apply',
        status: json['status'] as String? ?? 'sent',
        title: json['title'] as String? ?? '',
        message: json['message'] as String?,
        kolabId: json['kolab_id'] as String?,
        venueName: json['venue_name'] as String?,
        communityLabel: json['community_label'] as String?,
        proposedDate: json['proposed_date'] != null
            ? DateTime.tryParse(json['proposed_date'] as String)
            : null,
        whatBusinessGets: json['what_business_gets'] as String?,
        whatCommunityGets: json['what_community_gets'] as String?,
        canRespond: json['can_respond'] as bool? ?? false,
        resultKolabId: json['result_kolab_id'] as String?,
        resultApplicationId: json['result_application_id'] as String?,
      );

  final String id;
  final String kind;

  /// `sent` (open), `accepted` or `declined`.
  final String status;
  final String title;
  final String? message;
  final String? kolabId;
  final String? venueName;

  /// For a business offer: the community's name when the viewer may see it,
  /// otherwise a generic label. Always the backend's choice, never ours.
  final String? communityLabel;
  final DateTime? proposedDate;
  final String? whatBusinessGets;
  final String? whatCommunityGets;

  /// True while Accept / Not now are still available.
  final bool canRespond;
  final String? resultKolabId;
  final String? resultApplicationId;

  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}
