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
  final Map<String, int> customCounts;
  final Map<String, int> customIcons;

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
    this.customCounts = const {},
    this.customIcons = const {},
  });

  int get totalSeats {
    int total = adults + children + teenagers + disabled;
    customCounts.forEach((_, count) => total += count);
    return total;
  }

  factory GuestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return GuestModel(
      id: id,
      eventId: data['eventId'] ?? '',
      displayName: data['displayName'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      role: GuestRole.values.firstWhere((e) => e.name == data['role'], orElse: () => GuestRole.regular),
      status: GuestStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => GuestStatus.pending),
      tableId: data['tableId'],
      adults: data['adults'] ?? 0,
      children: data['children'] ?? 0,
      teenagers: data['teenagers'] ?? 0,
      disabled: data['disabled'] ?? 0,
      phone: data['phone'],
      email: data['email'],
      socialMedia: data['socialMedia'],
      notes: data['notes'],
      dietaryRestrictions: data['dietaryRestrictions'],
      customCounts: Map<String, int>.from(data['customCounts'] ?? {}),
      customIcons: Map<String, int>.from(data['customIcons'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'customCounts': customCounts,
      'customIcons': customIcons,
    };
  }

  GuestModel copyWith({
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
    Map<String, int>? customCounts,
    Map<String, int>? customIcons,
  }) {
    return GuestModel(
      id: id,
      eventId: eventId,
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
      customCounts: customCounts ?? this.customCounts,
      customIcons: customIcons ?? this.customIcons,
    );
  }

  @override
  List<Object?> get props => [
        id, eventId, displayName, firstName, lastName, role, status,
        tableId, adults, children, teenagers, disabled, phone, email,
        socialMedia, notes, dietaryRestrictions, customCounts, customIcons,
      ];
}
