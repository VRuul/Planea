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

  factory VenueElementModel.fromJson(Map<String, dynamic> json) {
    return VenueElementModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      name: json['name'] ?? '',
      type: VenueElementType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'other'),
        orElse: () => VenueElementType.other,
      ),
      posX: (json['pos_x'] ?? 0.0).toDouble(),
      posY: (json['pos_y'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 200.0).toDouble(),
      height: (json['height'] ?? 200.0).toDouble(),
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'name': name,
      'type': type.name,
      'pos_x': posX,
      'pos_y': posY,
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
