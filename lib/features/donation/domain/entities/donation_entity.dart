class DonationEntity {
  final String id;
  final String code;
  final String donorId;
  final String groupId;
  final String title;
  final String? description;
  final String status;
  final String pickupMethod;
  final String? pickupAddress;
  final DateTime? scheduledAt;
  final String? rejectedReason;
  final DateTime createdAt;
  final List<DonationItemEntity> items;

  const DonationEntity({
    required this.id,
    required this.code,
    required this.donorId,
    required this.groupId,
    required this.title,
    this.description,
    required this.status,
    required this.pickupMethod,
    this.pickupAddress,
    this.scheduledAt,
    this.rejectedReason,
    required this.createdAt,
    this.items = const [],
  });
}

class DonationItemEntity {
  final String id;
  final String donationId;
  final String name;
  final String? categoryId;
  final int quantity;
  final String conditionDeclared;
  final String? conditionActual;
  final String status;
  final String? rejectReason;
  final List<String> imageUrls;

  const DonationItemEntity({
    required this.id,
    required this.donationId,
    required this.name,
    this.categoryId,
    required this.quantity,
    required this.conditionDeclared,
    this.conditionActual,
    required this.status,
    this.rejectReason,
    this.imageUrls = const [],
  });
}

class DonationTimelineEntry {
  final DateTime at;
  final String event;
  final String? note;

  const DonationTimelineEntry({
    required this.at,
    required this.event,
    this.note,
  });
}
