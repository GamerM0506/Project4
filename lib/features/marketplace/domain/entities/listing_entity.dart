import 'package:equatable/equatable.dart';

class ListingEntity extends Equatable {
  final String id;
  final String inventoryItemId;
  final String groupId;
  final String title;
  final String description;
  final String categoryId;
  final String condition;
  final int quantityTotal;
  final int quantityAvailable;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl; // Add imageUrl for UI even if not in POST

  const ListingEntity({
    required this.id,
    required this.inventoryItemId,
    required this.groupId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.condition,
    required this.quantityTotal,
    required this.quantityAvailable,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        inventoryItemId,
        groupId,
        title,
        description,
        categoryId,
        condition,
        quantityTotal,
        quantityAvailable,
        status,
        createdBy,
        createdAt,
        updatedAt,
        imageUrl,
      ];
}
