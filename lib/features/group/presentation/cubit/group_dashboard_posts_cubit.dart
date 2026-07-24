import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../post/domain/usecases/get_posts_usecase.dart';
import '../../../post/domain/usecases/update_post_status_usecase.dart';
import '../../../post/domain/usecases/delete_post_usecase.dart';
import 'group_dashboard_posts_state.dart';

class GroupDashboardPostsCubit extends Cubit<GroupDashboardPostsState> {
  final GetPostsUseCase getPostsUseCase;
  final UpdatePostStatusUseCase updatePostStatusUseCase;
  final DeletePostUseCase deletePostUseCase;

  GroupDashboardPostsCubit({
    required this.getPostsUseCase,
    required this.updatePostStatusUseCase,
    required this.deletePostUseCase,
  }) : super(GroupDashboardPostsInitial());

  Future<void> fetchPosts(String groupId) async {
    emit(GroupDashboardPostsLoading());

    // The backend has no status filter, so moderators filter one bounded page locally.
    final result = await getPostsUseCase(groupId, limit: 100);

    result.fold((failure) => emit(GroupDashboardPostsError(failure)), (posts) {
      final pendingPosts = posts
          .where((p) => p.status == 'pending_review')
          .toList();
      final publishedPosts = posts.where((p) => p.status == 'active').toList();

      emit(
        GroupDashboardPostsLoaded(
          pendingPosts: pendingPosts,
          publishedPosts: publishedPosts,
        ),
      );
    });
  }

  Future<void> approvePost(String groupId, String postId) async {
    if (state is! GroupDashboardPostsLoaded) return;
    final currentState = state as GroupDashboardPostsLoaded;

    final result = await updatePostStatusUseCase(postId, 'active');
    result.fold((failure) => emit(GroupDashboardPostsError(failure)), (
      updatedPost,
    ) {
      // Remove from pending and add to published locally
      final newPending = currentState.pendingPosts
          .where((p) => p.id != postId)
          .toList();
      final newPublished = List.of(currentState.publishedPosts)
        ..insert(0, updatedPost);
      emit(
        GroupDashboardPostsLoaded(
          pendingPosts: newPending,
          publishedPosts: newPublished,
        ),
      );
    });
  }

  Future<void> rejectPost(String groupId, String postId) async {
    if (state is! GroupDashboardPostsLoaded) return;
    final currentState = state as GroupDashboardPostsLoaded;

    final result = await updatePostStatusUseCase(postId, 'blocked');
    result.fold((failure) => emit(GroupDashboardPostsError(failure)), (
      updatedPost,
    ) {
      final newPending = currentState.pendingPosts
          .where((p) => p.id != postId)
          .toList();
      emit(
        GroupDashboardPostsLoaded(
          pendingPosts: newPending,
          publishedPosts: currentState.publishedPosts,
        ),
      );
    });
  }

  Future<void> deletePost(String groupId, String postId) async {
    if (state is! GroupDashboardPostsLoaded) return;
    final currentState = state as GroupDashboardPostsLoaded;

    final result = await deletePostUseCase(postId);
    result.fold((failure) => emit(GroupDashboardPostsError(failure)), (_) {
      final newPublished = currentState.publishedPosts
          .where((p) => p.id != postId)
          .toList();
      emit(
        GroupDashboardPostsLoaded(
          pendingPosts: currentState.pendingPosts,
          publishedPosts: newPublished,
        ),
      );
    });
  }
}
