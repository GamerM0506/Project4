import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/api_client.dart';
import 'package:project4_chosv/features/donation/data/datasources/campaign_remote_data_source.dart';
import 'package:project4_chosv/features/donation/data/models/campaign_item_input.dart';
import 'package:project4_chosv/features/donation/data/models/contribution_model.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient apiClient;
  late MockDio dio;
  late CampaignRemoteDataSource dataSource;

  setUp(() {
    apiClient = MockApiClient();
    dio = MockDio();
    when(() => apiClient.dio).thenReturn(dio);
    dataSource = CampaignRemoteDataSource(apiClient: apiClient);
  });

  test('loads active campaigns from the current backend envelope', () async {
    when(
      () => dio.get(
        '${AppConstants.donationApiBaseUrl}/campaigns',
        queryParameters: {'status': 'active', 'limit': 50, 'offset': 0},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/campaigns'),
        data: {
          'data': {
            'items': [
              {
                'id': 'campaign-1',
                'code': 'CP-2026-00001',
                'group_id': 'group-1',
                'title': 'Áo ấm vùng cao',
                'status': 'active',
                'created_at': '2026-07-31T00:00:00Z',
                'items': [
                  {
                    'id': 'item-1',
                    'name': 'Áo khoác',
                    'target_quantity': 10,
                    'received_quantity': 4,
                    'unit': 'cái',
                  },
                ],
              },
            ],
            'meta': {'total': 1, 'limit': 50, 'offset': 0},
          },
        },
      ),
    );

    final result = await dataSource.getCampaigns();

    expect(result.single.code, 'CP-2026-00001');
    expect(result.single.items.single.remaining, 6);
  });

  test('creates a contribution with campaign item contract', () async {
    when(
      () => dio.post(
        '${AppConstants.donationApiBaseUrl}/contributions',
        data: {
          'campaign_id': 'campaign-1',
          'pickup_method': 'drop_off',
          'items': [
            {
              'campaign_item_id': 'item-1',
              'name': 'Áo khoác nam',
              'quantity': 2,
              'condition_declared': 'good',
              'images': <Map<String, dynamic>>[],
            },
          ],
        },
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/contributions'),
        data: {
          'data': {
            'id': 'contribution-1',
            'code': 'CTR-2026-00001',
            'campaign_id': 'campaign-1',
            'donor_id': 'user-1',
            'status': 'pending',
            'pickup_method': 'drop_off',
            'created_at': '2026-07-31T00:00:00Z',
            'items': [],
          },
        },
      ),
    );

    final result = await dataSource.createContribution(
      campaignId: 'campaign-1',
      items: const [
        ContributionItemInput(
          campaignItemId: 'item-1',
          name: 'Áo khoác nam',
          quantity: 2,
          conditionDeclared: 'good',
        ),
      ],
      pickupMethod: 'drop_off',
    );

    expect(result.id, 'contribution-1');

    verify(
      () => dio.post(
        '${AppConstants.donationApiBaseUrl}/contributions',
        data: {
          'campaign_id': 'campaign-1',
          'pickup_method': 'drop_off',
          'items': [
            {
              'campaign_item_id': 'item-1',
              'name': 'Áo khoác nam',
              'quantity': 2,
              'condition_declared': 'good',
              'images': <Map<String, dynamic>>[],
            },
          ],
        },
      ),
    ).called(1);
  });

  test(
    'loads current user contributions from the protected endpoint',
    () async {
      when(
        () => dio.get(
          '${AppConstants.donationApiBaseUrl}/contributions',
          queryParameters: {'mine': true, 'limit': 100, 'offset': 0},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/contributions'),
          data: {
            'data': {
              'items': [
                {
                  'id': 'contribution-1',
                  'code': 'CTR-2026-00001',
                  'campaign_id': 'campaign-1',
                  'donor_id': 'user-1',
                  'status': 'pending',
                  'pickup_method': 'drop_off',
                  'created_at': '2026-07-31T00:00:00Z',
                  'items': [],
                },
              ],
              'meta': {'total': 1, 'limit': 100, 'offset': 0},
            },
          },
        ),
      );

      final result = await dataSource.getContributions(mine: true);

      expect(result.single.code, 'CTR-2026-00001');
      expect(result.single.status, 'pending');
    },
  );

  test('loads seeded categories sorted by sort_order', () async {
    when(
      () => dio.get('${AppConstants.donationApiBaseUrl}/categories'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/categories'),
        data: {
          'data': [
            {'id': 'cat-2', 'name': 'Giày dép', 'slug': 'giay-dep', 'sort_order': 2},
            {'id': 'cat-1', 'name': 'Quần áo', 'slug': 'quan-ao', 'sort_order': 1},
          ],
        },
      ),
    );

    final result = await dataSource.getCategories();

    expect(result.map((c) => c.id).toList(), ['cat-1', 'cat-2']);
    expect(result.first.name, 'Quần áo');
  });

  test('sends category_id and deadline when creating a campaign', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/campaigns'),
        data: {'data': _campaignJson()},
      ),
    );

    await dataSource.createCampaign(
      groupId: 'group-1',
      title: 'Áo ấm vùng cao',
      deadline: DateTime(2026, 9, 5),
      items: const [
        CampaignItemInput(
          name: 'Áo khoác',
          targetQuantity: 10,
          unit: 'cái',
          categoryId: 'cat-1',
        ),
      ],
    );

    verify(
      () => dio.post('${AppConstants.donationApiBaseUrl}/campaigns', data: {
        'group_id': 'group-1',
        'title': 'Áo ấm vùng cao',
        'deadline': '2026-09-05',
        'items': [
          {
            'name': 'Áo khoác',
            'target_quantity': 10,
            'unit': 'cái',
            'category_id': 'cat-1',
          },
        ],
      }),
    ).called(1);
  });

  test('sends every item when a campaign needs several things', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/campaigns'),
        data: {'data': _campaignJson()},
      ),
    );

    await dataSource.createCampaign(
      groupId: 'group-1',
      title: 'Tiếp sức mùa đông',
      items: const [
        CampaignItemInput(
          name: 'Áo khoác',
          targetQuantity: 20,
          unit: 'cái',
          conditionRequired: 'good',
        ),
        CampaignItemInput(
          name: 'Chăn bông',
          targetQuantity: 10,
          unit: 'chiếc',
          note: 'Ưu tiên chăn dày',
        ),
        CampaignItemInput(name: 'Sách vở', targetQuantity: 100),
      ],
    );

    final captured = verify(
      () => dio.post(
        '${AppConstants.donationApiBaseUrl}/campaigns',
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;

    final items = captured['items'] as List;
    expect(items, hasLength(3));
    expect(items[0]['condition_required'], 'good');
    expect(items[1]['note'], 'Ưu tiên chăn dày');
    // Trường không nhập thì bỏ hẳn khỏi payload thay vì gửi null.
    expect((items[2] as Map).containsKey('unit'), isFalse);
    expect((items[2] as Map).containsKey('category_id'), isFalse);
  });

  test('rejects a campaign with no items before calling the API', () async {
    expect(
      () => dataSource.createCampaign(
        groupId: 'group-1',
        title: 'Thiếu vật phẩm',
        items: const [],
      ),
      throwsArgumentError,
    );
    verifyNever(() => dio.post(any(), data: any(named: 'data')));
  });

  test('updates campaign metadata through the put contract', () async {
    when(() => dio.put(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/campaigns/campaign-1'),
        data: {'data': _campaignJson(title: 'Tên mới')},
      ),
    );

    final result = await dataSource.updateCampaign(
      'campaign-1',
      title: 'Tên mới',
      description: 'Mô tả mới',
      deadline: DateTime(2026, 12, 31),
    );

    verify(
      () => dio.put(
        '${AppConstants.donationApiBaseUrl}/campaigns/campaign-1',
        data: {
          'title': 'Tên mới',
          'description': 'Mô tả mới',
          'deadline': '2026-12-31',
        },
      ),
    ).called(1);
    expect(result.title, 'Tên mới');
  });

  test('sends a null deadline when the moderator clears it', () async {
    when(() => dio.put(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/campaigns/campaign-1'),
        data: {'data': _campaignJson()},
      ),
    );

    await dataSource.updateCampaign(
      'campaign-1',
      title: 'Áo ấm vùng cao',
      deadline: DateTime(2026, 12, 31),
      clearDeadline: true,
    );

    verify(
      () => dio.put(
        '${AppConstants.donationApiBaseUrl}/campaigns/campaign-1',
        data: {'title': 'Áo ấm vùng cao', 'deadline': null},
      ),
    ).called(1);
  });
  test('reads nested items straight from the list response', () async {
    when(
      () => dio.get(
        '${AppConstants.donationApiBaseUrl}/campaigns',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/campaigns'),
        data: {
          'data': {
            'items': [_campaignJson()],
            'meta': {'total': 1, 'limit': 50, 'offset': 0},
          },
        },
      ),
    );

    final result = await dataSource.getCampaigns();

    expect(result.single.items, hasLength(1));
    expect(result.single.items.single.name, 'Áo khoác');
    // Chan N+1 tai xuat hien: khong duoc goi chi tiet cho tung dot.
    verifyNever(
      () => dio.get('${AppConstants.donationApiBaseUrl}/campaigns/campaign-1'),
    );
  });

  test('gui don dong gop nhieu vat pham kem anh rieng tung mon', () async {
    const expectedBody = {
      'campaign_id': 'campaign-1',
      'pickup_method': 'pickup',
      'pickup_address': '123 Lê Lợi',
      'items': [
        {
          'campaign_item_id': 'item-1',
          'name': 'Áo khoác nam',
          'quantity': 5,
          'condition_declared': 'good',
          'images': [
            {'image_url': 'https://cdn/a.jpg', 'type': 'declared'},
          ],
        },
        {
          'campaign_item_id': 'item-2',
          'name': 'Bao gạo 5kg',
          'quantity': 10,
          'condition_declared': 'new',
          'images': <Map<String, dynamic>>[],
        },
      ],
    };
    when(
      () => dio.post(
        '${AppConstants.donationApiBaseUrl}/contributions',
        data: expectedBody,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/contributions'),
        data: {
          'data': {
            'id': 'contribution-9',
            'code': 'CTR-2026-00023',
            'campaign_id': 'campaign-1',
            'donor_id': 'user-1',
            'status': 'pending',
            'pickup_method': 'pickup',
            'created_at': '2026-08-02T00:00:00Z',
            'items': [],
          },
        },
      ),
    );

    final result = await dataSource.createContribution(
      campaignId: 'campaign-1',
      pickupMethod: 'pickup',
      pickupAddress: '  123 Lê Lợi  ',
      items: const [
        ContributionItemInput(
          campaignItemId: 'item-1',
          name: 'Áo khoác nam',
          quantity: 5,
          conditionDeclared: 'good',
          imageUrls: ['https://cdn/a.jpg'],
        ),
        ContributionItemInput(
          campaignItemId: 'item-2',
          name: 'Bao gạo 5kg',
          quantity: 10,
          conditionDeclared: 'new',
        ),
      ],
    );

    expect(result.code, 'CTR-2026-00023');
    verify(
      () => dio.post(
        '${AppConstants.donationApiBaseUrl}/contributions',
        data: expectedBody,
      ),
    ).called(1);
  });

  test('tu choi gui don khi khong co vat pham nao', () async {
    expect(
      () => dataSource.createContribution(
        campaignId: 'campaign-1',
        items: const [],
        pickupMethod: 'drop_off',
      ),
      throwsArgumentError,
    );
    verifyNever(() => dio.post(any(), data: any(named: 'data')));
  });

  test('kiem tra vat pham gui kem anh actual_check', () async {
    const url =
        '${AppConstants.donationApiBaseUrl}/contributions/ctr-1/items/it-1/check';
    when(() => dio.put(url, data: any(named: 'data'))).thenAnswer(
      (_) async =>
          Response(requestOptions: RequestOptions(path: url), data: {'data': {}}),
    );

    await dataSource.checkContributionItem(
      contributionId: 'ctr-1',
      itemId: 'it-1',
      action: 'accepted',
      conditionActual: 'good',
      note: 'Đồ còn mới',
      imageUrls: const ['https://cdn/check.jpg'],
    );

    verify(
      () => dio.put(
        url,
        data: {
          'action': 'accepted',
          'condition_actual': 'good',
          'check_note': 'Đồ còn mới',
          'images': [
            {'image_url': 'https://cdn/check.jpg', 'type': 'actual_check'},
          ],
        },
      ),
    ).called(1);
  });

  test('trao tang gui kem anh va ghi chu', () async {
    const url =
        '${AppConstants.donationApiBaseUrl}/campaigns/campaign-1/deliver';
    when(() => dio.post(url, data: any(named: 'data'))).thenAnswer(
      (_) async =>
          Response(requestOptions: RequestOptions(path: url), data: {'data': {}}),
    );

    await dataSource.deliverCampaign(
      'campaign-1',
      note: 'Đã trao cho bà con vùng lũ',
      deliveryPhotoUrl: 'https://cdn/delivery.jpg',
    );

    verify(
      () => dio.post(
        url,
        data: {
          'delivery_photo_url': 'https://cdn/delivery.jpg',
          'delivery_note': 'Đã trao cho bà con vùng lũ',
        },
      ),
    ).called(1);
  });

  test('doc tien do dot quyen gop tu endpoint progress', () async {
    when(
      () => dio.get(
        '${AppConstants.donationApiBaseUrl}/campaigns/campaign-1/progress',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/progress'),
        data: {
          'data': {
            'campaign_id': 'campaign-1',
            'code': 'CP-2026-00021',
            'title': 'Đợt quyên góp vùng lũ',
            'status': 'active',
            'total_targets': 2,
            'fulfilled_targets': 0,
            'items': [
              {
                'id': 'item-1',
                'name': 'Áo khoác',
                'target_quantity': 15,
                'received_quantity': 5,
                'remaining': 10,
                'unit': 'chiếc',
                'fulfilled': false,
              },
            ],
          },
        },
      ),
    );

    final progress = await dataSource.getCampaignProgress('campaign-1');

    expect(progress.code, 'CP-2026-00021');
    expect(progress.items.single.remaining, 10);
    expect(progress.items.single.fulfilled, isFalse);
  });

  test('loc dong gop theo donor_id cho phia hoi nhom', () async {
    when(
      () => dio.get(
        '${AppConstants.donationApiBaseUrl}/contributions',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/contributions'),
        data: {
          'data': {'items': [], 'meta': {}},
        },
      ),
    );

    await dataSource.getContributions(donorId: 'donor-9', status: 'pending');

    verify(
      () => dio.get(
        '${AppConstants.donationApiBaseUrl}/contributions',
        queryParameters: {
          'donor_id': 'donor-9',
          'status': 'pending',
          'limit': 100,
          'offset': 0,
        },
      ),
    ).called(1);
  });
}

Map<String, dynamic> _campaignJson({String title = 'Áo ấm vùng cao'}) => {
  'id': 'campaign-1',
  'code': 'CP-2026-00001',
  'group_id': 'group-1',
  'title': title,
  'status': 'active',
  'created_at': '2026-07-31T00:00:00Z',
  'items': [
    {
      'id': 'item-1',
      'name': 'Áo khoác',
      'target_quantity': 10,
      'received_quantity': 0,
      'unit': 'cái',
      'category_id': 'cat-1',
    },
  ],
};
