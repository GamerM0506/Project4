import 'package:equatable/equatable.dart';

class RequestEntity extends Equatable {
  final String id;
  final String code;
  final String listingId;
  final String groupId;
  final String receiverId;
  final int quantity;
  final String reason;

  /// pending, approved, rejected, scheduled, completed, cancelled, no_show.
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectReason;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RequestEntity({
    required this.id,
    required this.code,
    required this.listingId,
    required this.groupId,
    required this.receiverId,
    required this.quantity,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectReason,
    this.scheduledAt,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    code,
    listingId,
    groupId,
    receiverId,
    quantity,
    reason,
    status,
    reviewedBy,
    reviewedAt,
    rejectReason,
    scheduledAt,
    completedAt,
    createdAt,
    updatedAt,
  ];
}
