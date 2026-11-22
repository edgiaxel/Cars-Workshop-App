import 'estimate_model.dart';

/// Estimate authorization audit record mapping `public.estimate_authorizations`.
class EstimateAuthorizationModel {
  const EstimateAuthorizationModel({
    required this.id,
    required this.estimateId,
    required this.authorizedBy,
    required this.status,
    this.signatureToken,
    this.notes,
    required this.authorizedAt,
  });

  final String id;
  final String estimateId;
  final String authorizedBy;
  final EstimateStatus status;
  final String? signatureToken;
  final String? notes;
  final DateTime authorizedAt;

  factory EstimateAuthorizationModel.fromJson(Map<String, dynamic> json) {
    return EstimateAuthorizationModel(
      id: (json['id'] as String?) ?? '',
      estimateId: (json['estimate_id'] ?? json['estimateId'] ?? '') as String,
      authorizedBy: (json['authorized_by'] ?? json['authorizedBy'] ?? '') as String,
      status: EstimateStatus.fromString(json['status'] as String?),
      signatureToken: (json['signature_token'] ?? json['signatureToken']) as String?,
      notes: json['notes'] as String?,
      authorizedAt: json['authorized_at'] != null
          ? DateTime.parse(json['authorized_at'] as String)
          : (json['authorizedAt'] != null
              ? DateTime.parse(json['authorizedAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'estimate_id': estimateId,
      'authorized_by': authorizedBy,
      'status': status.toDbString(),
      if (signatureToken != null) 'signature_token': signatureToken,
      if (notes != null) 'notes': notes,
      'authorized_at': authorizedAt.toIso8601String(),
    };
  }

  EstimateAuthorizationModel copyWith({
    String? id,
    String? estimateId,
    String? authorizedBy,
    EstimateStatus? status,
    String? signatureToken,
    String? notes,
    DateTime? authorizedAt,
  }) {
    return EstimateAuthorizationModel(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      status: status ?? this.status,
      signatureToken: signatureToken ?? this.signatureToken,
      notes: notes ?? this.notes,
      authorizedAt: authorizedAt ?? this.authorizedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateAuthorizationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          estimateId == other.estimateId &&
          authorizedBy == other.authorizedBy &&
          status == other.status &&
          signatureToken == other.signatureToken &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
        id,
        estimateId,
        authorizedBy,
        status,
        signatureToken,
        notes,
      );
}
