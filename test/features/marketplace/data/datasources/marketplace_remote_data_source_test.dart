import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'package:project4_chosv/features/marketplace/data/models/listing_model.dart';

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
