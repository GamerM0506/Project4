import '../../../../injection_container.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';
import '../../../group/domain/usecases/get_group_detail_usecase.dart';
import '../../../user/domain/repositories/user_repository.dart';

class ListingAttribution {
  final String donorName;
  final String groupName;
  final String? donorAvatar;

  const ListingAttribution({
    required this.donorName,
    required this.groupName,
    this.donorAvatar,
  });
}

class ListingAttributionResolver {
  static final Map<String, Future<({String name, String? avatar})>>
  _donorCache = {};
  static final Map<String, Future<String>> _groupCache = {};

  static Future<ListingAttribution> resolve({
    required String inventoryItemId,
    required String createdBy,
    required String groupId,
  }) async {
    final donor = await _donorCache.putIfAbsent(inventoryItemId, () async {
      var donorId = createdBy;
      final inventory = await sl<GetInventoryItemUseCase>()(inventoryItemId);
      inventory.fold((_) {}, (item) {
        if (item.donorId?.trim().isNotEmpty ?? false) donorId = item.donorId!;
      });
      final result = await sl<UserRepository>().getPublicProfile(donorId);
      return result.fold(
        (_) => (name: 'Người tặng', avatar: null),
        (user) => (
          name: user.fullName.trim().isEmpty ? 'Người tặng' : user.fullName,
          avatar: user.resolvedAvatarUrl,
        ),
      );
    });
    final groupName = await _groupCache.putIfAbsent(groupId, () async {
      final result = await sl<GetGroupDetailUseCase>()(groupId);
      return result.fold(
        (_) => 'Hội nhóm',
        (group) => group.name.trim().isEmpty ? 'Hội nhóm' : group.name,
      );
    });

    return ListingAttribution(
      donorName: donor.name,
      donorAvatar: donor.avatar,
      groupName: groupName,
    );
  }
}
