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
    );
  }
}
