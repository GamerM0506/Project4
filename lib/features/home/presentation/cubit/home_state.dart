import 'package:equatable/equatable.dart';

import '../../data/models/feed_post_model.dart';
import '../../data/models/group_model.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.groups = const [],
    this.feed = const [],
    this.hasMoreFeed = true,
    this.loadingMoreFeed = false,
    this.feedError,
    this.errorMessage,
  });

  final HomeStatus status;
  final List<GroupModel> groups;

  /// Bài viết từ các hội nhóm, mới nhất trước.
  final List<FeedPostModel> feed;
  final bool hasMoreFeed;
  final bool loadingMoreFeed;

  /// Lỗi riêng của feed — hội nhóm nổi bật vẫn hiển thị được.
  final String? feedError;

  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    List<GroupModel>? groups,
    List<FeedPostModel>? feed,
    bool? hasMoreFeed,
    bool? loadingMoreFeed,
    String? feedError,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      feed: feed ?? this.feed,
      hasMoreFeed: hasMoreFeed ?? this.hasMoreFeed,
      loadingMoreFeed: loadingMoreFeed ?? this.loadingMoreFeed,
      feedError: feedError,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    groups,
    feed,
    hasMoreFeed,
    loadingMoreFeed,
    feedError,
    errorMessage,
  ];
}
