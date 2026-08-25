import 'package:flutter/foundation.dart';

import 'multi_kolab_enums.dart';
import 'multi_kolab_role.dart';

/// Event-level capacity expressed in PARTNER SPOTS, not in role records.
///
/// The API's `role_counts` block counts rows in `multi_kolab_roles`
/// (`{total, open, filled}`), which is why the old copy read "0 of 1 roles
/// filled" for an event whose single role was recruiting three partners. A
/// role is a slot *type* ("Content creator"); `positions_needed` is how many
/// partners that slot type takes. Organizers plan in partners, so every
/// event-level capacity line is derived here from the roles themselves.
@immutable
class MultiKolabSpotCounts {
  const MultiKolabSpotCounts({
    required this.filled,
    required this.total,
    required this.openRoles,
  });

  /// Summed `positions_filled` / `positions_needed` across every role, plus
  /// the number of roles still recruiting.
  factory MultiKolabSpotCounts.fromRoles(Iterable<MultiKolabRole> roles) {
    var filled = 0;
    var total = 0;
    var openRoles = 0;

    for (final role in roles) {
      // `positions_filled` can only be raised by an acceptance, so it counts
      // even on a role the organizer has since closed — those partners are
      // confirmed and the event really does have them.
      filled += role.positionsFilled;
      total += role.positionsNeeded;

      // One role is one open role however many partners it still takes:
      // a "Content creator" role with two free spots is not two open roles.
      // A `filled`/`closed` role is never recruiting, and the backend flips a
      // role to `filled` once capacity is reached, so the remaining-capacity
      // check is belt and braces against a stale payload.
      if (role.status == MultiKolabRoleStatus.open &&
          role.positionsRemaining > 0) {
        openRoles++;
      }
    }

    return MultiKolabSpotCounts(
      filled: filled,
      total: total,
      openRoles: openRoles,
    );
  }

  /// Partner positions already confirmed across the whole event.
  final int filled;

  /// Partner positions the event needs in total.
  final int total;

  /// Roles still accepting applications.
  final int openRoles;

  bool get isFullyStaffed => total > 0 && filled >= total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MultiKolabSpotCounts &&
          filled == other.filled &&
          total == other.total &&
          openRoles == other.openRoles);

  @override
  int get hashCode => Object.hash(filled, total, openRoles);

  @override
  String toString() =>
      'MultiKolabSpotCounts(filled: $filled, total: $total, '
      'openRoles: $openRoles)';
}
