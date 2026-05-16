import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum EventType { wedding, quinceanera, birthday, corporate, graduation, other }


class EventModel extends Equatable {
  final String id;
  final String name;
  final EventType type;
  final DateTime date;
  final Color primaryColor;
  final Color secondaryColor;
  final String? venue;
  final String organizerId;
  final double budget;
  final double budgetSpent;
  final String? customType;
  final int? customTypeIcon;
  final int guestGoal;
  final String? celebrantNames;
  final String? inviteCode;
  final List<String> collaboratorIds;
  final String? whatsappTemplate;
  final String? emailTemplate;
  final String? emailSubject;

  const EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.primaryColor,
    required this.secondaryColor,
    this.venue,
    required this.organizerId,
    this.budget = 0,
    this.budgetSpent = 0,
    this.customType,
    this.customTypeIcon,
    this.guestGoal = 0,
    this.celebrantNames,
    this.inviteCode,
    this.collaboratorIds = const [],
    this.whatsappTemplate,
    this.emailTemplate,
    this.emailSubject,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: EventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EventType.other,
      ),
      date: DateTime.fromMillisecondsSinceEpoch(json['date_ms'] ?? 0),
      primaryColor: Color(json['primary_color'] ?? 0xFF2D2D2D),
      secondaryColor: Color(json['secondary_color'] ?? 0xFFD4AF37),
      venue: json['venue'],
      organizerId: json['organizer_id'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      budgetSpent: (json['budget_spent'] ?? 0).toDouble(),
      customType: json['custom_type'],
      customTypeIcon: json['custom_type_icon'],
      guestGoal: json['guest_goal'] ?? 0,
      celebrantNames: json['celebrant_names'],
      inviteCode: json['invite_code'],
      collaboratorIds: List<String>.from(json['collaborator_ids'] ?? []),
      whatsappTemplate: json['whatsapp_template'],
      emailTemplate: json['email_template'],
      emailSubject: json['email_subject'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'date_ms': date.millisecondsSinceEpoch,
    'primary_color': primaryColor.toARGB32(),
    'secondary_color': secondaryColor.toARGB32(),
    'venue': venue,
    'organizer_id': organizerId,
    'budget': budget,
    'budget_spent': budgetSpent,
    'custom_type': customType,
    'custom_type_icon': customTypeIcon,
    'guest_goal': guestGoal,
    'celebrant_names': celebrantNames,
    'invite_code': inviteCode,
    'collaborator_ids': collaboratorIds,
    'whatsapp_template': whatsappTemplate,
    'email_template': emailTemplate,
    'email_subject': emailSubject,
  };

  EventModel copyWith({
    String? id,
    String? name,
    EventType? type,
    DateTime? date,
    Color? primaryColor,
    Color? secondaryColor,
    String? venue,
    String? organizerId,
    double? budget,
    double? budgetSpent,
    String? customType,
    int? customTypeIcon,
    int? guestGoal,
    String? celebrantNames,
    String? inviteCode,
    List<String>? collaboratorIds,
    String? whatsappTemplate,
    String? emailTemplate,
    String? emailSubject,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      venue: venue ?? this.venue,
      organizerId: organizerId ?? this.organizerId,
      budget: budget ?? this.budget,
      budgetSpent: budgetSpent ?? this.budgetSpent,
      customType: customType ?? this.customType,
      customTypeIcon: customTypeIcon ?? this.customTypeIcon,
      guestGoal: guestGoal ?? this.guestGoal,
      celebrantNames: celebrantNames ?? this.celebrantNames,
      inviteCode: inviteCode ?? this.inviteCode,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      whatsappTemplate: whatsappTemplate ?? this.whatsappTemplate,
      emailTemplate: emailTemplate ?? this.emailTemplate,
      emailSubject: emailSubject ?? this.emailSubject,
    );
  }

  double get budgetProgress => budget > 0 ? (budgetSpent / budget).clamp(0, 1) : 0;

  @override
  List<Object?> get props => [
        id, name, type, date, primaryColor, secondaryColor, venue, organizerId,
        budget, budgetSpent, customType, customTypeIcon, guestGoal, celebrantNames,
        inviteCode, collaboratorIds, whatsappTemplate, emailTemplate, emailSubject
      ];
}
