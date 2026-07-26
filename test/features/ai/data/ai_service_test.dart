import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/ai/data/ai_service.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient apiClient;
  late MockDio dio;

  setUp(() {
    apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
  });

  test('generateDescription sends the exact AI contract', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {'description': 'Món đồ còn tốt'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final result = await AiService(
      apiClient: apiClient,
    ).generateDescription(name: 'Áo khoác', condition: 'good');

    verify(
      () => dio.post(
        '${AppConstants.aiApiBaseUrl}/generate-description',
        data: {'name': 'Áo khoác', 'condition': 'good'},
      ),
    ).called(1);
    expect(result, 'Món đồ còn tốt');
  });
}
