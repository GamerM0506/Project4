import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/features/home/data/models/group_model.dart';

void main() {
  test('maps a valid group avatar URL', () {
    final group = GroupModel.fromJson({
      'id': 'group-1',
      'name': 'Nhóm sẻ chia',
      'avatar_url': 'https://cdn.example.com/group.jpg',
    });

    expect(group.imageUrl, 'https://cdn.example.com/group.jpg');
  });

  test('ignores missing or malformed group image URLs', () {
    final group = GroupModel.fromJson({
      'id': 'group-1',
      'name': 'Nhóm sẻ chia',
      'avatar_url': 's',
      'cover_url': null,
    });

    expect(group.imageUrl, isNull);
  });
}
