import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/features/post/data/models/comment_model.dart';
import 'package:project4_chosv/features/post/data/models/post_model.dart';

Map<String, dynamic> postJson({Map<String, dynamic>? author}) => {
  'id': 'post-1',
  'group_id': 'group-1',
  'author_id': 'a1111111-1111-1111-1111-111111111111',
  'content': 'Nội dung bài viết',
  'type': 'normal',
  'ref_id': null,
  'status': 'active',
  'is_pinned': false,
  'like_count': 0,
  'comment_count': 0,
  'images': [],
  'created_at': '2026-08-01T00:00:00Z',
  'updated_at': '2026-08-01T00:00:00Z',
  'author': author,
};

Map<String, dynamic> commentJson({Map<String, dynamic>? author}) => {
  'id': 'c-1',
  'post_id': 'post-1',
  'author_id': 'a1111111-1111-1111-1111-111111111111',
  'parent_id': null,
  'content': 'Bình luận',
  'status': 'active',
  'created_at': '2026-08-01T00:00:00Z',
  'author': author,
};

void main() {
  group('tác giả bài viết', () {
    test('đọc được họ tên và avatar', () {
      final post = PostModel.fromJson(
        postJson(
          author: {
            'id': 'a1111111-1111-1111-1111-111111111111',
            'full_name': 'Nguyễn Văn An',
            'username': 'nguyenvanan',
            'avatar_url': 'https://cdn/an.jpg',
          },
        ),
      );

      expect(post.authorName, 'Nguyễn Văn An');
      expect(post.authorAvatar, 'https://cdn/an.jpg');
      expect(post.displayAuthorName, 'Nguyễn Văn An');
    });

    test('thiếu họ tên thì lùi về username', () {
      final post = PostModel.fromJson(
        postJson(author: {'id': 'x', 'username': 'tranthibinh'}),
      );

      expect(post.displayAuthorName, '@tranthibinh');
    });

    test('identity lỗi thì lùi về mã rút gọn, không vỡ giao diện', () {
      final post = PostModel.fromJson(postJson());

      expect(post.authorName, isNull);
      expect(post.displayAuthorName, 'Người dùng a111');
    });

    test('copyWithLike giữ nguyên thông tin tác giả', () {
      final post = PostModel.fromJson(
        postJson(author: {'id': 'x', 'full_name': 'Nguyễn Văn An'}),
      );

      final liked = post.copyWithLike(isLiked: true, likeCount: 1);

      expect(liked.authorName, 'Nguyễn Văn An');
      expect(liked.isLiked, isTrue);
    });
  });

  group('tác giả bình luận', () {
    test('đọc từ khối author', () {
      final comment = CommentModel.fromJson(
        commentJson(
          author: {
            'id': 'x',
            'full_name': 'Trần Thị Bình',
            'avatar_url': 'https://cdn/b.jpg',
          },
        ),
      );

      expect(comment.authorName, 'Trần Thị Bình');
      expect(comment.authorAvatar, 'https://cdn/b.jpg');
    });

    test('không có author thì để null cho UI tự lùi', () {
      final comment = CommentModel.fromJson(commentJson());

      expect(comment.authorName, isNull);
      expect(comment.content, 'Bình luận');
    });

    test('vẫn đọc được dạng phẳng cũ author_name', () {
      final json = commentJson()..['author_name'] = 'Tên cũ';

      expect(CommentModel.fromJson(json).authorName, 'Tên cũ');
    });
  });
}
