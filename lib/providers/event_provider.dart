import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/event_model.dart';
import '../data/services/supabase_service.dart';

class EventProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  EventModel? _currentEvent;
  String? _currentEventId;
  List<EventModel> _userEvents = [];
  bool _isLoading = false;
  StreamSubscription? _eventsSubscription;

  EventModel? get currentEvent => _currentEvent;
  String? get currentEventId => _currentEventId;
  List<EventModel> get userEvents => _userEvents;
  bool get isLoading => _isLoading;

  void updateUserId(String? userId) {
    _eventsSubscription?.cancel();
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
      
      notifyListeners();
    });
  }

  void setCurrentEventId(String eventId) {
    if (_currentEventId == eventId) return;
    _currentEventId = eventId;
    if (_userEvents.isNotEmpty) {
      _currentEvent = _userEvents.cast<EventModel?>().firstWhere((e) => e?.id == eventId, orElse: () => null);
    }
    notifyListeners();
  }

  void setCurrentEvent(EventModel event) {
    _currentEvent = event;
    _currentEventId = event.id;
    notifyListeners();
  }

  Future<String> createEvent(EventModel event) => _service.createEvent(event);
  Future<void> updateEvent(EventModel event) => _service.updateEvent(event);

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
