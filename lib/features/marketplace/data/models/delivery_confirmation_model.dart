import '../../domain/entities/delivery_confirmation_entity.dart';

class DeliveryConfirmationModel extends DeliveryConfirmationEntity {
  const DeliveryConfirmationModel({
    required super.id,
    required super.requestId,
    required super.confirmedBy,
    super.qrToken,
    super.photoUrl,
    super.note,
    super.confirmedAt,
    super.receiverPhotoUrl,
    super.receiverNote,
    super.receiverConfirmedAt,
  });

  factory DeliveryConfirmationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryConfirmationModel(
      id: json['id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      confirmedBy: json['confirmed_by']?.toString() ?? '',
      qrToken: json['qr_token']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      note: json['note']?.toString(),
      confirmedAt: DateTime.tryParse(json['confirmed_at']?.toString() ?? ''),
      receiverPhotoUrl: json['receiver_photo_url']?.toString(),
      receiverNote: json['receiver_note']?.toString(),
      receiverConfirmedAt: DateTime.tryParse(
        json['receiver_confirmed_at']?.toString() ?? '',
      ),
    );
  }
}
