import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/group/data/datasources/group_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late GroupRemoteDataSourceImpl dataSource;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({AppConstants.keyUserId: 'user-a'});
    preferences = await SharedPreferences.getInstance();
    final apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    when(() => apiClient.sharedPreferences).thenReturn(preferences);
    dataSource = GroupRemoteDataSourceImpl(apiClient);
  });

  test('stores pending joins separately for each account', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'id': '33333333-3333-3333-3333-333333333333',
            'group_id': '11111111-1111-1111-1111-111111111111',
            'user_id': '22222222-2222-2222-2222-222222222222',
            'message': null,
            'status': 'pending',
            'reviewed_by': null,
            'reviewed_at': null,
            'created_at': '2026-07-24T00:00:00Z',
          },
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.joinGroup('11111111-1111-1111-1111-111111111111');
    expect(
      dataSource.hasPendingJoin('11111111-1111-1111-1111-111111111111'),
      isTrue,
    );

    await preferences.setString(AppConstants.keyUserId, 'user-b');
    expect(
      dataSource.hasPendingJoin('11111111-1111-1111-1111-111111111111'),
      isFalse,
    );
  });

  test('loads membership fields from the real groups/me envelope', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'items': [_groupJson(myRole: 'moderator', myStatus: 'approved')],
            'meta': {'total': 1, 'limit': 20, 'offset': 0},
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final groups = await dataSource.getMyGroups(memberStatus: 'approved');

    verify(
      () => dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/me',
        queryParameters: {
          'limit': 20,
          'offset': 0,
          'member_status': 'approved',
        },
      ),
    ).called(1);
    expect(groups.single.myRole, 'moderator');
    expect(groups.single.myStatus, 'approved');
  });

  test('enriches group detail with approved membership', () async {
    const groupId = '11111111-1111-1111-1111-111111111111';
    when(
      () => dio.get('${AppConstants.communityApiBaseUrl}/groups/$groupId'),
    ).thenAnswer(
      (_) async => Response(
        data: {'data': _groupJson()},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );
    when(
      () => dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/me',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'items': [_groupJson(myRole: 'member', myStatus: 'approved')],
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final group = await dataSource.getGroupDetail(groupId);

    expect(group.myRole, 'member');
    expect(group.myStatus, 'approved');
  });

  test('sends all backend-supported group update fields', () async {
    when(() => dio.patch(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {'data': _groupJson()},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.updateGroup(
      'group-id',
      address: '1 Main Street',
      provinceCode: '79',
      districtCode: '760',
      allowMemberPost: false,
      requirePostReview: true,
    );

    verify(
      () => dio.patch(
        '${AppConstants.communityApiBaseUrl}/groups/group-id',
        data: {
          'address': '1 Main Street',
          'province_code': '79',
          'district_code': '760',
          'allow_member_post': false,
          'require_post_review': true,
        },
      ),
    ).called(1);
  });

  test('approveGroup calls the backend admin endpoint', () async {
    when(() => dio.post(any())).thenAnswer(
      (_) async => Response(
        data: {'data': _groupJson()},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.approveGroup('group-id');

    verify(
      () => dio.post(
        '${AppConstants.communityApiBaseUrl}/admin/groups/group-id/approve',
      ),
    ).called(1);
  });

  test('reads an error.message from the community error envelope', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 422,
          data: {
            'statusCode': 422,
            'error': {'message': 'Validation failed', 'details': []},
          },
        ),
      ),
    );

    expect(
      () => dataSource.joinGroup('group-id'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Validation failed'),
        ),
      ),
    );
  });
}

Map<String, dynamic> _groupJson({String? myRole, String? myStatus}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'name': 'Community group',
  'slug': 'community-group',
  'description': null,
  'avatar_url': null,
  'cover_url': null,
  'address': '1 Main Street',
  'province_code': '79',
  'district_code': '760',
  'owner_id': '22222222-2222-2222-2222-222222222222',
  'status': 'active',
  'allow_member_post': true,
  'require_post_review': false,
  'member_count': 1,
  'reputation_score': 0,
  'created_at': '2026-07-24T00:00:00Z',
  'updated_at': '2026-07-24T00:00:00Z',
  'my_role': ?myRole,
  'my_status': ?myStatus,
};
