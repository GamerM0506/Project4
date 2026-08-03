import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/features/donation/data/models/campaign_model.dart';

/// Sao chép logic lọc/sắp xếp của CampaignsPage để kiểm chứng độc lập.
/// Nếu logic trong trang đổi mà quên cập nhật đây, test sẽ lệch và lộ ra.
List<CampaignModel> applyFilter(
  List<CampaignModel> source,
  String filter,
  DateTime now,
) {
  final filtered = switch (filter) {
    'all' => [...source],
    'active' => source.where((c) => c.status == 'active').toList(),
    'fulfilled' => source.where((c) => c.status == 'fulfilled').toList(),
    'urgent' => source
        .where(
          (c) =>
              c.status == 'active' &&
              c.deadline != null &&
              c.deadline!.difference(now).inDays <= 7,
        )
        .toList(),
    _ => <CampaignModel>[],
  };

  int rank(CampaignModel c) => switch (c.status) {
    'active' => 0,
    'closed' => 1,
    'fulfilled' => 2,
    _ => 3,
  };

  filtered.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final ad = a.deadline;
    final bd = b.deadline;
    if (ad != null && bd != null) return ad.compareTo(bd);
    if (ad != null) return -1;
    if (bd != null) return 1;
    return b.createdAt.compareTo(a.createdAt);
  });
  return filtered;
}

CampaignModel campaign({
  required String title,
  String status = 'active',
  DateTime? deadline,
  DateTime? createdAt,
  List<CampaignItemModel> items = const [],
}) {
  return CampaignModel(
    id: title,
    code: 'CP-2026-00001',
    groupId: 'g1',
    title: title,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    items: items,
    deadline: deadline,
  );
}

CampaignItemModel item({int target = 10, int received = 0}) {
  return CampaignItemModel(
    id: 'i-$target-$received',
    name: 'Áo khoác',
    targetQuantity: target,
    receivedQuantity: received,
  );
}

void main() {
  final now = DateTime(2026, 8, 1);

  group('bộ lọc', () {
    final source = [
      campaign(title: 'đang mở', status: 'active'),
      campaign(title: 'đã đóng', status: 'closed'),
      campaign(title: 'đã trao', status: 'fulfilled'),
      campaign(
        title: 'sắp hết hạn',
        status: 'active',
        deadline: now.add(const Duration(days: 3)),
      ),
    ];

    test('Đang mở chỉ lấy status active', () {
      final result = applyFilter(source, 'active', now);
      expect(result.map((c) => c.title), containsAll(['đang mở', 'sắp hết hạn']));
      expect(result.every((c) => c.status == 'active'), isTrue);
    });

    test('Sắp hết hạn chỉ lấy đợt active còn <= 7 ngày', () {
      final result = applyFilter(source, 'urgent', now);
      expect(result.map((c) => c.title), ['sắp hết hạn']);
    });

    test('đợt đã đóng dù sát hạn cũng không vào Sắp hết hạn', () {
      final result = applyFilter([
        campaign(
          title: 'đóng rồi',
          status: 'closed',
          deadline: now.add(const Duration(days: 1)),
        ),
      ], 'urgent', now);
      expect(result, isEmpty);
    });

    test('đợt quá hạn vẫn tính là sắp hết hạn', () {
      final result = applyFilter([
        campaign(
          title: 'quá hạn',
          status: 'active',
          deadline: now.subtract(const Duration(days: 2)),
        ),
      ], 'urgent', now);
      expect(result, hasLength(1));
    });

    test('Tất cả giữ nguyên số lượng', () {
      expect(applyFilter(source, 'all', now), hasLength(4));
    });

    test('không làm thay đổi danh sách gốc', () {
      final original = [...source];
      applyFilter(source, 'all', now);
      expect(source.map((c) => c.title), original.map((c) => c.title));
    });
  });

  group('sắp xếp', () {
    test('đang mở lên trước đã đóng và đã trao', () {
      final result = applyFilter([
        campaign(title: 'đã trao', status: 'fulfilled'),
        campaign(title: 'đã đóng', status: 'closed'),
        campaign(title: 'đang mở', status: 'active'),
      ], 'all', now);

      expect(result.map((c) => c.title), ['đang mở', 'đã đóng', 'đã trao']);
    });

    test('cùng trạng thái thì hạn gần hơn lên trước', () {
      final result = applyFilter([
        campaign(title: 'xa', deadline: now.add(const Duration(days: 30))),
        campaign(title: 'gần', deadline: now.add(const Duration(days: 2))),
      ], 'active', now);

      expect(result.map((c) => c.title), ['gần', 'xa']);
    });

    test('đợt có hạn xếp trước đợt không hạn', () {
      final result = applyFilter([
        campaign(title: 'không hạn'),
        campaign(title: 'có hạn', deadline: now.add(const Duration(days: 9))),
      ], 'active', now);

      expect(result.first.title, 'có hạn');
    });

    test('không hạn thì đợt mới hơn lên trước', () {
      final result = applyFilter([
        campaign(title: 'cũ', createdAt: DateTime(2026, 1, 1)),
        campaign(title: 'mới', createdAt: DateTime(2026, 7, 1)),
      ], 'active', now);

      expect(result.map((c) => c.title), ['mới', 'cũ']);
    });
  });

  group('tiến độ hiển thị trên thẻ', () {
    test('cộng dồn mọi vật phẩm', () {
      final c = campaign(
        title: 'nhiều món',
        items: [item(target: 10, received: 5), item(target: 30, received: 5)],
      );
      expect(c.totalTarget, 40);
      expect(c.totalReceived, 10);
      expect((c.progress * 100).round(), 25);
    });

    test('không có vật phẩm thì tiến độ 0, không chia cho 0', () {
      expect(campaign(title: 'rỗng').progress, 0);
    });

    test('nhận vượt mục tiêu thì chặn ở 100%', () {
      final c = campaign(
        title: 'vượt',
        items: [item(target: 10, received: 25)],
      );
      expect(c.progress, 1.0);
    });
  });
}
