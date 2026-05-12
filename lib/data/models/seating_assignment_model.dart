import 'package:equatable/equatable.dart';

class SeatingAssignment extends Equatable {
  final String id;
  final String guestId;
  final String tableId;
  final Map<String, int> counts; // {'Adults': 2, 'Children': 1, 'Chambelán': 1}

  const SeatingAssignment({
    required this.id,
    required this.guestId,
    required this.tableId,
    required this.counts,
  });

  int get total => counts.values.fold(0, (sum, v) => sum + v);

  factory SeatingAssignment.fromFirestore(Map<String, dynamic> data, String id) {
    return SeatingAssignment(
      id: id,
      guestId: data['guestId'] ?? '',
      tableId: data['tableId'] ?? '',
      counts: Map<String, int>.from(data['counts'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'guestId': guestId,
    'tableId': tableId,
    'counts': counts,
  };

  @override
  List<Object?> get props => [id, guestId, tableId, counts];
}
