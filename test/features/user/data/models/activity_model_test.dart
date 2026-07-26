import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/features/user/data/models/activity_model.dart';

void main() {
  test('maps the real activity envelope payload', () {
    final result = ActivityPageModel.fromJson({
      'items': [
        {
          'id': 7,
          'action': 'change_password',
          'ref_type': null,
          'ref_id': null,
          'created_at': '2026-07-25T10:00:00Z',
        },
      ],
      'meta': {'page': 2, 'limit': 20, 'total': 45},
    });

    expect(result.items.single.id, 7);
    expect(result.items.single.action, 'change_password');
    expect(result.items.single.createdAt, DateTime.utc(2026, 7, 25, 10));
    expect(result.page, 2);
    expect(result.limit, 20);
    expect(result.total, 45);
    expect(result.hasMore, isTrue);
  });
}
