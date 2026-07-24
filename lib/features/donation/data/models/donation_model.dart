class DonationCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;

  const DonationCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
  });

  factory DonationCategoryModel.fromJson(Map<String, dynamic> json) {
    return DonationCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
    );
  }
}

class DonationImageModel {
  final String id;
  final String donationItemId;
  final String imageUrl;
  final String type;

  const DonationImageModel({
    required this.id,
    required this.donationItemId,
    required this.imageUrl,
    required this.type,
  });

  factory DonationImageModel.fromJson(Map<String, dynamic> json) {
    return DonationImageModel(
      id: json['id']?.toString() ?? '',
      donationItemId: json['donation_item_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'declared',
    );
  }
}

class DonationItemModel {
  final String id;
  final String donationId;
  final String name;
  final String? categoryId;
  final int quantity;
  final String conditionDeclared;
  final String? conditionActual;
  final String status;
  final List<DonationImageModel> images;

  const DonationItemModel({
    required this.id,
    required this.donationId,
    required this.name,
    this.categoryId,
    required this.quantity,
    required this.conditionDeclared,
    this.conditionActual,
    required this.status,
    this.images = const [],
  });

  factory DonationItemModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
              .whereType<Map>()
              .map(
                (image) => DonationImageModel.fromJson(
                  Map<String, dynamic>.from(image),
                ),
              )
              .where((image) => image.imageUrl.isNotEmpty)
              .toList()
        : <DonationImageModel>[];

    return DonationItemModel(
      id: json['id']?.toString() ?? '',
      donationId: json['donation_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      conditionDeclared: json['condition_declared']?.toString() ?? 'used',
      conditionActual: json['condition_actual']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      images: images,
    );
  }
}

class DonationModel {
  final String id;
  final String code;
  final String donorId;
  final String groupId;
  final String title;
  final String? description;
  final String status;
  final List<DonationItemModel> items;

  const DonationModel({
    required this.id,
    required this.code,
    required this.donorId,
    required this.groupId,
    required this.title,
    this.description,
    required this.status,
    this.items = const [],
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (e) => DonationItemModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <DonationItemModel>[];

    return DonationModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      donorId: json['donor_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      items: items,
    );
  }
}

class InventoryItemModel {
  final String id;
  final String code;
  final String groupId;
  final String? donationItemId;
  final String? donorId;
  final String name;
  final String? categoryId;
  final int quantity;
  final String condition;
  final String status;

  const InventoryItemModel({
    required this.id,
    required this.code,
    required this.groupId,
    this.donationItemId,
    this.donorId,
    required this.name,
    this.categoryId,
    required this.quantity,
    required this.condition,
    required this.status,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      donationItemId: json['donation_item_id']?.toString(),
      donorId: json['donor_id']?.toString(),
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      condition: json['condition']?.toString() ?? 'used',
      status: json['status']?.toString() ?? 'in_stock',
    );
  }
}
