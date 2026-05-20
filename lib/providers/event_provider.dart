import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/event_model.dart';
import '../data/models/collaborator_model.dart';
import '../data/services/supabase_service.dart';

class EventProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  EventModel? _currentEvent;
  String? _currentEventId;
  List<EventModel> _userEvents = [];
  bool _isLoading = false;
  StreamSubscription? _eventsSubscription;

  String? _userId;
  CollaboratorRole? _currentRole;
  StreamSubscription? _roleSubscription;

  EventModel? get currentEvent => _currentEvent;
  String? get currentEventId => _currentEventId;
  List<EventModel> get userEvents => _userEvents;
  bool get isLoading => _isLoading;

  CollaboratorRole? get currentRole => _currentRole;
  bool get isOwner => _currentEvent?.organizerId == _userId;
  bool get isAdmin => _currentRole == CollaboratorRole.admin;
  bool get isStaff => _currentRole == CollaboratorRole.staff;
  bool get isViewer => _currentRole == CollaboratorRole.viewer;

  bool get canEditGuestsAndTables => isOwner || isAdmin;
  bool get canCheckInGuests => isOwner || isAdmin || isStaff;
  bool get canManageCollaborators => isOwner;

  void updateUserId(String? userId) {
    _eventsSubscription?.cancel();
    _roleSubscription?.cancel();
    _roleSubscription = null;
    _currentRole = null;
    _userId = userId;

    if (userId == null) {
      _userEvents = [];
      _currentEventId = null;
      _currentEvent = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _eventsSubscription = _service.watchUserEvents(userId).listen((events) {
      _userEvents = events;
      _isLoading = false;
      
      if (_currentEventId == null && events.isNotEmpty) {
        _currentEventId = events.first.id;
        _currentEvent = events.first;
      } else if (_currentEventId != null && events.isNotEmpty) {
        _currentEvent = events.cast<EventModel?>().firstWhere((e) => e?.id == _currentEventId, orElse: () => events.first);
        _currentEventId = _currentEvent?.id;
      }
      
      _updateRoleSubscription();
      notifyListeners();
    });
  }

  void setCurrentEventId(String eventId) {
    if (_currentEventId == eventId) return;
    _currentEventId = eventId;
    if (_userEvents.isNotEmpty) {
      _currentEvent = _userEvents.cast<EventModel?>().firstWhere((e) => e?.id == eventId, orElse: () => null);
    }
    _updateRoleSubscription();
    notifyListeners();
  }

  void setCurrentEvent(EventModel event) {
    _currentEvent = event;
    _currentEventId = event.id;
    _updateRoleSubscription();
    notifyListeners();
  }

  void _updateRoleSubscription() {
    _roleSubscription?.cancel();
    _roleSubscription = null;

    final eventId = _currentEventId;
    final userId = _userId;

    if (eventId == null || userId == null) {
      _currentRole = null;
      return;
    }

    if (_currentEvent?.organizerId == userId) {
      _currentRole = CollaboratorRole.owner;
      return;
    }

    _roleSubscription = _service.watchCollaborators(eventId).listen((collaborators) {
      final self = collaborators.where((c) => c.userId == userId && c.isApproved).firstOrNull;
      if (self != null) {
        _currentRole = self.role;
      } else {
        _currentRole = CollaboratorRole.viewer;
      }
      notifyListeners();
    });
  }

  Future<String> createEvent(EventModel event) => _service.createEvent(event);
  Future<void> updateEvent(EventModel event) => _service.updateEvent(event);

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _roleSubscription?.cancel();
    super.dispose();
  }
}
