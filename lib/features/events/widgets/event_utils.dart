import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import '../../../core/extensions/l10n_extension.dart';

class EventTypeInfo {
  final String label;
  final String protagonistLabel;
  final IconData icon;
  const EventTypeInfo(this.label, this.protagonistLabel, this.icon);
}

EventTypeInfo getEventTypeInfo(BuildContext context, EventType t) {
  final l = context.l10n;
  switch (t) {
    case EventType.wedding:
      return EventTypeInfo(l.typeWedding, "Nombres de los novios", Icons.favorite_rounded);
    case EventType.quinceanera:
      return EventTypeInfo(l.typeQuinceanera, "Nombre de la festejada", Icons.auto_awesome_rounded);
    case EventType.birthday:
      return EventTypeInfo(l.typeBirthday, "Nombre del cumpleañero", Icons.cake_rounded);
    case EventType.corporate:
      return EventTypeInfo(l.typeCorporate, "Nombre del evento o empresa", Icons.business_center_rounded);
    case EventType.graduation:
      return EventTypeInfo(l.typeGraduation, "Nombre del graduado o generación", Icons.school_rounded);
    case EventType.other:
      return EventTypeInfo(l.typeOther, "Nombres de los protagonistas", Icons.celebration_rounded);
  }
}
