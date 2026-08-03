import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/home/data/home_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

Map<String, dynamic> feedPostJson({
  String id = 'post-1',
  String groupName = 'Cộng đồng Từ thiện Hà Nội',
  List<Map<String, dynamic>> images = const [],
  String? myStatus,
  String? myRole,
  bool isLiked = false,
  bool canInteract = false,
  Map<String, dynamic>? author = const {
    'id': 'user-1',
    'full_name': 'Nguyễn Văn An',
    'username': 'nguyenvanan',
    'avatar_url': 'https://cdn/an.jpg',
  },
}) => {
  'id': id,
  'group_id': 'group-1',
  'author_id': 'user-1',
  'content': 'Kêu gọi quyên góp áo ấm',
  'type': 'call_for_donation',
  'ref_id': null,
  'status': 'active',
  'is_pinned': false,
  'like_count': 5,
  'comment_count': 2,
  'images': images,
  'created_at': '2026-08-01T00:00:00Z',
  'updated_at': '2026-08-01T00:00:00Z',
  'is_liked': isLiked,
  'can_interact': canInteract,
  'author': author,
  'group': {
    'id': 'group-1',
    'name': groupName,
    'slug': 'cong-dong-ha-noi',
    'avatar_url': 'https://cdn/avatar.jpg',
    'my_role': myRole,
    'my_status': myStatus,
  },
};

void main() {
  late MockDio dio;
  late HomeRepository repository;

  setUp(() {
    final apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    repository = HomeRepository(apiClient: apiClient);
  });

  void stubFeed(List<Map<String, dynamic>> items, {int? total}) {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/feed'),
        data: {
          'data': {
            'items': items,
            'meta': {
              'total': total ?? items.length,
              'limit': 10,
              'offset': 0,
            },
          },
        },
      ),
    );
  }

  test('đọc feed kèm thông tin hội nhóm', () async {
    stubFeed([feedPostJson()]);

    final page = await repository.getFeed();

    expect(page.total, 1);
    final item = page.items.single;
    expect(item.post.content, 'Kêu gọi quyên góp áo ấm');
    expect(item.group.name, 'Cộng đồng Từ thiện Hà Nội');
    expect(item.group.avatarUrl, 'https://cdn/avatar.jpg');
  });

  test('gọi đúng endpoint feed với phân trang', () async {
    stubFeed([]);

    await repository.getFeed(limit: 5, offset: 20);

    verify(
      () => dio.get(
        '${AppConstants.communityApiBaseUrl}/feed',
        queryParameters: {'limit': 5, 'offset': 20},
      ),
    ).called(1);
  });

  test('lấy được danh sách ảnh của bài viết', () async {
    stubFeed([
      feedPostJson(
        images: [
          {'id': 'i1', 'image_url': 'https://cdn/1.jpg', 'sort_order': 0},
          {'id': 'i2', 'image_url': 'https://cdn/2.jpg', 'sort_order': 1},
        ],
      ),
    ]);

    final page = await repository.getFeed();

    expect(page.items.single.post.imageUrls, [
      'https://cdn/1.jpg',
      'https://cdn/2.jpg',
    ]);
  });

  test('vẫn dựng được bài viết khi thiếu khối group', () async {
    final json = feedPostJson()..remove('group');
    stubFeed([json]);

    final page = await repository.getFeed();

    expect(page.items.single.group.id, 'group-1');
    expect(page.items.single.group.name, 'Hội nhóm');
  });

  test('feed rỗng trả danh sách rỗng', () async {
    stubFeed([]);

    final page = await repository.getFeed();

    expect(page.items, isEmpty);
    expect(page.total, 0);
  });

  test('không lấy dư 100 nhóm cho mục nổi bật', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/groups'),
        data: {
          'data': {
            'items': [],
            'meta': {'total': 0, 'limit': 20, 'offset': 0},
          },
        },
      ),
    );

    await repository.getFeaturedGroups(limit: 5);

    final captured = verify(
      () => dio.get(
        '${AppConstants.communityApiBaseUrl}/groups',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map;
    expect(captured['limit'], lessThan(100));
  });

  group('quyền tương tác của người xem', () {
    test('thành viên đã duyệt thì tương tác được', () async {
      stubFeed([
        feedPostJson(myStatus: 'approved', canInteract: true, isLiked: true),
      ]);

      final item = (await repository.getFeed()).items.single;

      expect(item.canInteract, isTrue);
      expect(item.isLiked, isTrue);
      expect(item.group.isMember, isTrue);
      expect(item.group.canRequestJoin, isFalse);
    });

    test('chưa tham gia thì bị chặn và được mời vào nhóm', () async {
      stubFeed([feedPostJson()]);

      final item = (await repository.getFeed()).items.single;

      expect(item.canInteract, isFalse);
      expect(item.group.isMember, isFalse);
      expect(item.group.canRequestJoin, isTrue);
    });

    test('đang chờ duyệt thì không mời tham gia lại', () async {
      stubFeed([feedPostJson(myStatus: 'pending')]);

      final group = (await repository.getFeed()).items.single.group;

      expect(group.isPending, isTrue);
      expect(group.canRequestJoin, isFalse);
    });

    test('bị cấm thì không mời tham gia', () async {
      stubFeed([feedPostJson(myStatus: 'banned')]);

      final group = (await repository.getFeed()).items.single.group;

      expect(group.isMember, isFalse);
      expect(group.canRequestJoin, isFalse);
    });

    test('chủ nhóm được coi là thành viên dù thiếu my_status', () async {
      stubFeed([feedPostJson(myRole: 'owner', canInteract: true)]);

      final group = (await repository.getFeed()).items.single.group;

      expect(group.isMember, isTrue);
      expect(group.canRequestJoin, isFalse);
    });
  });

  group('tác giả bài viết', () {
    test('đọc được tên và avatar tác giả', () async {
      stubFeed([feedPostJson()]);

      final author = (await repository.getFeed()).items.single.author;

      expect(author, isNotNull);
      expect(author!.displayName, 'Nguyễn Văn An');
      expect(author.avatarUrl, 'https://cdn/an.jpg');
    });

    test('thiếu họ tên thì hiện username', () async {
      stubFeed([
        feedPostJson(
          author: const {'id': 'user-1', 'username': 'tranthibinh'},
        ),
      ]);

      final author = (await repository.getFeed()).items.single.author;

      expect(author!.displayName, '@tranthibinh');
    });

    test('thiếu cả hai thì có nhãn dự phòng', () async {
      stubFeed([feedPostJson(author: const {'id': 'user-1'})]);

      final author = (await repository.getFeed()).items.single.author;

      expect(author!.displayName, 'Người dùng');
    });

    test('identity lỗi thì author null nhưng bài vẫn dựng được', () async {
      stubFeed([feedPostJson(author: null)]);

      final item = (await repository.getFeed()).items.single;

      expect(item.author, isNull);
      expect(item.post.content, 'Kêu gọi quyên góp áo ấm');
      expect(item.group.name, isNotEmpty);
    });
  });
}
