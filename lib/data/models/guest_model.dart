import 'package:equatable/equatable.dart';

enum GuestRole { padrino, vip, regular }

enum GuestStatus { confirmed, pending, declined }

class GuestModel extends Equatable {
  final String id;
  final String name;
  final GuestRole role;
  final GuestStatus status;
  final String? tableId;
  final int plusOnes;
  final String eventId;

  const GuestModel({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.tableId,
    this.plusOnes = 0,
    required this.eventId,
  });

  factory GuestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return GuestModel(
      id: id,
      name: data['name'] ?? '',
      role: GuestRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => GuestRole.regular,
      ),
      status: GuestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GuestStatus.pending,
      ),
      tableId: data['tableId'],
      plusOnes: data['plusOnes'] ?? 0,
      eventId: data['eventId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'role': role.name,
    'status': status.name,
    'tableId': tableId,
    'plusOnes': plusOnes,
    'eventId': eventId,
  };

  GuestModel copyWith({
    String? id,
    String? name,
    GuestRole? role,
    GuestStatus? status,
    String? tableId,
    int? plusOnes,
    String? eventId,
  }) {
    return GuestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      tableId: tableId ?? this.tableId,
      plusOnes: plusOnes ?? this.plusOnes,
      eventId: eventId ?? this.eventId,
    );
  }

  int get totalSeats => 1 + plusOnes;

  @override
  List<Object?> get props => [id, name, role, status, tableId, plusOnes, eventId];
}
