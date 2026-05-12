import '../models/table_model.dart';
import '../models/guest_model.dart';
import '../models/seating_assignment_model.dart';
import '../models/venue_element_model.dart';

class SeatingData {
  final List<TableModel> tables;
  final List<GuestModel> guests;
  final List<SeatingAssignment> assignments;
  final List<VenueElementModel> venueElements;

  SeatingData({
    required this.tables,
    required this.guests,
    required this.assignments,
    required this.venueElements,
  });
}
