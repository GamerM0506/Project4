import '../../domain/entities/donation_entity.dart';

class DonationModel extends DonationEntity {
  const DonationModel({
    required super.id,
    required super.code,
    required super.donorId,
    required super.groupId,
    required super.title,
    super.description,
    required super.status,
    required super.pickupMethod,
    super.pickupAddress,
    super.scheduledAt,
    super.rejectedReason,
    required super.createdAt,
    super.items,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <DonationItemEntity>[];
    if (itemsRaw is List) {
      for (final i in itemsRaw) {
        if (i is Map) {
          items.add(DonationItemModel.fromJson(Map<String, dynamic>.from(i)));
        }
      }
    }

    return DonationModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      donorId: json['donor_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      pickupMethod: json['pickup_method']?.toString() ?? 'drop_off',
      pickupAddress: json['pickup_address']?.toString(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      rejectedReason: json['rejected_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: items,
    );
  }
}

class DonationItemModel extends DonationItemEntity {
  const DonationItemModel({
    required super.id,
    required super.donationId,
    required super.name,
    super.categoryId,
    required super.quantity,
    required super.conditionDeclared,
    super.conditionActual,
    required super.status,
    super.rejectReason,
    super.imageUrls,
  });

  factory DonationItemModel.fromJson(Map<String, dynamic> json) {
    final images = <String>[];
    final raw = json['images'];
    if (raw is List) {
      for (final img in raw) {
        if (img is Map) {
          final url = img['image_url']?.toString();
          if (url != null && url.isNotEmpty) images.add(url);
        } else if (img is String) {
          images.add(img);
        }
      }
    }

    return DonationItemModel(
      id: json['id']?.toString() ?? '',
      donationId: json['donation_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      conditionDeclared: json['condition_declared']?.toString() ?? 'good',
      conditionActual: json['condition_actual']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      rejectReason: json['reject_reason']?.toString(),
      imageUrls: images,
    );
  }
}

class DonationTimelineModel extends DonationTimelineEntry {
  const DonationTimelineModel({
    required super.at,
    required super.event,
    super.note,
  });

  factory DonationTimelineModel.fromJson(Map<String, dynamic> json) {
    return DonationTimelineModel(
      at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      event: json['event']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }
}
