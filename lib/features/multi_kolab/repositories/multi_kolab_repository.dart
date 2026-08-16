import '../models/child_kolab_result.dart';
import '../models/event_creator_entitlement.dart';
import '../models/multi_kolab_dashboard.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_event_summary.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';

/// The single seam every Multi-Kolab screen depends on. Screens/providers
/// must never talk to `http`/`ApiMultiKolabRepository` directly — only this
/// interface — so mock-backed UI development and the real API integration
/// can proceed independently (see the plan's weekend-development strategy).
abstract interface class MultiKolabRepository {
  Future<MultiKolabEvent> createDraft(CreateMultiKolabEventInput input);

  Future<MultiKolabEvent> updateDraft(
    String eventId,
    UpdateMultiKolabEventInput input,
  );

  Future<MultiKolabRole> addRole(
    String eventId,
    CreateMultiKolabRoleInput input,
  );

  Future<MultiKolabEvent> publish(String eventId);

  Future<List<MultiKolabEventSummary>> explore(MultiKolabExploreFilter filter);

  /// The authenticated profile's own events, any status.
  Future<List<MultiKolabEventSummary>> myEvents();

  Future<MultiKolabEvent> getEvent(String eventId);

  Future<MultiKolabRoleApplication> apply(
    String roleId,
    CreateMultiKolabApplicationInput input,
  );

  Future<MultiKolabDashboard> getDashboard(String eventId);

  Future<MultiKolabRoleApplication> shortlist(String applicationId);

  Future<ChildKolabResult> accept(String applicationId);

  Future<MultiKolabRoleApplication> decline(String applicationId);

  Future<void> withdraw(String applicationId, String reason);

  Future<void> cancelEvent(String eventId, String reason);

  Future<EventCreatorEntitlement> getEntitlement();
}
