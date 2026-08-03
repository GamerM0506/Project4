import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/get_post_detail_usecase.dart';

enum PostDetailStatus { initial, loading, loaded, error }

class PostDetailState extends Equatable {
  final PostDetailStatus status;
  final PostEntity? post;
  final String? errorMessage;

  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.errorMessage,
  });

  PostDetailState copyWith({
    PostDetailStatus? status,
    PostEntity? post,
    String? errorMessage,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, post, errorMessage];
}

class PostDetailCubit extends Cubit<PostDetailState> {
  final GetPostDetailUseCase getPostDetailUseCase;

  PostDetailCubit({required this.getPostDetailUseCase})
    : super(const PostDetailState());

  Future<void> load(String postId) async {
    if (postId.trim().isEmpty) {
      emit(
        state.copyWith(
          status: PostDetailStatus.error,
          errorMessage: 'Không xác định được bài viết.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PostDetailStatus.loading));

    final result = await getPostDetailUseCase(postId.trim());
    result.fold(
      (error) => emit(
        state.copyWith(status: PostDetailStatus.error, errorMessage: error),
      ),
      (post) =>
          emit(state.copyWith(status: PostDetailStatus.loaded, post: post)),
    );
  }

  /// Cập nhật số bình luận tại chỗ sau khi người dùng vừa gửi bình luận mới.
  void incrementCommentCount() {
    final current = state.post;
    if (current == null) return;
    emit(
      state.copyWith(
        post: current.copyWith(commentCount: current.commentCount + 1),
      ),
    );
  }
}
