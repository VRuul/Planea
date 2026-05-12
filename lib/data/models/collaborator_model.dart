import 'package:equatable/equatable.dart';

enum CollaboratorRole { owner, admin, viewer }

enum CollaboratorStatus { pending, approved, rejected }

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
  });

  factory CollaboratorModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CollaboratorModel(
      id: id,
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: CollaboratorRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => CollaboratorRole.viewer,
      ),
      status: CollaboratorStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CollaboratorStatus.pending,
      ),
      requestedAt: DateTime.fromMillisecondsSinceEpoch(data['requestedAtMs'] ?? 0),
      approvedAt: data['approvedAtMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['approvedAtMs'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role.name,
    'status': status.name,
    'requestedAtMs': requestedAt.millisecondsSinceEpoch,
    'approvedAtMs': approvedAt?.millisecondsSinceEpoch,
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
    );
  }

  bool get isPending => status == CollaboratorStatus.pending;
  bool get isApproved => status == CollaboratorStatus.approved;
  bool get isOwner => role == CollaboratorRole.owner;
  bool get isAdmin => role == CollaboratorRole.admin;
  bool get canEdit => role == CollaboratorRole.owner || role == CollaboratorRole.admin;

  @override
  List<Object?> get props => [
    id, userId, email, displayName, photoUrl, role, status, requestedAt, approvedAt
  ];
}
