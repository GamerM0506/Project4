class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.parentId,
    this.iconUrl,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? slug;
  final String? parentId;
  final String? iconUrl;
  final int sortOrder;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      parentId: json['parent_id']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
