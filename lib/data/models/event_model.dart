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
    );
  }

  double get budgetProgress => budget > 0 ? (budgetSpent / budget).clamp(0, 1) : 0;

  @override
  List<Object?> get props => [id, name, type, date, primaryColor, secondaryColor, venue, organizerId, budget, budgetSpent];
}
