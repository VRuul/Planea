import 'package:equatable/equatable.dart';

class SeatingAssignment extends Equatable {
  final String id;
  final String eventId;
  final String guestId;
  final String tableId;
  final Map<String, int> counts; // {'Adults': 2, 'Children': 1, 'Chambelán': 1}

  const SeatingAssignment({
    required this.id,
    required this.eventId,
    required this.guestId,
    required this.tableId,
    required this.counts,
  });

  int get total => counts.values.fold(0, (sum, v) => sum + v);

  factory SeatingAssignment.fromJson(Map<String, dynamic> json) {
    return SeatingAssignment(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      guestId: json['guest_id'] ?? '',
      tableId: json['table_id'] ?? '',
      counts: Map<String, int>.from(json['counts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'guest_id': guestId,
    'table_id': tableId,
    'counts': counts,
  };

  @override
  List<Object?> get props => [id, eventId, guestId, tableId, counts];
}
