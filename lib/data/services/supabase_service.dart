import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../models/guest_model.dart';
import '../models/event_model.dart';
import '../models/collaborator_model.dart';
import '../models/table_model.dart';
import '../models/seating_assignment_model.dart';
import '../models/seating_data_model.dart';
import '../models/venue_element_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // ─── Profile CRUD ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data;
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // ─── Event CRUD ──────────────────────────────────────────────
  Future<String> createEvent(EventModel event) async {
    final data = await _client.from('events').insert(event.toJson()).select('id').single();
    return data['id'];
  }

  Future<void> updateEvent(EventModel event) async {
    await _client.from('events').update(event.toJson()).eq('id', event.id);
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Stream<EventModel?> watchEvent(String eventId) {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((json) => json['id'] == eventId)
            .map((json) => EventModel.fromJson(json))
            .firstOrNull);
  }

  Stream<List<EventModel>> watchUserEvents(String userId) {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .map((list) {
          final filtered = list.where((json) => 
            json['organizer_id'] == userId || 
            (json['collaborator_ids'] as List?)?.contains(userId) == true
          ).toList();
          // Ordenar manualmente por date_ms
          filtered.sort((a, b) => (a['date_ms'] ?? 0).compareTo(b['date_ms'] ?? 0));
          return filtered.map((json) => EventModel.fromJson(json)).toList();
        });
  }

  Future<void> updateEventTemplate(String eventId, String template) async {
    await _client.from('events').update({'whatsapp_template': template}).eq('id', eventId);
  }

  Future<void> updateEventEmailConfig(String eventId, String email, String subject) async {
    await _client.from('events').update({
      'email_template': email,
      'email_subject': subject,
    }).eq('id', eventId);
  }

  // ─── Guest CRUD ──────────────────────────────────────────────
  Future<String> addGuest(String eventId, GuestModel guest) async {
    final data = await _client.from('guests').insert(guest.toJson()).select('id').single();
    return data['id'];
  }

  Future<void> updateGuest(String eventId, GuestModel guest) async {
    await _client.from('guests').update(guest.toJson()).eq('id', guest.id);
  }

  Future<void> updateGuestStatus(String eventId, String guestId, GuestStatus status) async {
    await _client.from('guests').update({'status': status.name}).eq('id', guestId);
  }

  Future<void> deleteGuest(String eventId, String guestId) async {
    await _client.from('guests').delete().eq('id', guestId);
  }

  Stream<List<GuestModel>> watchGuests(String eventId) {
    return _client
        .from('guests')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((json) => json['event_id'] == eventId)
            .map((json) => GuestModel.fromJson(json))
            .toList());
  }

  // ─── Table CRUD ──────────────────────────────────────────────
  Future<String> addTable(String eventId, TableModel table) async {
    final data = await _client.from('tables').insert(table.toJson()).select('id').single();
    return data['id'];
  }

  Future<void> updateTable(String eventId, TableModel table) async {
    await _client.from('tables').update(table.toJson()).eq('id', table.id);
  }

  Future<void> updateTablePosition(String eventId, String tableId, double x, double y) async {
    await _client.from('tables').update({'pos_x': x, 'pos_y': y}).eq('id', tableId);
  }

  Future<void> deleteTable(String eventId, String tableId) async {
    await _client.from('tables').delete().eq('id', tableId);
  }

  Stream<List<TableModel>> watchTables(String eventId) {
    return _client
        .from('tables')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((json) => json['event_id'] == eventId)
            .map((json) => TableModel.fromJson(json))
            .toList());
  }

  // ─── Venue Element CRUD ──────────────────────────────────────
  Future<String> addVenueElement(String eventId, VenueElementModel element) async {
    final data = await _client.from('venue_elements').insert(element.toJson()).select('id').single();
    return data['id'];
  }

  Future<void> updateVenueElement(String eventId, VenueElementModel element) async {
    await _client.from('venue_elements').update(element.toJson()).eq('id', element.id);
  }

  Future<void> updateVenueElementPosition(String eventId, String elementId, double x, double y) async {
    await _client.from('venue_elements').update({'pos_x': x, 'pos_y': y}).eq('id', elementId);
  }

  Future<void> deleteVenueElement(String eventId, String elementId) async {
    await _client.from('venue_elements').delete().eq('id', elementId);
  }

  Stream<List<VenueElementModel>> watchVenueElements(String eventId) {
    return _client
        .from('venue_elements')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((json) => json['event_id'] == eventId)
            .map((json) => VenueElementModel.fromJson(json))
            .toList());
  }

  // ─── Seating Assignment ──────────────────────────
  Stream<List<SeatingAssignment>> watchAssignments(String eventId) {
    return _client
        .from('seating_assignments')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((json) => json['event_id'] == eventId)
            .map((json) => SeatingAssignment.fromJson(json))
            .toList());
  }

  Future<void> addAssignment(String eventId, SeatingAssignment assignment) async {
    await _client.from('seating_assignments').insert(assignment.toJson());
  }

  Future<void> updateAssignment(String eventId, SeatingAssignment assignment) async {
    await _client.from('seating_assignments').update(assignment.toJson()).eq('id', assignment.id);
  }

  Future<void> deleteAssignment(String eventId, String assignmentId) async {
    await _client.from('seating_assignments').delete().eq('id', assignmentId);
  }

  // ─── Collaboration ───────────────────────────────────────────
  Future<String> generateInviteCode(String eventId) async {
    final code = 'PLA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    await _client.from('events').update({'invite_code': code}).eq('id', eventId);
    return code;
  }

  Future<void> approveCollaborator(String id, CollaboratorRole role) async {
    await _client.from('collaborators').update({
      'status': 'approved',
      'role': role.name,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> rejectCollaborator(String id) async {
    await _client.from('collaborators').update({
      'status': 'rejected',
    }).eq('id', id);
  }

  Future<void> removeCollaborator(String id) async {
    await _client.from('collaborators').delete().eq('id', id);
  }

  Future<void> updateCollaboratorRole(String id, CollaboratorRole role) async {
    await _client.from('collaborators').update({
      'role': role.name,
    }).eq('id', id);
  }

  Stream<List<CollaboratorModel>> watchCollaborators(String eventId) {
    return _client
        .from('collaborators')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((list) => list.map((json) => CollaboratorModel.fromJson(json)).toList());
  }

  Stream<List<Map<String, dynamic>>> watchReceivedInvitations(String email) {
    // Escuchamos cambios en colaboradores invitados con este correo
    return _client
        .from('collaborators')
        .stream(primaryKey: ['id'])
        .asyncMap((list) async {
          final filtered = list.where((json) => 
            json['email'] == email && json['status'] == 'invited'
          ).toList();
          final enriched = <Map<String, dynamic>>[];
          for (var item in filtered) {
            final eventId = item['event_id'];
            String eventName = 'Evento Desconocido';
            try {
              final eventRes = await _client.from('events').select('name').eq('id', eventId).maybeSingle();
              if (eventRes != null) eventName = eventRes['name'];
            } catch (_) {}
            
            enriched.add({
              'collaborator': CollaboratorModel.fromJson(item),
              'event_name': eventName,
            });
          }
          return enriched;
        });
  }

  Future<void> acceptInvitation({
    required String id,
    required String userId,
    required String displayName,
    String? photoUrl,
  }) async {
    // 1. Obtener el event_id de la invitación
    final collabRes = await _client.from('collaborators').select('event_id').eq('id', id).single();
    final eventId = collabRes['event_id'];

    // 2. Actualizar el registro del colaborador
    await _client.from('collaborators').update({
      'user_id': userId,
      'display_name': displayName,
      'photo_url': photoUrl,
      'status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    // 3. Sincronizar con la tabla de eventos (añadir al array de IDs)
    final eventRes = await _client.from('events').select('collaborator_ids').eq('id', eventId).single();
    List<String> ids = List<String>.from(eventRes['collaborator_ids'] ?? []);
    if (!ids.contains(userId)) {
      ids.add(userId);
      await _client.from('events').update({'collaborator_ids': ids}).eq('id', eventId);
    }
  }

  Stream<List<CollaboratorModel>> watchPendingRequests(String eventId) {
    return _client
        .from('collaborators')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((json) => json['event_id'] == eventId && json['status'] == 'pending')
            .map((json) => CollaboratorModel.fromJson(json))
            .toList());
  }

  Future<void> inviteByEmail({
    required String eventId,
    required String email,
    required CollaboratorRole role,
    required String inviterName,
  }) async {
    await _client.from('collaborators').insert({
      'event_id': eventId,
      'email': email,
      'role': role.name,
      'status': 'invited',
      'display_name': email.split('@').first,
      'invited_by': inviterName,
    });
  }

  Future<EventModel?> findEventByInviteCode(String code) async {
    final list = await _client.from('events').select().eq('invite_code', code);
    if (list.isEmpty) return null;
    return EventModel.fromJson(list.first);
  }

  Future<void> requestJoinEvent({
    required String eventId,
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    await _client.from('collaborators').insert({
      'event_id': eventId,
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'status': 'pending',
      'role': 'viewer',
    });
  }

  // ─── Consolidated Seating Stream ─────────────────────────────
  Stream<SeatingData> watchSeatingData(String eventId) {
    if (eventId.isEmpty) {
      return Stream.value(SeatingData(tables: [], guests: [], assignments: [], venueElements: []));
    }
    
    return CombineLatestStream.combine4(
      watchTables(eventId).onErrorReturn([]),
      watchGuests(eventId).onErrorReturn([]),
      watchAssignments(eventId).onErrorReturn([]),
      watchVenueElements(eventId).onErrorReturn([]),
      (tables, guests, assignments, venueElements) => SeatingData(
        tables: tables,
        guests: guests,
        assignments: assignments,
        venueElements: venueElements,
      ),
    ).distinct();
  }
}
