import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/core/network/api_error_parser.dart';

void main() {
  DioException exceptionWith(dynamic data) => DioException(
    requestOptions: RequestOptions(path: '/auth/login'),
    response: Response(
      requestOptions: RequestOptions(path: '/auth/login'),
      statusCode: 422,
      data: data,
    ),
  );

  test('parses backend error string', () {
    expect(
      parseApiError(exceptionWith({'error': 'Account is locked'}), 'fallback'),
      'Account is locked',
    );
  });

  test('parses backend error message and details', () {
    expect(
      parseApiError(
        exceptionWith({
          'error': {
            'message': 'Validation failed',
            'details': [
              {'msg': 'Password is too short'},
            ],
          },
        }),
        'fallback',
      ),
      'Validation failed: Password is too short',
    );
  });

  test('uses legacy detail only as fallback', () {
    expect(
      parseApiError(exceptionWith({'detail': 'Invalid OTP'}), 'fallback'),
      'Invalid OTP',
    );
  });
}
