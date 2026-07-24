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
      id: json['id']?.toString() ?? '',
      listingId: json['listing_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reviewedBy: json['reviewed_by']?.toString(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      confirmedBy: json['confirmed_by']?.toString(),
      qrToken: json['qr_token']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
