import 'package:equatable/equatable.dart';

enum GuestRole { padrino, vip, regular }

enum GuestStatus { confirmed, pending, declined }

class GuestModel extends Equatable {
  final String id;
  final String eventId;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final GuestRole role;
  final GuestStatus status;
  final String? tableId;
  
  // Detailed counts
  final int adults;
  final int children;
  final int teenagers;
  final int disabled;

  // Contact info
  final String? phone;
  final String? email;
  final String? socialMedia;
  
  // Extra info
  final String? notes;
  final String? dietaryRestrictions;

  const GuestModel({
    required this.id,
    required this.eventId,
    required this.displayName,
    this.firstName,
    this.lastName,
    required this.role,
    required this.status,
    this.tableId,
    this.adults = 1,
    this.children = 0,
    this.teenagers = 0,
    this.disabled = 0,
    this.phone,
    this.email,
    this.socialMedia,
    this.notes,
    this.dietaryRestrictions,
  });

  factory GuestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return GuestModel(
      id: id,
      eventId: data['eventId'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      role: GuestRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => GuestRole.regular,
      ),
      status: GuestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GuestStatus.pending,
      ),
      tableId: data['tableId'],
      adults: data['adults'] ?? data['plusOnes'] ?? 1,
      children: data['children'] ?? 0,
      teenagers: data['teenagers'] ?? 0,
      disabled: data['disabled'] ?? 0,
      phone: data['phone'],
      email: data['email'],
      socialMedia: data['socialMedia'],
      notes: data['notes'],
      dietaryRestrictions: data['dietaryRestrictions'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'displayName': displayName,
    'firstName': firstName,
    'lastName': lastName,
    'role': role.name,
    'status': status.name,
    'tableId': tableId,
    'adults': adults,
    'children': children,
    'teenagers': teenagers,
    'disabled': disabled,
    'phone': phone,
    'email': email,
    'socialMedia': socialMedia,
    'notes': notes,
    'dietaryRestrictions': dietaryRestrictions,
  };

  GuestModel copyWith({
    String? id,
    String? eventId,
    String? displayName,
    String? firstName,
    String? lastName,
    GuestRole? role,
    GuestStatus? status,
    String? tableId,
    int? adults,
    int? children,
    int? teenagers,
    int? disabled,
    String? phone,
    String? email,
    String? socialMedia,
    String? notes,
    String? dietaryRestrictions,
  }) {
    return GuestModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      tableId: tableId ?? this.tableId,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      teenagers: teenagers ?? this.teenagers,
      disabled: disabled ?? this.disabled,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      socialMedia: socialMedia ?? this.socialMedia,
      notes: notes ?? this.notes,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
    );
  }

  int get totalSeats => adults + children + teenagers + disabled;

  @override
  List<Object?> get props => [
    id, eventId, displayName, firstName, lastName, role, status, tableId,
    adults, children, teenagers, disabled, phone, email, socialMedia, notes, dietaryRestrictions
  ];
}
