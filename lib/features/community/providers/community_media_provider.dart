import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../profile/providers/gallery_provider.dart';
import '../../profile/providers/public_profile_provider.dart';

/// Which community's photos, and whose profile might hold the curated ones.
typedef CommunityMediaKey = ({String communityId, String? ownerProfileId});

/// Photos for a community.
///
/// A community has no photo table of its own, and inventing one for a first
/// pass would have delayed every other thing this page needed. Two real sources
/// exist instead, in priority order:
///
/// 1. the **curated gallery** on the community owner's profile — already
///    uploadable, reorderable and public (`GET /profiles/{id}/gallery`), so a
///    leader who cares can choose exactly what a visitor sees;
/// 2. failing that, photos from the community's **own events**, newest first —
///    which means an active community is never photoless, without anyone
///    uploading anything twice.
///
/// The known limit: the curated set belongs to the leader's profile, not to the
/// community, so a leader running two communities would show the same photos on
/// both. That is the price of not adding a table yet, and it is written down in
/// `docs/superpowers/specs/2026-08-24-community-page-v2-design.md`.
final communityPhotosProvider =
    Provider.family<List<GalleryPhoto>, CommunityMediaKey>((ref, key) {
      final owner = key.ownerProfileId;
      if (owner != null && owner.isNotEmpty) {
        final curated = ref
            .watch(publicProfileProvider(owner))
            .maybeWhen(
              data: (profile) => profile.gallery,
              orElse: () => const <GalleryPhoto>[],
            );
        if (curated.isNotEmpty) return curated;
      }

      final events = <Event>[
        ...ref
            .watch(communityUpcomingEventsProvider(key.communityId))
            .maybeWhen(data: (e) => e, orElse: () => const <Event>[]),
        ...ref
            .watch(communityPastEventsProvider(key.communityId))
            .maybeWhen(data: (e) => e, orElse: () => const <Event>[]),
      ]..sort((a, b) => (b.startsAt ?? b.date).compareTo(a.startsAt ?? a.date));

      final seen = <String>{};
      final photos = <GalleryPhoto>[];
      for (final event in events) {
        for (final photo in event.photos) {
          if (!seen.add(photo.url)) continue;
          photos.add(
            GalleryPhoto.fromUrl(
              id: photo.id,
              rawUrl: photo.url,
              caption: event.name,
              sortOrder: photos.length,
            ),
          );
        }
      }
      return photos;
    });

/// The single photo the cover band should paint, if any.
final communityCoverPhotoProvider = Provider.family<String?, CommunityMediaKey>(
  (ref, key) {
    final photos = ref.watch(communityPhotosProvider(key));
    return photos.isEmpty ? null : photos.first.url;
  },
);
