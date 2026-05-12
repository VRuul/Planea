import 'package:flutter/material.dart';
import '../data/models/event_model.dart';
import '../data/services/firestore_service.dart';

class EventProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  EventModel? _currentEvent;
  String? _currentEventId;

  EventModel? get currentEvent => _currentEvent;
  String? get currentEventId => _currentEventId;

  void setCurrentEventId(String eventId) {
    if (_currentEventId == eventId) return;
    _currentEventId = eventId;
    notifyListeners();
  }

  void setCurrentEvent(EventModel event) {
    _currentEvent = event;
    notifyListeners();
  }

  Stream<EventModel?> watchCurrentEvent() {
    if (_currentEventId == null) return const Stream.empty();
    return _service.watchEvent(_currentEventId!);
  }

  Stream<List<EventModel>> watchUserEvents(String userId) =>
      _service.watchUserEvents(userId);

  Future<String> createEvent(EventModel event) =>
      _service.createEvent(event);

  Future<void> updateEvent(EventModel event) =>
      _service.updateEvent(event);
}
