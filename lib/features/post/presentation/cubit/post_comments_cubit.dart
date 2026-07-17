import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/add_comment_usecase.dart';

abstract class PostCommentsState {}

class PostCommentsInitial extends PostCommentsState {}

class PostCommentsLoading extends PostCommentsState {}

class PostCommentsLoaded extends PostCommentsState {
  final List<CommentEntity> comments;
  PostCommentsLoaded(this.comments);
}

class PostCommentsError extends PostCommentsState {
  final String message;
  PostCommentsError(this.message);
}

class PostCommentsCubit extends Cubit<PostCommentsState> {
  final GetCommentsUseCase getCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;

  PostCommentsCubit({
    required this.getCommentsUseCase,
    required this.addCommentUseCase,
  }) : super(PostCommentsInitial());

  Future<void> fetchComments(String postId) async {
    emit(PostCommentsLoading());
    final result = await getCommentsUseCase(postId);

    result.fold(
      (error) => emit(PostCommentsError(error)),
      (comments) => emit(PostCommentsLoaded(comments)),
    );
  }

  Future<void> addComment(String postId, String content) async {
    final currentState = state;
    if (currentState is PostCommentsLoaded) {
      final result = await addCommentUseCase(postId, content);
      result.fold(
        (error) {}, // Could show a toast or error state
        (comment) {
          emit(PostCommentsLoaded([comment, ...currentState.comments]));
        },
      );
    }
  }
}
