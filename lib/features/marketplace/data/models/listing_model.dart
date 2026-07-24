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
    String? imageUrl = json['image_url']?.toString();
    if ((imageUrl == null || imageUrl.isEmpty) && json['images'] is List) {
      final images = json['images'] as List;
      if (images.isNotEmpty) {
        final first = images.first;
        if (first is Map) {
          imageUrl = (first['url'] ?? first['image_url'] ?? first['public_url'])
              ?.toString();
        } else if (first is String) {
          imageUrl = first;
        }
      }
    }

    return ListingModel(
      id: json['id']?.toString() ?? '',
      inventoryItemId: json['inventory_item_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      condition: json['condition']?.toString() ?? '',
      quantityTotal: _toInt(json['quantity_total']),
      quantityAvailable: _toInt(json['quantity_available']),
      status: json['status']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      imageUrl: imageUrl,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
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
