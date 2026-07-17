import '../../domain/entities/request_entity.dart';

class RequestModel extends RequestEntity {
  const RequestModel({
    required super.id,
    required super.listingId,
    required super.groupId,
    required super.receiverId,
    required super.quantity,
    required super.reason,
    required super.status,
    super.reviewedBy,
    super.scheduledAt,
    super.confirmedBy,
    super.qrToken,
    super.photoUrl,
    required super.createdAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] ?? '',
      listingId: json['listing_id'] ?? '',
      groupId: json['group_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewed_by'],
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      confirmedBy: json['confirmed_by'],
      qrToken: json['qr_token'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'group_id': groupId,
      'receiver_id': receiverId,
      'quantity': quantity,
      'reason': reason,
      'status': status,
      'reviewed_by': reviewedBy,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'confirmed_by': confirmedBy,
      'qr_token': qrToken,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
