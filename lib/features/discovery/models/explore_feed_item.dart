import 'package:flutter/foundation.dart';

import '../../multi_kolab/models/multi_kolab_role_offer.dart';
import 'discovery_item.dart';

/// One entry of the Explore feed.
///
/// The discovery endpoint returns a HETEROGENEOUS list: ordinary Kolab
/// offers and open Multi-Kolab partner roles, interleaved. This sealed union
/// is the only sanctioned way to tell them apart — nothing downstream may
/// branch on title text, overload an id, or coerce a role into a fake
/// ordinary offer.
@immutable
sealed class ExploreFeedItem {
  const ExploreFeedItem();

  /// Parses one feed entry, dispatching on the backend's `item_type`
  /// discriminator. Entries without the discriminator are ordinary offers —
  /// which keeps the client compatible with the pre-Multi-Kolab payload.
  factory ExploreFeedItem.fromJson(Map<String, dynamic> json) {
    if (MultiKolabRoleOffer.isMultiKolabRoleJson(json)) {
      return ExploreMultiKolabRoleItem(MultiKolabRoleOffer.fromJson(json));
    }
    return ExploreOfferItem(DiscoveryItem.fromJson(json));
  }

  /// Stable, type-qualified identity for widget keys and de-duplication.
  /// Type-qualified so an ordinary offer id can never collide with a role id.
  String get feedKey;

  /// The profile that authored this item, used by the shared ownership and
  /// block filters. Empty when unknown.
  String get creatorProfileId;
}

/// An ordinary Kolab offer (the pre-existing Explore card).
final class ExploreOfferItem extends ExploreFeedItem {
  const ExploreOfferItem(this.offer);

  final DiscoveryItem offer;

  @override
  String get feedKey => 'offer:${offer.id}';

  @override
  String get creatorProfileId => offer.creatorProfile.id;
}

/// One open Multi-Kolab partner role, shown as a single offer card.
final class ExploreMultiKolabRoleItem extends ExploreFeedItem {
  const ExploreMultiKolabRoleItem(this.role);

  final MultiKolabRoleOffer role;

  @override
  String get feedKey => 'multi-kolab-role:${role.roleId}';

  @override
  String get creatorProfileId => role.organizerProfileId ?? '';
}
