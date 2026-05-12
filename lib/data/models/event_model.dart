import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum EventType { wedding, quinceanera, birthday, corporate, graduation, other }

class EventTypeInfo {
  final String label;
  final IconData icon;
  const EventTypeInfo(this.label, this.icon);
}

EventTypeInfo getEventTypeInfo(BuildContext context, EventType t) {
  final l = l10n(context);
  switch (t) {
    case EventType.wedding: return EventTypeInfo(l.typeWedding, Icons.favorite_rounded);
    case EventType.quinceanera: return EventTypeInfo(l.typeQuinceanera, Icons.auto_awesome_rounded);
    case EventType.birthday: return EventTypeInfo(l.typeBirthday, Icons.cake_rounded);
    case EventType.corporate: return EventTypeInfo(l.typeCorporate, Icons.business_center_rounded);
    case EventType.graduation: return EventTypeInfo(l.typeGraduation, Icons.school_rounded);
    case EventType.other: return EventTypeInfo(l.typeOther, Icons.celebration_rounded);
  }
}

AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context)!;

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
    );
  }

  double get budgetProgress => budget > 0 ? (budgetSpent / budget).clamp(0, 1) : 0;

  @override
  List<Object?> get props => [
        id, name, type, date, primaryColor, secondaryColor, venue, organizerId,
        budget, budgetSpent, customType, customTypeIcon, guestGoal, celebrantNames
      ];
}
