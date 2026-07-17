import '../../domain/entities/listing_entity.dart';

class ListingModel extends ListingEntity {
  const ListingModel({
    required super.id,
    required super.inventoryItemId,
    required super.groupId,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.condition,
    required super.quantityTotal,
    required super.quantityAvailable,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    super.updatedAt,
    super.imageUrl,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] ?? '',
      inventoryItemId: json['inventory_item_id'] ?? '',
      groupId: json['group_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? '',
      condition: json['condition'] ?? '',
      quantityTotal: json['quantity_total'] ?? 0,
      quantityAvailable: json['quantity_available'] ?? 0,
      status: json['status'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      imageUrl: json['image_url'], // Optional field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'group_id': groupId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'condition': condition,
      'quantity_total': quantityTotal,
      'quantity_available': quantityAvailable,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}
