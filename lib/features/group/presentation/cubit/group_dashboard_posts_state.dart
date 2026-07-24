import 'package:equatable/equatable.dart';
import '../../../post/domain/entities/post_entity.dart';

abstract class GroupDashboardPostsState extends Equatable {
  const GroupDashboardPostsState();

  @override
  List<Object?> get props => [];
}

class GroupDashboardPostsInitial extends GroupDashboardPostsState {}

class GroupDashboardPostsLoading extends GroupDashboardPostsState {}

class GroupDashboardPostsLoaded extends GroupDashboardPostsState {
  final List<PostEntity> pendingPosts;
  final List<PostEntity> publishedPosts;

  const GroupDashboardPostsLoaded({
    required this.pendingPosts,
    required this.publishedPosts,
  });

  @override
  List<Object?> get props => [pendingPosts, publishedPosts];
}

class GroupDashboardPostsError extends GroupDashboardPostsState {
  final String message;

  const GroupDashboardPostsError(this.message);

  @override
  List<Object?> get props => [message];
}
