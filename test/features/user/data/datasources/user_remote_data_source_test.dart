import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/user/data/datasources/user_remote_data_source.dart';
import 'package:project4_chosv/features/user/data/models/user_model.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late UserRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    dataSource = UserRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('UserRemoteDataSource', () {
    final tUserModel = UserModel(
      id: '1',
      email: 'test@example.com',
      fullName: 'Test User',
    );
    
    final tUserJson = {
      'id': '1',
      'email': 'test@example.com',
      'full_name': 'Test User',
    };

    test('should perform a GET request for getProfile', () async {
      // arrange
      when(() => mockDio.get(any())).thenAnswer((_) async => Response(
            data: tUserJson,
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));
      // act
      final result = await dataSource.getProfile();
      // assert
      verify(() => mockDio.get('${AppConstants.authApiBaseUrl}/profile/me'));
      expect(result.id, tUserModel.id);
    });

    test('should perform a GET request for getPublicProfile', () async {
      // arrange
      when(() => mockDio.get(any())).thenAnswer((_) async => Response(
            data: tUserJson,
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));
      // act
      final result = await dataSource.getPublicProfile('2');
      // assert
      verify(() => mockDio.get('${AppConstants.authApiBaseUrl}/profile/2'));
      expect(result.id, tUserModel.id);
    });

    test('should perform a GET request for getMyActivities', () async {
      // arrange
      when(() => mockDio.get(any())).thenAnswer((_) async => Response(
            data: [{'activity': 'login'}],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));
      // act
      final result = await dataSource.getMyActivities();
      // assert
      verify(() => mockDio.get('${AppConstants.authApiBaseUrl}/profile/me/activities'));
      expect(result.length, 1);
    });
  });
}
