import '../../domain/entities/request_entity.dart';

class RequestModel extends RequestEntity {
  const RequestModel({
    required super.id,
    required super.code,
    required super.listingId,
    required super.groupId,
    required super.receiverId,
    required super.quantity,
    required super.reason,
    required super.status,
    super.reviewedBy,
    super.reviewedAt,
    super.rejectReason,
    super.scheduledAt,
    super.completedAt,
    required super.createdAt,
    super.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      listingId: json['listing_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      rejectReason: json['reject_reason']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'listing_id': listingId,
      'group_id': groupId,
      'receiver_id': receiverId,
      'quantity': quantity,
      'reason': reason,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reject_reason': rejectReason,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
