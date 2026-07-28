import 'package:equatable/equatable.dart';

class DeliveryConfirmationEntity extends Equatable {
  final String id;
  final String requestId;
  final String confirmedBy;
  final String? qrToken;
  final String? photoUrl;
  final String? note;
  final DateTime? confirmedAt;
  final String? receiverPhotoUrl;
  final String? receiverNote;
  final DateTime? receiverConfirmedAt;

  const DeliveryConfirmationEntity({
    required this.id,
    required this.requestId,
    required this.confirmedBy,
    this.qrToken,
    this.photoUrl,
    this.note,
    this.confirmedAt,
    this.receiverPhotoUrl,
    this.receiverNote,
    this.receiverConfirmedAt,
  });

  @override
  List<Object?> get props => [
    id,
    requestId,
    confirmedBy,
    qrToken,
    photoUrl,
    note,
    confirmedAt,
    receiverPhotoUrl,
    receiverNote,
    receiverConfirmedAt,
  ];
}
