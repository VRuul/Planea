import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import '../../../core/extensions/l10n_extension.dart';

class EventTypeInfo {
  final String label;
  final IconData icon;
  const EventTypeInfo(this.label, this.icon);
}

EventTypeInfo getEventTypeInfo(BuildContext context, EventType t) {
  final l = context.l10n;
  switch (t) {
    case EventType.wedding: return EventTypeInfo(l.typeWedding, Icons.favorite_rounded);
    case EventType.quinceanera: return EventTypeInfo(l.typeQuinceanera, Icons.auto_awesome_rounded);
    case EventType.birthday: return EventTypeInfo(l.typeBirthday, Icons.cake_rounded);
    case EventType.corporate: return EventTypeInfo(l.typeCorporate, Icons.business_center_rounded);
    case EventType.graduation: return EventTypeInfo(l.typeGraduation, Icons.school_rounded);
    case EventType.other: return EventTypeInfo(l.typeOther, Icons.celebration_rounded);
  }
}
