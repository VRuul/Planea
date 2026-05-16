import 'package:equatable/equatable.dart';

enum CollaboratorRole { owner, admin, viewer }

enum CollaboratorStatus { pending, approved, rejected, invited }

class CollaboratorModel extends Equatable {
  final String id; // Document ID (usually = userId)
  final String userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  final CollaboratorRole role;
  final CollaboratorStatus status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final String? invitedBy;

  const CollaboratorModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.invitedBy,
  });

  factory CollaboratorModel.fromJson(Map<String, dynamic> json) {
    return CollaboratorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      photoUrl: json['photo_url'],
      role: CollaboratorRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => CollaboratorRole.viewer,
      ),
      status: CollaboratorStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CollaboratorStatus.pending,
      ),
      requestedAt: DateTime.parse(json['requested_at'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      invitedBy: json['invited_by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'email': email,
    'display_name': displayName,
    'photo_url': photoUrl,
    'role': role.name,
    'status': status.name,
    'requested_at': requestedAt.toIso8601String(),
    'approved_at': approvedAt?.toIso8601String(),
    'invited_by': invitedBy,
  };

  CollaboratorModel copyWith({
    String? id,
    String? userId,
    String? email,
    String? displayName,
    String? photoUrl,
    CollaboratorRole? role,
    CollaboratorStatus? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    String? invitedBy,
  }) {
    return CollaboratorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }

  bool get isPending => status == CollaboratorStatus.pending;
  bool get isApproved => status == CollaboratorStatus.approved;
  bool get isOwner => role == CollaboratorRole.owner;
  bool get isAdmin => role == CollaboratorRole.admin;
  bool get canEdit => role == CollaboratorRole.owner || role == CollaboratorRole.admin;

  @override
  List<Object?> get props => [
    id, userId, email, displayName, photoUrl, role, status, requestedAt, approvedAt, invitedBy
  ];
}
