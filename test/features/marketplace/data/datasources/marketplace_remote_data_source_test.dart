import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:project4_chosv/features/marketplace/data/models/listing_model.dart';
import 'package:project4_chosv/features/marketplace/data/models/request_model.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MarketplaceRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    dataSource = MarketplaceRemoteDataSourceImpl(mockApiClient);
  });

  group('createRequest', () {
    test(
      'sends only listing data and lets backend resolve actor and group',
      () async {
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: const {'data': {}},
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        await dataSource.createRequest({
          'listing_id': 'listing-id',
          'quantity': 2,
          'reason': '  Cần dùng cho gia đình  ',
          'group_id': 'must-not-be-sent',
          'receiver_id': 'must-not-be-sent',
        });

        verify(
          () => mockDio.post(
            '${AppConstants.marketplaceApiBaseUrl}/requests',
            data: {
              'listing_id': 'listing-id',
              'quantity': 2,
              'reason': 'Cần dùng cho gia đình',
            },
          ),
        ).called(1);
      },
    );

    test('rejects an invalid quantity before sending a request', () async {
      expect(
        () => dataSource.createRequest({
          'listing_id': 'listing-id',
          'quantity': 0,
        }),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('quantity must be greater than 0'),
          ),
        ),
      );

      verifyNever(() => mockDio.post(any(), data: any(named: 'data')));
    });
  });

  test(
    'catalog sends exact backend filters and maps pagination meta',
    () async {
      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          data: const {
            'data': [],
            'meta': {'page': 2, 'limit': 10, 'total': 25, 'total_pages': 3},
          },
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.getCatalog(
        categoryId: 'category-id',
        provinceCode: '01',
        groupId: 'group-id',
        status: 'active',
        page: 2,
        limit: 10,
        search: '  áo ấm ',
      );

      verify(
        () => mockDio.get(
          '${AppConstants.marketplaceApiBaseUrl}/catalog',
          queryParameters: {
            'category_id': 'category-id',
            'province_code': '01',
            'group_id': 'group-id',
            'status': 'active',
            'page': 2,
            'limit': 10,
            'search': 'áo ấm',
          },
        ),
      ).called(1);
      expect(result.page, 2);
      expect(result.total, 25);
      expect(result.totalPages, 3);
      expect(result.hasMore, isTrue);
    },
  );

  test(
    'request actions rely on JWT actor and send only contract fields',
    () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          data: const {'data': {}},
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await dataSource.approveRequest('request-id');
      await dataSource.rejectRequest('request-id', 'Không đủ điều kiện');
      await dataSource.scheduleRequest(
        'request-id',
        DateTime.utc(2026, 7, 25, 9),
      );
      await dataSource.completeRequest(
        'request-id',
        qrToken: 'qr-token',
        photoUrl: 'https://cdn.example.com/delivery.jpg',
        note: 'Đã giao đủ',
      );
      await dataSource.noShowRequest('request-id');

      verify(
        () => mockDio.put(
          '${AppConstants.marketplaceApiBaseUrl}/requests/request-id/approve',
          data: <String, dynamic>{},
        ),
      ).called(1);
      verify(
        () => mockDio.put(
          '${AppConstants.marketplaceApiBaseUrl}/requests/request-id/reject',
          data: {'reason': 'Không đủ điều kiện'},
        ),
      ).called(1);
      verify(
        () => mockDio.put(
          '${AppConstants.marketplaceApiBaseUrl}/requests/request-id/schedule',
          data: {'scheduled_at': '2026-07-25T09:00:00.000Z'},
        ),
      ).called(1);
      verify(
        () => mockDio.put(
          '${AppConstants.marketplaceApiBaseUrl}/requests/request-id/complete',
          data: {
            'qr_token': 'qr-token',
            'photo_url': 'https://cdn.example.com/delivery.jpg',
            'note': 'Đã giao đủ',
          },
        ),
      ).called(1);
      verify(
        () => mockDio.put(
          '${AppConstants.marketplaceApiBaseUrl}/requests/request-id/no-show',
          data: <String, dynamic>{},
        ),
      ).called(1);
    },
  );

  test('request model maps all fields returned by GET requests', () {
    final request = RequestModel.fromJson(const {
      'id': 'request-id',
      'code': 'REQ-2026-1234',
      'listing_id': 'listing-id',
      'group_id': 'group-id',
      'receiver_id': 'receiver-id',
      'quantity': 2,
      'reason': 'Cần dùng',
      'status': 'no_show',
      'reviewed_by': 'moderator-id',
      'reviewed_at': '2026-07-25T08:00:00Z',
      'reject_reason': 'reason',
      'scheduled_at': '2026-07-26T08:00:00Z',
      'completed_at': '2026-07-27T08:00:00Z',
      'created_at': '2026-07-24T08:00:00Z',
      'updated_at': '2026-07-27T08:00:00Z',
    });

    expect(request.code, 'REQ-2026-1234');
    expect(request.status, 'no_show');
    expect(request.reviewedAt, DateTime.utc(2026, 7, 25, 8));
    expect(request.rejectReason, 'reason');
    expect(request.scheduledAt, DateTime.utc(2026, 7, 26, 8));
    expect(request.completedAt, DateTime.utc(2026, 7, 27, 8));
    expect(request.updatedAt, DateTime.utc(2026, 7, 27, 8));
  });

  test('listing model reads the first image returned by marketplace', () {
    final listing = ListingModel.fromJson({
      'id': 'listing-id',
      'inventory_item_id': 'inventory-id',
      'group_id': 'group-id',
      'title': 'Áo khoác',
      'description': '',
      'category_id': 'category-id',
      'condition': 'good',
      'quantity_total': 1,
      'quantity_available': 1,
      'status': 'active',
      'created_by': 'user-id',
      'created_at': '2026-07-24T00:00:00Z',
      'images': [
        {'image_url': 'https://cdn.example.com/listing.jpg'},
      ],
    });

    expect(listing.imageUrl, 'https://cdn.example.com/listing.jpg');
  });
}
