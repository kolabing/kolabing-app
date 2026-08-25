import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/event_ticket.dart';
import '../services/ticket_service.dart';

final ticketServiceProvider = Provider<TicketService>((ref) {
  return TicketService(authService: ref.watch(authServiceProvider));
});

/// The caller's whole ticket wallet.
final myTicketsProvider = FutureProvider<List<EventTicket>>((ref) async {
  return ref.watch(ticketServiceProvider).myTickets();
});

/// The caller's ticket for one event, or null when they hold none.
///
/// Null is the ordinary case, not an error: someone browsing an event they have
/// not signed up for has no ticket, and neither does anyone at all until the
/// backend's ticket route is deployed. The page shows no *My ticket* button in
/// either case rather than a disabled button with a mystery behind it.
final myTicketForEventProvider = FutureProvider.family<EventTicket?, String>((
  ref,
  eventId,
) async {
  try {
    final tickets = await ref.watch(myTicketsProvider.future);
    for (final ticket in tickets) {
      if (ticket.event?.id == eventId) return ticket;
    }
    return null;
  } on TicketException {
    return null;
  }
});
