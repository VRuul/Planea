import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/seating_data_model.dart';
import '../data/services/supabase_service.dart';

class SeatingProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  String? _currentEventId;
  StreamSubscription<SeatingData>? _subscription;
  SeatingData? _data;
  bool _isLoading = false;

  SeatingData? get data => _data;
  bool get isLoading => _isLoading;

  void updateEventId(String? eventId) {
    if (_currentEventId == eventId) return;
    _currentEventId = eventId;
    _data = null;
    _subscription?.cancel();

    if (eventId != null && eventId.isNotEmpty) {
      _isLoading = true;
      notifyListeners();
      
      _subscription = _service.watchSeatingData(eventId).listen((newData) {
        _data = newData;
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
