import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../post/domain/repositories/post_repository.dart';
import '../../data/home_repository.dart';
import '../../data/models/feed_post_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this.repository, required this.postRepository})
    : super(const HomeState());

  final HomeRepository repository;
  final PostRepository postRepository;

  static const _pageSize = 10;
  bool _loadingMore = false;

  Future<void> fetchHomeData() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      // Feed và hội nhóm độc lập nhau: feed lỗi thì vẫn hiện được nhóm nổi bật.
      final results = await Future.wait([
        repository.getFeaturedGroups(limit: 5),
        repository.getFeed(limit: _pageSize).then<Object?>(
          (page) => page,
          onError: (Object error) => error,
        ),
      ]);

      final groups = results[0] as List;
      final feedResult = results[1];

      if (feedResult is FeedPage) {
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            groups: groups.cast(),
            feed: feedResult.items,
            hasMoreFeed: feedResult.items.length >= _pageSize,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            groups: groups.cast(),
            feed: const [],
            hasMoreFeed: false,
            feedError: _message(feedResult),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> loadMoreFeed() async {
    if (_loadingMore || !state.hasMoreFeed) return;
    if (state.status != HomeStatus.loaded) return;

    _loadingMore = true;
    emit(state.copyWith(loadingMoreFeed: true));
    try {
      final page = await repository.getFeed(
        limit: _pageSize,
        offset: state.feed.length,
      );
      // Chống trùng: bài mới đăng có thể đẩy phân trang lệch một nhịp.
      final seen = state.feed.map((item) => item.post.id).toSet();
      final merged = [
        ...state.feed,
        ...page.items.where((item) => !seen.contains(item.post.id)),
      ];
      emit(
        state.copyWith(
          feed: merged,
          hasMoreFeed: page.items.length >= _pageSize,
          loadingMoreFeed: false,
        ),
      );
    } catch (_) {
      // Lỗi tải thêm không nên xoá feed đang có.
      emit(state.copyWith(loadingMoreFeed: false, hasMoreFeed: false));
    } finally {
      _loadingMore = false;
    }
  }

  static String _message(Object? error) =>
      error?.toString().replaceAll('Exception: ', '') ?? 'Đã xảy ra lỗi';

  /// Thích/bỏ thích ngay trên feed. Cập nhật lạc quan, hoàn tác khi lỗi.
  Future<void> toggleLike(String postId) async {
    final index = state.feed.indexWhere((item) => item.post.id == postId);
    if (index < 0) return;

    final original = state.feed[index];
    if (!original.canInteract) return;

    final liked = original.isLiked;
    _replaceFeedItem(
      index,
      original.copyWith(
        isLiked: !liked,
        post: original.post.copyWithLike(
          isLiked: !liked,
          likeCount: liked
              ? (original.post.likeCount - 1).clamp(0, 1 << 31)
              : original.post.likeCount + 1,
        ),
      ),
    );

    try {
      final result = liked
          ? await postRepository.unlikePost(postId)
          : await postRepository.likePost(postId);
      result.fold((_) => _rollbackLike(postId, original), (_) {});
    } catch (_) {
      _rollbackLike(postId, original);
    }
  }

  void _rollbackLike(String postId, FeedPostModel original) {
    final index = state.feed.indexWhere((item) => item.post.id == postId);
    if (index >= 0) _replaceFeedItem(index, original);
  }

  /// Đánh dấu đã gửi yêu cầu tham gia để đổi nút ngay, không phải tải lại feed.
  void markJoinRequested(String groupId) {
    if (groupId.isEmpty) return;
    final feed = [
      for (final item in state.feed)
        item.group.id == groupId
            ? item.copyWith(group: item.group.copyWith(myStatus: 'pending'))
            : item,
    ];
    // Cập nhật cả băng chuyền hội nhóm nổi bật, nếu không nút vẫn hiện
    // "Tham gia" dù người dùng vừa gửi yêu cầu.
    final groups = [
      for (final group in state.groups)
        group.id == groupId ? group.copyWith(myStatus: 'pending') : group,
    ];
    emit(state.copyWith(feed: feed, groups: groups));
  }

  void _replaceFeedItem(int index, FeedPostModel item) {
    final feed = [...state.feed];
    feed[index] = item;
    emit(state.copyWith(feed: feed));
  }
}
