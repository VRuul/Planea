import 'package:flutter/material.dart';

enum VenueElementType {
  danceFloor,
  dj,
  candyBar,
  entrance,
  reception,
  bar,
  bathrooms,
  kitchen,
  other
}

class VenueElementModel {
  final String id;
  final String eventId;
  final String name;
  final VenueElementType type;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final Color? color;

  VenueElementModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.type,
    this.posX = 0.0,
    this.posY = 0.0,
    this.width = 200.0,
    this.height = 200.0,
    this.color,
  });

  factory VenueElementModel.fromMap(String id, Map<String, dynamic> map) {
    return VenueElementModel(
      id: id,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      type: VenueElementType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'other'),
        orElse: () => VenueElementType.other,
      ),
      posX: (map['posX'] ?? 0.0).toDouble(),
      posY: (map['posY'] ?? 0.0).toDouble(),
      width: (map['width'] ?? 200.0).toDouble(),
      height: (map['height'] ?? 200.0).toDouble(),
      color: map['color'] != null ? Color(map['color']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'type': type.name,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
      'color': color?.toARGB32(),
    };
  }

  VenueElementModel copyWith({
    String? id,
    String? eventId,
    String? name,
    VenueElementType? type,
    double? posX,
    double? posY,
    double? width,
    double? height,
    Color? color,
  }) {
    return VenueElementModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      type: type ?? this.type,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
    );
  }
}
