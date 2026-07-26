import '../../domain/entities/activity_entity.dart';

class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.id,
    required super.action,
    required super.createdAt,
    super.refType,
    super.refId,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: (json['id'] as num).toInt(),
      action: json['action'] as String,
      refType: json['ref_type'] as String?,
      refId: json['ref_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ActivityPageModel extends ActivityPageEntity {
  const ActivityPageModel({
    required super.items,
    required super.page,
    required super.limit,
    required super.total,
  });

  factory ActivityPageModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    final meta = Map<String, dynamic>.from(json['meta'] as Map);
    return ActivityPageModel(
      items: items
          .map(
            (item) =>
                ActivityModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      page: (meta['page'] as num).toInt(),
      limit: (meta['limit'] as num).toInt(),
      total: (meta['total'] as num).toInt(),
    );
  }
}
