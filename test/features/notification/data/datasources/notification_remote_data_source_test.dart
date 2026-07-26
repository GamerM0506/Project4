import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/notification/data/datasources/notification_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NotificationRemoteDataSourceImpl dataSource;

  setUp(() {
    final apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    dataSource = NotificationRemoteDataSourceImpl(apiClient: apiClient);
  });

  test('parses backend bare list and all reference/timestamp fields', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: [
          {
            'id': 'notification-1',
            'title': 'Tin nhan moi',
            'body': 'Noi dung',
            'type': 'chat_message',
            'ref_type': 'conversation',
            'ref_id': 'conversation-1',
            'created_at': '2026-07-24T10:00:00Z',
            'is_read': true,
            'read_at': '2026-07-24T11:00:00Z',
          },
        ],
      ),
    );

    final result = await dataSource.getNotifications(limit: 20, offset: 10);

    expect(result.single.refType, 'conversation');
    expect(result.single.refId, 'conversation-1');
    expect(result.single.createdAt, DateTime.parse('2026-07-24T10:00:00Z'));
    expect(result.single.readAt, DateTime.parse('2026-07-24T11:00:00Z'));
    expect(result.single.isRead, isTrue);
    verify(
      () => dio.get(
        '${AppConstants.chatApiBaseUrl}/notifications',
        queryParameters: {'limit': 20, 'offset': 10},
      ),
    ).called(1);
  });

  test('also accepts a data envelope', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'data': [
            {
              'id': 'notification-2',
              'title': 'Thong bao',
              'body': 'Noi dung',
              'type': 'system',
              'created_at': '2026-07-24T10:00:00Z',
              'read_at': null,
            },
          ],
        },
      ),
    );

    final result = await dataSource.getNotifications();

    expect(result.single.id, 'notification-2');
    expect(result.single.isRead, isFalse);
  });

  test('uses exact backend device request bodies', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(requestOptions: RequestOptions(path: '')),
    );
    when(() => dio.delete(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(requestOptions: RequestOptions(path: '')),
    );

    await dataSource.registerDeviceToken('fcm-1', 'android');
    await dataSource.unregisterDeviceToken('fcm-1');

    verify(
      () => dio.post(
        '${AppConstants.chatApiBaseUrl}/devices/tokens',
        data: {'fcmToken': 'fcm-1', 'platform': 'android'},
      ),
    ).called(1);
    verify(
      () => dio.delete(
        '${AppConstants.chatApiBaseUrl}/devices/tokens',
        data: {'fcmToken': 'fcm-1'},
      ),
    ).called(1);
  });
}
