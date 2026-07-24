class CategoryEntity {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.iconUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });
}
