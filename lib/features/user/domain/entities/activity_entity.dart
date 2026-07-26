import 'package:equatable/equatable.dart';

class ActivityEntity extends Equatable {
  final int id;
  final String action;
  final String? refType;
  final String? refId;
  final DateTime createdAt;

  const ActivityEntity({
    required this.id,
    required this.action,
    required this.createdAt,
    this.refType,
    this.refId,
  });

  @override
  List<Object?> get props => [id, action, refType, refId, createdAt];
}

class ActivityPageEntity extends Equatable {
  final List<ActivityEntity> items;
  final int page;
  final int limit;
  final int total;

  const ActivityPageEntity({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  bool get hasMore => page * limit < total;

  @override
  List<Object?> get props => [items, page, limit, total];
}
