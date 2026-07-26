import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/like_post_usecase.dart';
import '../../domain/usecases/unlike_post_usecase.dart';
import 'group_feed_state.dart';
import '../../../../core/network/media_service.dart';

class GroupFeedCubit extends Cubit<GroupFeedState> {
  final GetPostsUseCase getPostsUseCase;
  final CreatePostUseCase createPostUseCase;
  final DeletePostUseCase deletePostUseCase;
  final LikePostUseCase likePostUseCase;
  final UnlikePostUseCase unlikePostUseCase;
  final MediaService? mediaService;
  final int _limit = 20;
  bool _isFetching = false;
  int _generation = 0;

  GroupFeedCubit({
    required this.getPostsUseCase,
    required this.createPostUseCase,
    required this.deletePostUseCase,
    required this.likePostUseCase,
    required this.unlikePostUseCase,
    this.mediaService,
  }) : super(GroupFeedInitial());

  Future<void> fetchPosts(String groupId, {bool isRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    final generation = isRefresh ? ++_generation : _generation;

    int offset = 0;
    if (!isRefresh && state is GroupFeedLoaded) {
      final currentState = state as GroupFeedLoaded;
      if (currentState.hasReachedMax) return;
      offset = currentState.posts.length;
    } else {
      emit(GroupFeedLoading());
    }

    final result = await getPostsUseCase(
      groupId,
      offset: offset,
      limit: _limit,
    );
    if (generation != _generation) {
      _isFetching = false;
      return;
    }

    result.fold((error) => emit(GroupFeedError(message: error)), (posts) {
      if (state is GroupFeedLoaded && !isRefresh) {
        final currentState = state as GroupFeedLoaded;
        emit(
          currentState.copyWith(
            posts: currentState.posts + posts,
            hasReachedMax: posts.isEmpty || posts.length < _limit,
          ),
        );
      } else {
        emit(
          GroupFeedLoaded(
            posts: posts,
            hasReachedMax: posts.isEmpty || posts.length < _limit,
          ),
        );
      }
    });
    _isFetching = false;
  }

  Future<void> createPost(
    String groupId,
    String content,
    String type,
    List<String> imageUrls, {
    List<String> mediaIds = const <String>[],
  }) async {
    final currentState = state;
    emit(GroupFeedCreating());

    final result = await createPostUseCase(groupId, content, type, imageUrls);

    result.fold(
      (error) {
        emit(GroupFeedCreateError(message: error));
        Future.delayed(const Duration(milliseconds: 100), () {
          if (currentState is GroupFeedLoaded) {
            emit(currentState);
          } else {
            fetchPosts(groupId, isRefresh: true);
          }
        });
      },
      (post) {
        if (mediaIds.isNotEmpty && mediaService != null) {
          mediaService!.linkMedia(mediaIds, 'post', post.id).catchError((_) {});
        }
        emit(GroupFeedCreateSuccess(post: post));
        Future.delayed(const Duration(milliseconds: 100), () {
          if (currentState is GroupFeedLoaded) {
            emit(currentState.copyWith(posts: [post, ...currentState.posts]));
          } else {
            fetchPosts(groupId, isRefresh: true);
          }
        });
      },
    );
  }

  Future<void> deletePost(String postId) async {
    final currentState = state;

    final result = await deletePostUseCase(postId);

    result.fold(
      (error) {
        if (currentState is GroupFeedLoaded) {
          emit(
            GroupFeedDeleteError(message: error, previousState: currentState),
          );
          emit(currentState);
        } else {
          emit(GroupFeedError(message: error));
        }
      },
      (_) {
        if (currentState is GroupFeedLoaded) {
          final newPosts = currentState.posts
              .where((p) => p.id != postId)
              .toList();
          emit(currentState.copyWith(posts: newPosts));
        }
      },
    );
  }

  Future<void> toggleLike(String postId) async {
    if (state is! GroupFeedLoaded) return;

    final currentState = state as GroupFeedLoaded;
    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentState.posts[postIndex];
    final isCurrentlyLiked = post.isLiked;

    // Optimistic UI update
    final updatedPost = post.copyWith(
      isLiked: !isCurrentlyLiked,
      likeCount: isCurrentlyLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    final newPosts = List<PostEntity>.from(currentState.posts);
    newPosts[postIndex] = updatedPost;
    emit(currentState.copyWith(posts: newPosts));

    // API Call
    final result = isCurrentlyLiked
        ? await unlikePostUseCase(postId)
        : await likePostUseCase(postId);

    result.fold((error) {
      // Rollback on error
      final rollbackPosts = List<PostEntity>.from(currentState.posts);
      rollbackPosts[postIndex] = post;
      emit(currentState.copyWith(posts: rollbackPosts));
    }, (_) {});
  }

  void incrementCommentCount(String postId) {
    if (state is! GroupFeedLoaded) return;
    final currentState = state as GroupFeedLoaded;
    final posts = currentState.posts.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(commentCount: post.commentCount + 1);
    }).toList();
    emit(currentState.copyWith(posts: posts));
  }
}
