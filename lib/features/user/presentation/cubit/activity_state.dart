import 'package:equatable/equatable.dart';

import '../../domain/entities/activity_entity.dart';

sealed class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {
  const ActivityInitial();
}

class ActivityLoading extends ActivityState {
  const ActivityLoading();
}

class ActivityLoaded extends ActivityState {
  final List<ActivityEntity> activities;
  final int page;
  final bool hasMore;

  const ActivityLoaded({
    required this.activities,
    required this.page,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [activities, page, hasMore];
}

class ActivityLoadingMore extends ActivityLoaded {
  const ActivityLoadingMore({
    required super.activities,
    required super.page,
    required super.hasMore,
  });
}

class ActivityError extends ActivityState {
  final String message;
  final List<ActivityEntity> activities;
  final int page;
  final bool hasMore;

  const ActivityError({
    required this.message,
    this.activities = const [],
    this.page = 0,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [message, activities, page, hasMore];
}
