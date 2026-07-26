import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient apiClient;
  late MockDio dio;
  late ChatRemoteDataSourceImpl dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({AppConstants.keyUserId: 'user-1'});
    apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    dataSource = ChatRemoteDataSourceImpl(apiClient: apiClient);
  });

  test('loads conversations for a group using the backend contract', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: [
          {
            'id': 'conversation-1',
            'type': 'donor_group',
            'group_id': 'group-1',
            'user_id': 'user-1',
            'context_type': 'donation',
            'context_id': 'donation-1',
            'last_message_preview': 'Xin chao',
            'last_message_at': '2026-07-24T10:00:00Z',
          },
        ],
      ),
    );

    final result = await dataSource.getConversations(groupId: 'group-1');

    expect(result.single.id, 'conversation-1');
    expect(result.single.groupId, 'group-1');
    expect(result.single.userId, 'user-1');
    expect(result.single.contextType, 'donation');
    expect(result.single.contextId, 'donation-1');
    expect(result.single.lastMessage, 'Xin chao');
    verify(
      () => dio.get(
        '${AppConstants.chatApiBaseUrl}/conversations',
        queryParameters: {'groupId': 'group-1'},
      ),
    ).called(1);
  });

  test('maps message ownership from the persisted user id', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: [
          {
            'id': 'message-1',
            'sender_id': 'user-1',
            'content': 'Da gui',
            'type': 'text',
            'created_at': '2026-07-24T10:00:00Z',
          },
        ],
      ),
    );

    final result = await dataSource.getMessages('conversation-1');

    expect(result.single.isMine, isTrue);
    verify(
      () => dio.get(
        '${AppConstants.chatApiBaseUrl}/conversations/conversation-1/messages',
        queryParameters: {'limit': 50, 'offset': 0},
      ),
    ).called(1);
  });

  test('does not swallow backend errors when sending a message', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
      ),
    );

    expect(
      () => dataSource.sendMessage('missing-conversation', 'Hello'),
      throwsA(isA<DioException>()),
    );
  });

  test('sends an uploaded image URL using the image message type', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'id': 'message-image',
          'sender_id': 'user-1',
          'content': 'https://cdn.example.com/chat/image.jpg',
          'type': 'image',
          'created_at': '2026-07-24T10:00:00Z',
        },
      ),
    );

    final result = await dataSource.sendMessage(
      'conversation-1',
      'https://cdn.example.com/chat/image.jpg',
      type: 'image',
    );

    expect(result.type, 'image');
    expect(result.content, 'https://cdn.example.com/chat/image.jpg');
    verify(
      () => dio.post(
        '${AppConstants.chatApiBaseUrl}/conversations/conversation-1/messages',
        data: {
          'content': 'https://cdn.example.com/chat/image.jpg',
          'type': 'image',
        },
      ),
    ).called(1);
  });
}
