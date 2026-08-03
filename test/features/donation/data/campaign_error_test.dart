import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/features/donation/data/campaign_error.dart';

DioException _dioError({
  int? statusCode,
  dynamic data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: '/campaigns');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  test('explains the moderator requirement in Vietnamese', () {
    final message = campaignErrorMessage(
      _dioError(
        statusCode: 403,
        data: {'error': 'Moderator or owner of the group required'},
      ),
    );

    expect(message, contains('quản trị viên hoặc chủ nhóm'));
    expect(message, isNot(contains('Moderator')));
  });

  test('explains an inactive group', () {
    final message = campaignErrorMessage(
      _dioError(
        statusCode: 400,
        data: {'error': 'Group is not active (status=pending)'},
      ),
    );

    expect(message, contains('chưa được kích hoạt'));
  });

  test('explains community-service downtime', () {
    final message = campaignErrorMessage(
      _dioError(
        statusCode: 503,
        data: {'error': 'Community service unavailable'},
      ),
    );

    expect(message, contains('đang bận'));
  });

  test('surfaces FastAPI validation details on 422', () {
    final message = campaignErrorMessage(
      _dioError(
        statusCode: 422,
        data: {
          'error': {
            'message': 'Validation error',
            'details': [
              {'msg': 'String should have at most 20 characters'},
            ],
          },
        },
      ),
    );

    expect(message, startsWith('Dữ liệu chưa hợp lệ:'));
    expect(message, contains('20 characters'));
  });

  test('maps a hung request to a timeout message', () {
    final message = campaignErrorMessage(
      _dioError(type: DioExceptionType.receiveTimeout),
    );

    expect(message, contains('quá lâu'));
  });

  test('falls back for non-Dio errors', () {
    final message = campaignErrorMessage(
      StateError('boom'),
      fallback: 'Không tạo được đợt quyên góp.',
    );

    expect(message, 'Không tạo được đợt quyên góp.');
  });
}
