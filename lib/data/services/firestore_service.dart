import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guest_model.dart';
import '../models/event_model.dart';
import '../models/collaborator_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ─────────────────────────────────────────────
  CollectionReference get _events => _db.collection('events');
  CollectionReference _guests(String eventId) =>
      _db.collection('events').doc(eventId).collection('guests');
  CollectionReference _collaborators(String eventId) =>
      _db.collection('events').doc(eventId).collection('collaborators');

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

  Stream<List<EventModel>> watchUserEvents(String userId) {
    final ownedStream = _events
        .where('organizerId', isEqualTo: userId)
        .orderBy('dateMs', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventModel.fromFirestore(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ))
            .toList());

    final collaborativeStream = _events
        .where('collaboratorIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventModel.fromFirestore(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ))
            .toList());

    // Merge both streams into a single combined list
    return ownedStream.asyncExpand((ownedEvents) {
      return collaborativeStream.map((collabEvents) {
        final allEvents = [...ownedEvents];
        for (final ce in collabEvents) {
          if (!allEvents.any((e) => e.id == ce.id)) {
            allEvents.add(ce);
          }
        }
        allEvents.sort((a, b) => a.date.compareTo(b.date));
        return allEvents;
      });
    });
  }

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

  // ─── Collaboration ───────────────────────────────────────────

  /// Generate a unique 9-character invite code (PLA-XXXXXX)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'PLA-$code';
  }

  /// Generate and save invite code for an event
  Future<String> generateInviteCode(String eventId) async {
    final code = _generateInviteCode();
    await _events.doc(eventId).update({'inviteCode': code});
    return code;
  }

  /// Find event by invite code
  Future<EventModel?> findEventByInviteCode(String code) async {
    final snap = await _events
        .where('inviteCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return EventModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  /// Request to join an event (status = pending)
  Future<void> requestJoinEvent({
    required String eventId,
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    // Check if already a collaborator
    final existing = await _collaborators(eventId).doc(userId).get();
    if (existing.exists) return;

    final collaborator = CollaboratorModel(
      id: userId,
      userId: userId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: CollaboratorRole.viewer,
      status: CollaboratorStatus.pending,
      requestedAt: DateTime.now(),
    );
    await _collaborators(eventId).doc(userId).set(collaborator.toFirestore());
  }

  /// Approve a pending collaborator
  Future<void> approveCollaborator(String eventId, String userId, CollaboratorRole role) async {
    await _collaborators(eventId).doc(userId).update({
      'status': CollaboratorStatus.approved.name,
      'role': role.name,
      'approvedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
    // Add to the event's collaboratorIds array for querying
    await _events.doc(eventId).update({
      'collaboratorIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Reject a pending collaborator
  Future<void> rejectCollaborator(String eventId, String userId) async {
    await _collaborators(eventId).doc(userId).update({
      'status': CollaboratorStatus.rejected.name,
    });
  }

  /// Remove a collaborator entirely
  Future<void> removeCollaborator(String eventId, String userId) async {
    await _collaborators(eventId).doc(userId).delete();
    await _events.doc(eventId).update({
      'collaboratorIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Update collaborator role
  Future<void> updateCollaboratorRole(String eventId, String userId, CollaboratorRole role) async {
    await _collaborators(eventId).doc(userId).update({'role': role.name});
  }

  /// Invite a user by email (direct invite — pre-approved placeholder)
  Future<void> inviteByEmail({
    required String eventId,
    required String email,
    required CollaboratorRole role,
    required String inviterName,
  }) async {
    // Check if a user with this email already exists as a collaborator
    final existingSnap = await _collaborators(eventId)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (existingSnap.docs.isNotEmpty) return;

    // Create a placeholder collaborator entry with the email
    final collaborator = CollaboratorModel(
      id: email.hashCode.toString(),
      userId: '',
      email: email,
      displayName: 'Invitación pendiente',
      role: role,
      status: CollaboratorStatus.approved,
      requestedAt: DateTime.now(),
      approvedAt: DateTime.now(),
    );
    await _collaborators(eventId).doc('invite_${email.hashCode}').set({
      ...collaborator.toFirestore(),
      'isEmailInvite': true,
      'inviterName': inviterName,
    });
  }

  /// Watch all collaborators for an event
  Stream<List<CollaboratorModel>> watchCollaborators(String eventId) =>
      _collaborators(eventId).snapshots().map((snap) => snap.docs
          .map((d) => CollaboratorModel.fromFirestore(
                d.data() as Map<String, dynamic>,
                d.id,
              ))
          .toList());

  /// Watch pending requests for an event
  Stream<List<CollaboratorModel>> watchPendingRequests(String eventId) =>
      _collaborators(eventId)
          .where('status', isEqualTo: CollaboratorStatus.pending.name)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => CollaboratorModel.fromFirestore(
                    d.data() as Map<String, dynamic>,
                    d.id,
                  ))
              .toList());

  /// Get the current user's role for an event
  Future<CollaboratorModel?> getCollaborator(String eventId, String userId) async {
    final doc = await _collaborators(eventId).doc(userId).get();
    if (!doc.exists) return null;
    return CollaboratorModel.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }
}
