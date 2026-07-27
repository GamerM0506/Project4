import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/donation/data/datasources/donation_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late DonationRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    dataSource = DonationRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  test('loads donation categories from the data envelope', () async {
    when(() => mockDio.get(any())).thenAnswer(
      (_) async => Response(
        data: {
          'data': [
            {
              'id': '11111111-1111-1111-1111-111111111111',
              'name': 'Quần áo',
              'slug': 'clothing',
              'icon_url': null,
            },
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final categories = await dataSource.getCategories();

    verify(
      () => mockDio.get('${AppConstants.donationApiBaseUrl}/categories'),
    ).called(1);
    expect(categories, hasLength(1));
    expect(categories.single.slug, 'clothing');
  });

  test('creates a donation with category and declared image', () async {
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'id': 'donation-id',
            'code': 'DON-2026-0001',
            'donor_id': 'donor-id',
            'group_id': 'group-id',
            'title': 'Áo khoác',
            'status': 'pending',
            'items': [
              {
                'id': 'item-id',
                'donation_id': 'donation-id',
                'name': 'Áo khoác',
                'category_id': '11111111-1111-1111-1111-111111111111',
                'quantity': 1,
                'condition_declared': 'good',
                'status': 'pending',
                'images': [
                  {
                    'id': 'image-id',
                    'donation_item_id': 'item-id',
                    'image_url': 'https://cdn.example.com/donation.jpg',
                    'type': 'declared',
                  },
                ],
              },
            ],
          },
        },
        statusCode: 201,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final donation = await dataSource.createDonation(
      groupId: 'group-id',
      title: 'Áo khoác',
      description: 'Còn tốt',
      items: [
        {
          'name': 'Áo khoác',
          'category_id': '11111111-1111-1111-1111-111111111111',
          'quantity': 1,
          'condition_declared': 'good',
          'images': [
            {
              'image_url': 'https://cdn.example.com/donation.jpg',
              'type': 'declared',
            },
          ],
        },
      ],
    );

    verify(
      () => mockDio.post(
        '${AppConstants.donationApiBaseUrl}/donations',
        data: {
          'group_id': 'group-id',
          'title': 'Áo khoác',
          'description': 'Còn tốt',
          'pickup_method': 'drop_off',
          'items': [
            {
              'name': 'Áo khoác',
              'category_id': '11111111-1111-1111-1111-111111111111',
              'quantity': 1,
              'condition_declared': 'good',
              'images': [
                {
                  'image_url': 'https://cdn.example.com/donation.jpg',
                  'type': 'declared',
                },
              ],
            },
          ],
        },
      ),
    ).called(1);
    expect(
      donation.items.single.images.single.imageUrl,
      'https://cdn.example.com/donation.jpg',
    );
  });

  test('lists donations for a group', () async {
    when(
      () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'items': [
              {
                'id': 'donation-id',
                'code': 'DON-2026-0001',
                'donor_id': 'donor-id',
                'group_id': 'group-id',
                'title': 'Áo khoác',
                'status': 'pending',
                'items': [],
              },
            ],
            'meta': {'total': 1, 'limit': 50, 'offset': 0},
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final donations = await dataSource.getDonations(groupId: 'group-id');

    verify(
      () => mockDio.get(
        '${AppConstants.donationApiBaseUrl}/donations',
        queryParameters: {'limit': 50, 'offset': 0, 'group_id': 'group-id'},
      ),
    ).called(1);
    expect(donations.single.status, 'pending');
  });

  test('gets an exact donation by code within a group', () async {
    when(
      () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'id': 'donation-id',
            'code': 'DON-2026-00001',
            'donor_id': 'donor-id',
            'group_id': 'group-id',
            'title': 'Áo khoác',
            'status': 'scheduled',
            'items': [],
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    final donation = await dataSource.getDonationByCode(
      ' don-2026-00001 ',
      'group-id',
    );

    verify(
      () => mockDio.get(
        '${AppConstants.donationApiBaseUrl}/donations/by-code/don-2026-00001',
        queryParameters: {'group_id': 'group-id'},
      ),
    ).called(1);
    expect(donation.code, 'DON-2026-00001');
    expect(donation.status, 'scheduled');
  });

  test('reviews a donation with the backend action contract', () async {
    when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'id': 'donation-id',
            'code': 'DON-2026-0001',
            'donor_id': 'donor-id',
            'group_id': 'group-id',
            'title': 'Áo khoác',
            'status': 'accepted',
            'items': [],
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.reviewDonation('donation-id', 'accepted');

    verify(
      () => mockDio.put(
        '${AppConstants.donationApiBaseUrl}/donations/donation-id/review',
        data: {'action': 'accepted'},
      ),
    ).called(1);
  });

  test('checks an accepted item with its actual condition', () async {
    when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        data: {
          'data': {
            'id': 'donation-id',
            'code': 'DON-2026-0001',
            'donor_id': 'donor-id',
            'group_id': 'group-id',
            'title': 'Áo khoác',
            'status': 'completed',
            'items': [],
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    await dataSource.checkItem(
      donationId: 'donation-id',
      itemId: 'item-id',
      action: 'accepted',
      conditionActual: 'good',
      checkNote: 'Đã kiểm tra trực tiếp',
    );

    verify(
      () => mockDio.put(
        '${AppConstants.donationApiBaseUrl}/donations/donation-id/items/item-id/check',
        data: {
          'action': 'accepted',
          'condition_actual': 'good',
          'check_note': 'Đã kiểm tra trực tiếp',
        },
      ),
    ).called(1);
  });
}
