import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final String eventId;
  final String name;
  final int capacity;
  final TableShape shape;
  final double posX;
  final double posY;
  final double? width;
  final double? height;

  TableModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.capacity,
    this.shape = TableShape.circular,
    this.posX = 0.0,
    this.posY = 0.0,
    this.width,
    this.height,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> map) {
    return TableModel(
      id: id,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      capacity: map['capacity'] ?? 10,
      shape: TableShape.values.firstWhere(
        (e) => e.name == (map['shape'] ?? 'circular'),
        orElse: () => TableShape.circular,
      ),
      posX: (map['posX'] ?? 0.0).toDouble(),
      posY: (map['posY'] ?? 0.0).toDouble(),
      width: map['width'] != null ? (map['width'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'capacity': capacity,
      'shape': shape.name,
      'posX': posX,
      'posY': posY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }
}

enum TableShape { circular, square, rectangular }
