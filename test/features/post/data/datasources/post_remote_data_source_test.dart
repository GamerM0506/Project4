import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/post/data/datasources/post_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late SharedPreferences preferences;
  late PostRemoteDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({AppConstants.keyUserId: 'user-a'});
    preferences = await SharedPreferences.getInstance();
    final apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    when(() => apiClient.sharedPreferences).thenReturn(preferences);
    dataSource = PostRemoteDataSourceImpl(apiClient: apiClient);
  });

  test('hides a post using the backend content status', () async {
    when(() => dio.patch(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {'data': _postJson(status: 'hidden')},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.deletePost('post-id');

    verify(
      () => dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/post-id',
        data: {'status': 'hidden'},
      ),
    ).called(1);
  });

  test('parses pending_review from the real post envelope', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'items': [_postJson(status: 'pending_review')],
            'meta': {'total': 1, 'limit': 20, 'offset': 0},
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final posts = await dataSource.getGroupPosts('group-id');

    expect(posts.single.status, 'pending_review');
  });

  test('reads a string error from the community error envelope', () async {
    when(() => dio.patch(any(), data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 403,
          data: {'statusCode': 403, 'error': 'Moderator required'},
        ),
      ),
    );

    expect(
      () => dataSource.deletePost('post-id'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Moderator required'),
        ),
      ),
    );
  });

  test('restores liked posts only for the current account', () async {
    when(() => dio.post(any())).thenAnswer(
      (_) async => Response(
        data: {
          'data': {'message': 'liked; like_count=1'},
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'items': [_postJson(status: 'active')],
            'meta': {'total': 1, 'limit': 20, 'offset': 0},
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.likePost('11111111-1111-1111-1111-111111111111');
    expect((await dataSource.getGroupPosts('group-id')).single.isLiked, isTrue);

    await preferences.setString(AppConstants.keyUserId, 'user-b');
    expect(
      (await dataSource.getGroupPosts('group-id')).single.isLiked,
      isFalse,
    );
  });
  test('pins a post through the backend patch contract', () async {
    when(() => dio.patch(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {'data': _postJson(status: 'active', isPinned: true)},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final post = await dataSource.setPostPinned('post-id', true);

    verify(
      () => dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/post-id',
        data: {'is_pinned': true},
      ),
    ).called(1);
    expect(post.isPinned, isTrue);
  });

  test('unpins a post through the backend patch contract', () async {
    when(() => dio.patch(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {'data': _postJson(status: 'active')},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final post = await dataSource.setPostPinned('post-id', false);

    verify(
      () => dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/post-id',
        data: {'is_pinned': false},
      ),
    ).called(1);
    expect(post.isPinned, isFalse);
  });

  test('reads the post detail envelope', () async {
    when(() => dio.get(any())).thenAnswer(
      (_) async => Response(
        data: {'data': _postJson(status: 'active', isPinned: true)},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final post = await dataSource.getPostDetail('post-id');

    verify(
      () => dio.get('${AppConstants.communityApiBaseUrl}/posts/post-id'),
    ).called(1);
    expect(post.id, '11111111-1111-1111-1111-111111111111');
    expect(post.isPinned, isTrue);
  });
}

Map<String, dynamic> _postJson({
  required String status,
  bool isPinned = false,
}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'group_id': '22222222-2222-2222-2222-222222222222',
  'author_id': '33333333-3333-3333-3333-333333333333',
  'content': 'Post content',
  'type': 'normal',
  'ref_id': null,
  'status': status,
  'is_pinned': isPinned,
  'like_count': 0,
  'comment_count': 0,
  'images': [],
  'created_at': '2026-07-24T00:00:00Z',
  'updated_at': '2026-07-24T00:00:00Z',
};
