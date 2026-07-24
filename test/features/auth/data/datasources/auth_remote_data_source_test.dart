import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:project4_chosv/features/auth/data/models/auth_model.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    dataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('AuthRemoteDataSource', () {
    final tAuthModel = AuthModel(
      userId: '1',
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
    );

    final tAuthJson = {
      'user': {
        'id': '1',
        'email': 'test@example.com',
        'full_name': 'Test User',
      },
      'access_token': 'access_token',
      'refresh_token': 'refresh_token',
    };

    test('should perform a POST request for login', () async {
      // arrange
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: tAuthJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      // act
      final result = await dataSource.login(
        'test@example.com',
        null,
        'password',
      );
      // assert
      verify(
        () => mockDio.post(
          '${AppConstants.authApiBaseUrl}/auth/login',
          data: {'email': 'test@example.com', 'password': 'password'},
        ),
      );
      expect(result.accessToken, tAuthModel.accessToken);
    });

    test('should perform a POST request for login2FA', () async {
      // arrange
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: tAuthJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      // act
      final result = await dataSource.login2FA('challenge-token', '123456');
      // assert
      verify(
        () => mockDio.post(
          '${AppConstants.authApiBaseUrl}/auth/login/2fa',
          data: {'challenge_token': 'challenge-token', 'code': '123456'},
        ),
      );
      expect(result.accessToken, tAuthModel.accessToken);
    });

    test('should perform a POST request for logout', () async {
      // arrange
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );
      // act
      await dataSource.logout('refresh-token');
      // assert
      verify(
        () => mockDio.post(
          '${AppConstants.authApiBaseUrl}/auth/logout',
          data: {'refresh_token': 'refresh-token'},
        ),
      );
    });

    test('should parse a two-factor challenge from login', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'two_factor_required': true,
              'challenge_token': 'challenge-token',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.login(
        'test@example.com',
        null,
        'password',
      );

      expect(result.twoFactorRequired, isTrue);
      expect(result.challengeToken, 'challenge-token');
      expect(result.accessToken, isNull);
    });

    test('loads the two-factor status from the backend', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          data: {
            'data': {'enabled': true},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final enabled = await dataSource.getTwoFactorStatus();

      verify(
        () => mockDio.get('${AppConstants.authApiBaseUrl}/auth/2fa/status'),
      ).called(1);
      expect(enabled, isTrue);
    });
  });
}
