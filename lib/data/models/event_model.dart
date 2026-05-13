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

  factory EventModel.fromFirestore(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      name: data['name'] ?? '',
      type: EventType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => EventType.other,
      ),
      date: DateTime.fromMillisecondsSinceEpoch(data['dateMs'] ?? 0),
      primaryColor: Color(data['primaryColor'] ?? 0xFF2D2D2D),
      secondaryColor: Color(data['secondaryColor'] ?? 0xFFD4AF37),
      venue: data['venue'],
      organizerId: data['organizerId'] ?? '',
      budget: (data['budget'] ?? 0).toDouble(),
      budgetSpent: (data['budgetSpent'] ?? 0).toDouble(),
      customType: data['customType'],
      customTypeIcon: data['customTypeIcon'],
      guestGoal: data['guestGoal'] ?? 0,
      celebrantNames: data['celebrantNames'],
      inviteCode: data['inviteCode'],
      collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
      whatsappTemplate: data['whatsappTemplate'],
      emailTemplate: data['emailTemplate'],
      emailSubject: data['emailSubject'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type.name,
    'dateMs': date.millisecondsSinceEpoch,
    'primaryColor': primaryColor.toARGB32(),
    'secondaryColor': secondaryColor.toARGB32(),
    'venue': venue,
    'organizerId': organizerId,
    'budget': budget,
    'budgetSpent': budgetSpent,
    'customType': customType,
    'customTypeIcon': customTypeIcon,
    'guestGoal': guestGoal,
    'celebrantNames': celebrantNames,
    'inviteCode': inviteCode,
    'collaboratorIds': collaboratorIds,
    'whatsappTemplate': whatsappTemplate,
    'emailTemplate': emailTemplate,
    'emailSubject': emailSubject,
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
