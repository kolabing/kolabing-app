/// Wire-value enums for the Multi-Kolab Event MVP. Values match the backend
/// contract exactly (`docs/superpowers/specs/2026-08-12-multi-kolab-event-api-contract.md`
/// in `kolabing-v2`) — never invent a value here that the backend doesn't emit.
library;

enum MultiKolabEventStatus {
  draft,
  recruiting,
  confirmed,
  completed,
  cancelled,
  expired;

  String toApiValue() => name;

  static MultiKolabEventStatus fromApiValue(String value) {
    return MultiKolabEventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MultiKolabEventStatus.draft,
    );
  }
}

enum MultiKolabRoleStatus {
  open,
  filled,
  closed;

  String toApiValue() => name;

  static MultiKolabRoleStatus fromApiValue(String value) {
    return MultiKolabRoleStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MultiKolabRoleStatus.open,
    );
  }
}

enum MultiKolabRoleApplicationStatus {
  pending,
  shortlisted,
  accepted,
  declined,
  withdrawn;

  String toApiValue() => name;

  static MultiKolabRoleApplicationStatus fromApiValue(String value) {
    return MultiKolabRoleApplicationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MultiKolabRoleApplicationStatus.pending,
    );
  }
}

enum MultiKolabEligibleAccountType {
  business,
  community,
  either;

  String toApiValue() => name;

  static MultiKolabEligibleAccountType fromApiValue(String value) {
    return MultiKolabEligibleAccountType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MultiKolabEligibleAccountType.either,
    );
  }
}

enum MultiKolabCompensationType {
  paid,
  sponsoredInKind,
  valueExchange,
  negotiable;

  String toApiValue() {
    switch (this) {
      case MultiKolabCompensationType.paid:
        return 'paid';
      case MultiKolabCompensationType.sponsoredInKind:
        return 'sponsored_in_kind';
      case MultiKolabCompensationType.valueExchange:
        return 'value_exchange';
      case MultiKolabCompensationType.negotiable:
        return 'negotiable';
    }
  }

  static MultiKolabCompensationType? fromApiValue(String? value) {
    switch (value) {
      case 'paid':
        return MultiKolabCompensationType.paid;
      case 'sponsored_in_kind':
        return MultiKolabCompensationType.sponsoredInKind;
      case 'value_exchange':
        return MultiKolabCompensationType.valueExchange;
      case 'negotiable':
        return MultiKolabCompensationType.negotiable;
      default:
        return null;
    }
  }
}

/// `exact` (uses eventDate) or `range` (uses dateRangeStart/End).
enum MultiKolabDateMode {
  exact,
  range;

  String toApiValue() => name;

  static MultiKolabDateMode? fromApiValue(String? value) {
    switch (value) {
      case 'exact':
        return MultiKolabDateMode.exact;
      case 'range':
        return MultiKolabDateMode.range;
      default:
        return null;
    }
  }
}
