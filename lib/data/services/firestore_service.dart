import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guest_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ─────────────────────────────────────────────
  CollectionReference get _events => _db.collection('events');
  CollectionReference _guests(String eventId) =>
      _db.collection('events').doc(eventId).collection('guests');

  // ─── Event CRUD ──────────────────────────────────────────────
  Future<String> createEvent(EventModel event) async {
    final ref = await _events.add(event.toFirestore());
    return ref.id;
  }

  Future<void> updateEvent(EventModel event) =>
      _events.doc(event.id).update(event.toFirestore());

  Stream<EventModel?> watchEvent(String eventId) =>
      _events.doc(eventId).snapshots().map((snap) {
        if (!snap.exists) return null;
        return EventModel.fromFirestore(
          snap.data() as Map<String, dynamic>,
          snap.id,
        );
      });

  Stream<List<EventModel>> watchUserEvents(String userId) =>
      _events
          .where('organizerId', isEqualTo: userId)
          .orderBy('dateMs', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => EventModel.fromFirestore(
                    d.data() as Map<String, dynamic>,
                    d.id,
                  ))
              .toList());

  // ─── Guest CRUD ──────────────────────────────────────────────
  Future<String> addGuest(String eventId, GuestModel guest) async {
    final ref = await _guests(eventId).add(guest.toFirestore());
    return ref.id;
  }

  Future<void> updateGuest(String eventId, GuestModel guest) =>
      _guests(eventId).doc(guest.id).update(guest.toFirestore());

  Future<void> deleteGuest(String eventId, String guestId) =>
      _guests(eventId).doc(guestId).delete();

  /// Real-time stream of all guests for an event
  Stream<List<GuestModel>> watchGuests(String eventId) =>
      _guests(eventId).snapshots().map((snap) => snap.docs
          .map((d) => GuestModel.fromFirestore(
                d.data() as Map<String, dynamic>,
                d.id,
              ))
          .toList());

  /// Atomic update: guest status
  Future<void> updateGuestStatus(
    String eventId,
    String guestId,
    GuestStatus status,
  ) async {
    await _guests(eventId).doc(guestId).update({'status': status.name});
  }

  /// Atomic update: table assignment
  Future<void> assignTable(
    String eventId,
    String guestId,
    String? tableId,
  ) async {
    await _guests(eventId).doc(guestId).update({'tableId': tableId});
  }

  /// Atomic update: budget spent
  Future<void> updateBudgetSpent(String eventId, double amount) async {
    await _events.doc(eventId).update({'budgetSpent': amount});
  }

  /// Bulk RSVP confirmation (used from web PWA)
  Future<void> confirmGuest(String eventId, String guestId) async {
    await _guests(eventId).doc(guestId).update({
      'status': GuestStatus.confirmed.name,
    });
  }
}
