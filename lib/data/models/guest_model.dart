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
  final String? customRole;
  final int? customRoleIcon;
  final String? menuSelection;
  final bool checkedIn;

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
    this.customRole,
    this.customRoleIcon,
    this.menuSelection,
    this.checkedIn = false,
  });

  int get totalSeats {
    int total = adults + children + teenagers + disabled;
    customCounts.forEach((_, count) => total += count);
    return total;
  }

  factory GuestModel.fromJson(Map<String, dynamic> json) {
    return GuestModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      displayName: json['display_name'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: GuestRole.values.firstWhere((e) => e.name == json['role'], orElse: () => GuestRole.regular),
      status: GuestStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => GuestStatus.pending),
      tableId: json['table_id'],
      adults: json['adults'] ?? 0,
      children: json['children'] ?? 0,
      teenagers: json['teenagers'] ?? 0,
      disabled: json['disabled'] ?? 0,
      phone: json['phone'],
      email: json['email'],
      socialMedia: json['social_media'],
      notes: json['notes'],
      dietaryRestrictions: json['dietary_restrictions'],
      customCounts: Map<String, int>.from(json['custom_counts'] ?? {}),
      customIcons: Map<String, int>.from(json['custom_icons'] ?? {}),
      customRole: json['custom_role'],
      customRoleIcon: json['custom_role_icon'],
      menuSelection: json['menu_selection'],
      checkedIn: json['checked_in'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.name,
      'status': status.name,
      'table_id': tableId,
      'adults': adults,
      'children': children,
      'teenagers': teenagers,
      'disabled': disabled,
      'phone': phone,
      'email': email,
      'social_media': socialMedia,
      'notes': notes,
      'dietary_restrictions': dietaryRestrictions,
      'custom_counts': customCounts,
      'custom_icons': customIcons,
      'custom_role': customRole,
      'custom_role_icon': customRoleIcon,
      'menu_selection': menuSelection,
      'checked_in': checkedIn,
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
    String? customRole,
    int? customRoleIcon,
    String? menuSelection,
    bool? checkedIn,
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
      customRole: customRole ?? this.customRole,
      customRoleIcon: customRoleIcon ?? this.customRoleIcon,
      menuSelection: menuSelection ?? this.menuSelection,
      checkedIn: checkedIn ?? this.checkedIn,
    );
  }

  @override
  List<Object?> get props => [
        id, eventId, displayName, firstName, lastName, role, status,
        tableId, adults, children, teenagers, disabled, phone, email,
        socialMedia, notes, dietaryRestrictions, customCounts, customIcons,
        customRole, customRoleIcon, menuSelection, checkedIn,
      ];
}
