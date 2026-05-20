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
  final List<MenuModel> menus;
  final RsvpConfig rsvpConfig;

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
    this.menus = const [],
    this.rsvpConfig = const RsvpConfig(),
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
      menus: (json['menus'] as List?)
              ?.map((m) => MenuModel.fromJson(m))
              .toList() ??
          const [],
      rsvpConfig: RsvpConfig.fromJson(json['rsvp_config']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'date': date.toIso8601String(),
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
    'menus': menus.map((m) => m.toJson()).toList(),
    'rsvp_config': rsvpConfig.toJson(),
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
    List<MenuModel>? menus,
    RsvpConfig? rsvpConfig,
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
      menus: menus ?? this.menus,
      rsvpConfig: rsvpConfig ?? this.rsvpConfig,
    );
  }

  double get budgetProgress => budget > 0 ? (budgetSpent / budget).clamp(0, 1) : 0;

  @override
  List<Object?> get props => [
        id, name, type, date, primaryColor, secondaryColor, venue, organizerId,
        budget, budgetSpent, customType, customTypeIcon, guestGoal, celebrantNames,
        inviteCode, collaboratorIds, whatsappTemplate, emailTemplate, emailSubject,
        menus, rsvpConfig
      ];
}

class RsvpConfig extends Equatable {
  final String themeStyle;
  final String? coverPhotoUrl;
  final bool showCountdown;
  final bool showMap;
  final String? customNotes;
  final String? dressCode;
  final String? registryUrl;
  final String? churchMapUrl;
  final String? venueMapUrl;
  final String? customMapUrl;
  final String? customMapLabel;

  const RsvpConfig({
    this.themeStyle = 'classic_gold',
    this.coverPhotoUrl,
    this.showCountdown = true,
    this.showMap = true,
    this.customNotes,
    this.dressCode,
    this.registryUrl,
    this.churchMapUrl,
    this.venueMapUrl,
    this.customMapUrl,
    this.customMapLabel,
  });

  static String? normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return url;
    final trimmed = url.trim();
    
    // Check if it's a Google Drive URL
    if (trimmed.contains('drive.google.com') || trimmed.contains('docs.google.com')) {
      // Pattern 1: /file/d/FILE_ID/view...
      final regExp1 = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
      final match1 = regExp1.firstMatch(trimmed);
      if (match1 != null && match1.groupCount >= 1) {
        final id = match1.group(1);
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
      
      // Pattern 2: ?id=FILE_ID or &id=FILE_ID
      final regExp2 = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
      final match2 = regExp2.firstMatch(trimmed);
      if (match2 != null && match2.groupCount >= 1) {
        final id = match2.group(1);
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }
    return trimmed;
  }

  factory RsvpConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RsvpConfig();
    return RsvpConfig(
      themeStyle: json['theme_style'] ?? 'classic_gold',
      coverPhotoUrl: normalizeImageUrl(json['cover_photo_url']),
      showCountdown: json['show_countdown'] ?? true,
      showMap: json['show_map'] ?? true,
      customNotes: json['custom_notes'],
      dressCode: json['dress_code'],
      registryUrl: json['registry_url'],
      churchMapUrl: json['church_map_url'],
      venueMapUrl: json['venue_map_url'],
      customMapUrl: json['custom_map_url'],
      customMapLabel: json['custom_map_label'],
    );
  }

  Map<String, dynamic> toJson() => {
        'theme_style': themeStyle,
        'cover_photo_url': coverPhotoUrl,
        'show_countdown': showCountdown,
        'show_map': showMap,
        'custom_notes': customNotes,
        'dress_code': dressCode,
        'registry_url': registryUrl,
        'church_map_url': churchMapUrl,
        'venue_map_url': venueMapUrl,
        'custom_map_url': customMapUrl,
        'custom_map_label': customMapLabel,
      };

  RsvpConfig copyWith({
    String? themeStyle,
    String? coverPhotoUrl,
    bool? showCountdown,
    bool? showMap,
    String? customNotes,
    String? dressCode,
    String? registryUrl,
    String? churchMapUrl,
    String? venueMapUrl,
    String? customMapUrl,
    String? customMapLabel,
  }) {
    return RsvpConfig(
      themeStyle: themeStyle ?? this.themeStyle,
      coverPhotoUrl: coverPhotoUrl != null ? normalizeImageUrl(coverPhotoUrl) : this.coverPhotoUrl,
      showCountdown: showCountdown ?? this.showCountdown,
      showMap: showMap ?? this.showMap,
      customNotes: customNotes ?? this.customNotes,
      dressCode: dressCode ?? this.dressCode,
      registryUrl: registryUrl ?? this.registryUrl,
      churchMapUrl: churchMapUrl ?? this.churchMapUrl,
      venueMapUrl: venueMapUrl ?? this.venueMapUrl,
      customMapUrl: customMapUrl ?? this.customMapUrl,
      customMapLabel: customMapLabel ?? this.customMapLabel,
    );
  }

  @override
  List<Object?> get props => [
        themeStyle,
        coverPhotoUrl,
        showCountdown,
        showMap,
        customNotes,
        dressCode,
        registryUrl,
        churchMapUrl,
        venueMapUrl,
        customMapUrl,
        customMapLabel,
      ];
}

class MenuModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final List<MenuCourseModel> courses;

  const MenuModel({
    required this.id,
    required this.name,
    this.icon,
    required this.courses,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      courses: (json['courses'] as List?)
              ?.map((c) => MenuCourseModel.fromJson(c))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'courses': courses.map((c) => c.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, name, icon, courses];
}

class MenuCourseModel extends Equatable {
  final String name;
  final String dishName;
  final String? description;

  const MenuCourseModel({
    required this.name,
    required this.dishName,
    this.description,
  });

  factory MenuCourseModel.fromJson(Map<String, dynamic> json) {
    return MenuCourseModel(
      name: json['name'] ?? '',
      dishName: json['dish_name'] ?? json['dishName'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dish_name': dishName,
        'description': description,
      };

  @override
  List<Object?> get props => [name, dishName, description];
}
