import 'package:equatable/equatable.dart';

class RequestEntity extends Equatable {
  final String id;
  final String listingId;
  final String groupId;
  final String receiverId;
  final int quantity;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'scheduled', 'completed'
  final String? reviewedBy;
  final DateTime? scheduledAt;
  final String? confirmedBy;
  final String? qrToken;
  final String? photoUrl;
  final DateTime createdAt;

  const RequestEntity({
    required this.id,
    required this.listingId,
    required this.groupId,
    required this.receiverId,
    required this.quantity,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.scheduledAt,
    this.confirmedBy,
    this.qrToken,
    this.photoUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        listingId,
        groupId,
        receiverId,
        quantity,
        reason,
        status,
        reviewedBy,
        scheduledAt,
        confirmedBy,
        qrToken,
        photoUrl,
        createdAt,
      ];
}
