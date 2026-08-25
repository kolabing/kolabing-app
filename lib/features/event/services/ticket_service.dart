import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/event_ticket.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Raised when the ticket wallet cannot be read. [isUnavailable] separates a
/// backend that has not deployed tickets yet from one that refused this caller
/// — the first is a reason to show nothing, the second a reason to say why.
class TicketException implements Exception {
  const TicketException(this.message, {this.isUnavailable = false});

  final String message;
  final bool isUnavailable;

  @override
  String toString() => message;
}

/// The holder's ticket wallet.
///
/// There is no "ticket for event X" endpoint, and adding one for the sake of a
/// single screen would be the wrong trade: `GET /me/tickets` is already scoped
/// to the caller and returns few enough rows to filter on the client.
class TicketService {
  TicketService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Every ticket the caller holds. `GET /api/v1/me/tickets`.
  Future<List<EventTicket>> myTickets() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const TicketException('Not authenticated');
    }

    final url = '$_baseUrl/me/tickets';
    debugPrint('🎟️ My tickets: GET $url');

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    debugPrint('🎟️ My tickets response status: ${response.statusCode}');

    if (response.statusCode == 404) {
      // Self-gated: the route ships in parallel with this screen.
      throw const TicketException('Tickets unavailable', isUnavailable: true);
    }
    if (response.statusCode != 200) {
      throw TicketException('Could not load tickets (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(EventTicket.fromJson)
        .toList();
  }

  /// One ticket by its code. `GET /api/v1/tickets/{code}`.
  ///
  /// Readable by the holder and the event's host, which is what makes the door
  /// work: the scanner is authorised, not the code.
  Future<EventTicket> byCode(String code) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const TicketException('Not authenticated');
    }

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/tickets/$code'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 404) {
      throw const TicketException('Ticket not found', isUnavailable: true);
    }
    if (response.statusCode != 200) {
      throw TicketException('Could not load ticket (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return EventTicket.fromJson(body['data'] as Map<String, dynamic>);
  }
}
