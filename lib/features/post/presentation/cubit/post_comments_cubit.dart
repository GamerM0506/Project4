import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/add_comment_usecase.dart';

abstract class PostCommentsState {}

class PostCommentsInitial extends PostCommentsState {}

class PostCommentsLoading extends PostCommentsState {}

class PostCommentsLoaded extends PostCommentsState {
  final List<CommentEntity> comments;
  final bool hasReachedMax;
  final bool isLoadingMore;
  PostCommentsLoaded(
    this.comments, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });
}

class PostCommentsError extends PostCommentsState {
  final String message;
  PostCommentsError(this.message);
}

class PostCommentsCubit extends Cubit<PostCommentsState> {
  final GetCommentsUseCase getCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;
  static const _limit = 20;

  PostCommentsCubit({
    required this.getCommentsUseCase,
    required this.addCommentUseCase,
  }) : super(PostCommentsInitial());

  Future<void> fetchComments(String postId) async {
    emit(PostCommentsLoading());
    final result = await getCommentsUseCase(postId, limit: _limit);

    result.fold(
      (error) => emit(PostCommentsError(error)),
      (comments) => emit(
        PostCommentsLoaded(
          _sortAndDedupe(comments),
          hasReachedMax: comments.length < _limit,
        ),
      ),
    );
  }

  Future<void> loadMore(String postId) async {
    final current = state;
    if (current is! PostCommentsLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    emit(
      PostCommentsLoaded(
        current.comments,
        hasReachedMax: current.hasReachedMax,
        isLoadingMore: true,
      ),
    );
    final result = await getCommentsUseCase(
      postId,
      limit: _limit,
      offset: current.comments.length,
    );
    result.fold(
      (error) => emit(PostCommentsError(error)),
      (comments) => emit(
        PostCommentsLoaded(
          _sortAndDedupe([...current.comments, ...comments]),
          hasReachedMax: comments.length < _limit,
        ),
      ),
    );
  }

  Future<bool> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    final currentState = state;
    if (currentState is PostCommentsLoaded) {
      final result = await addCommentUseCase(
        postId,
        content,
        parentId: parentId,
      );
      return result.fold(
        (error) {
          emit(PostCommentsError(error));
          return false;
        },
        (comment) {
          emit(
            PostCommentsLoaded(
              _sortAndDedupe([...currentState.comments, comment]),
              hasReachedMax: currentState.hasReachedMax,
            ),
          );
          return true;
        },
      );
    }
    return false;
  }

  List<CommentEntity> _sortAndDedupe(List<CommentEntity> comments) {
    final unique = <String, CommentEntity>{
      for (final comment in comments) comment.id: comment,
    }.values.toList();
    unique.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return unique;
  }
}
