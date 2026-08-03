import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/post/data/datasources/post_remote_data_source.dart';
import 'package:project4_chosv/features/post/data/models/comment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

Map<String, dynamic> commentJson({String? parentId}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'post_id': '22222222-2222-2222-2222-222222222222',
  'author_id': '33333333-3333-3333-3333-333333333333',
  'parent_id': parentId,
  'content': 'Nội dung bình luận',
  'status': 'active',
  'created_at': '2026-08-01T00:00:00Z',
};

void main() {
  late MockDio dio;
  late PostRemoteDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({AppConstants.keyUserId: 'user-a'});
    final preferences = await SharedPreferences.getInstance();
    final apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    when(() => apiClient.sharedPreferences).thenReturn(preferences);
    dataSource = PostRemoteDataSourceImpl(apiClient: apiClient);
  });

  void stubPost(Map<String, dynamic> payload) {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 201,
        data: {'data': payload},
      ),
    );
  }

  group('gửi bình luận', () {
    test('bình luận gốc không gửi parent_id', () async {
      stubPost(commentJson());

      await dataSource.addComment('post-1', 'Xin chào');

      verify(
        () => dio.post(
          '${AppConstants.communityApiBaseUrl}/posts/post-1/comments',
          data: {'content': 'Xin chào'},
        ),
      ).called(1);
    });

    test('trả lời gửi kèm parent_id', () async {
      stubPost(commentJson(parentId: 'comment-1'));

      await dataSource.addComment(
        'post-1',
        'Mình đồng ý',
        parentId: 'comment-1',
      );

      verify(
        () => dio.post(
          '${AppConstants.communityApiBaseUrl}/posts/post-1/comments',
          data: {'content': 'Mình đồng ý', 'parent_id': 'comment-1'},
        ),
      ).called(1);
    });

    test('parent_id rỗng hoặc toàn khoảng trắng bị bỏ qua', () async {
      stubPost(commentJson());

      await dataSource.addComment('post-1', 'Nội dung', parentId: '   ');

      verify(
        () => dio.post(
          '${AppConstants.communityApiBaseUrl}/posts/post-1/comments',
          data: {'content': 'Nội dung'},
        ),
      ).called(1);
    });
  });

  group('đọc bình luận', () {
    test('bình luận gốc có parentId null', () {
      final comment = CommentModel.fromJson(commentJson());

      expect(comment.parentId, isNull);
      expect(comment.isReply, isFalse);
    });

    test('trả lời giữ được parentId', () {
      final comment = CommentModel.fromJson(commentJson(parentId: 'c-goc'));

      expect(comment.parentId, 'c-goc');
      expect(comment.isReply, isTrue);
    });

    test('danh sách bình luận đọc được parent_id', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'data': {
              'items': [commentJson(), commentJson(parentId: 'c-goc')],
              'meta': {'total': 2, 'limit': 20, 'offset': 0},
            },
          },
        ),
      );

      final comments = await dataSource.getComments('post-1');

      expect(comments, hasLength(2));
      expect(comments[0].isReply, isFalse);
      expect(comments[1].isReply, isTrue);
    });
  });
}
