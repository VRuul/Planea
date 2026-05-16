
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
  final int? color;

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
    this.color,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 10,
      shape: TableShape.values.firstWhere(
        (e) => e.name == (json['shape'] ?? 'circular'),
        orElse: () => TableShape.circular,
      ),
      posX: (json['pos_x'] ?? 0.0).toDouble(),
      posY: (json['pos_y'] ?? 0.0).toDouble(),
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'name': name,
      'capacity': capacity,
      'shape': shape.name,
      'pos_x': posX,
      'pos_y': posY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (color != null) 'color': color,
    };
  }
}

enum TableShape { circular, square, rectangular }
