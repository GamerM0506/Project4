import '../../domain/entities/post_entity.dart';

abstract class GroupFeedState {}

class GroupFeedInitial extends GroupFeedState {}

class GroupFeedLoading extends GroupFeedState {}

class GroupFeedLoaded extends GroupFeedState {
  final List<PostEntity> posts;
  final bool hasReachedMax;

  GroupFeedLoaded({required this.posts, this.hasReachedMax = false});

  GroupFeedLoaded copyWith({List<PostEntity>? posts, bool? hasReachedMax}) {
    return GroupFeedLoaded(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class GroupFeedError extends GroupFeedState {
  final String message;
  GroupFeedError({required this.message});
}

class GroupFeedCreating extends GroupFeedState {}

class GroupFeedCreateSuccess extends GroupFeedState {
  final PostEntity post;
  GroupFeedCreateSuccess({required this.post});
}

class GroupFeedCreateError extends GroupFeedState {
  final String message;
  GroupFeedCreateError({required this.message});
}

class GroupFeedDeleteError extends GroupFeedState {
  final String message;
  final GroupFeedLoaded previousState;

  GroupFeedDeleteError({required this.message, required this.previousState});
}
