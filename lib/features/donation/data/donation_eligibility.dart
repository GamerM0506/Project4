import '../../group/data/datasources/group_remote_data_source.dart';
import '../../group/data/models/group_model.dart';

/// Người dùng có được quyên góp vào đợt của một hội nhóm hay không.
///
/// Backend yêu cầu là thành viên đã được duyệt (`my_status == 'approved'`) hoặc
/// chủ nhóm. Kiểm tra sớm ở tầng UI để không bắt người dùng điền hết form rồi
/// mới nhận 403.
enum DonationAccess {
  /// Đã là thành viên được duyệt (hoặc chủ nhóm) — quyên góp được.
  allowed,

  /// Đã gửi yêu cầu tham gia, đang chờ hội nhóm duyệt.
  pending,

  /// Chưa tham gia nhóm.
  notMember,

  /// Từng bị hội nhóm cấm.
  banned,

  /// Nhóm không còn hoạt động.
  groupInactive,

  /// Không xác minh được (mất mạng, lỗi máy chủ).
  unknown,
}

class DonationEligibility {
  const DonationEligibility({
    required this.access,
    this.group,
    this.errorMessage,
  });

  final DonationAccess access;
  final GroupModel? group;
  final String? errorMessage;

  bool get canDonate => access == DonationAccess.allowed;

  /// Chỉ khi chưa tham gia thì mới đề nghị gửi yêu cầu vào nhóm.
  bool get canRequestJoin => access == DonationAccess.notMember;

  String get groupName => group?.name ?? 'hội nhóm này';

  /// Thông điệp ngắn hiển thị cạnh nút hành động.
  String get reason {
    switch (access) {
      case DonationAccess.allowed:
        return '';
      case DonationAccess.pending:
        return 'Yêu cầu tham gia "$groupName" đang chờ duyệt. '
            'Bạn có thể quyên góp sau khi được chấp nhận.';
      case DonationAccess.notMember:
        return 'Bạn cần tham gia "$groupName" trước khi quyên góp cho đợt này.';
      case DonationAccess.banned:
        return 'Bạn không thể quyên góp cho "$groupName" vì đã bị hạn chế.';
      case DonationAccess.groupInactive:
        return '"$groupName" hiện không hoạt động nên chưa tiếp nhận quyên góp.';
      case DonationAccess.unknown:
        return errorMessage ?? 'Chưa kiểm tra được quyền quyên góp.';
    }
  }
}

/// Đọc trạng thái thành viên của người dùng hiện tại với nhóm [groupId].
///
/// `GET /community/groups/{id}` trả kèm `my_role`/`my_status` cho chính người
/// gọi, nên chỉ cần một request.
Future<DonationEligibility> checkDonationEligibility(
  GroupRemoteDataSource dataSource,
  String groupId,
) async {
  if (groupId.trim().isEmpty) {
    return const DonationEligibility(
      access: DonationAccess.unknown,
      errorMessage: 'Không xác định được hội nhóm của đợt quyên góp.',
    );
  }

  try {
    final group = await dataSource.getGroupDetail(groupId.trim());
    return DonationEligibility(
      access: _resolve(group),
      group: group,
    );
  } catch (error) {
    return DonationEligibility(
      access: DonationAccess.unknown,
      errorMessage: error.toString().replaceAll('Exception: ', ''),
    );
  }
}

DonationAccess _resolve(GroupModel group) {
  // Chủ nhóm luôn được coi là thành viên, kể cả khi my_status chưa được điền.
  if (group.myRole == 'owner' || group.myStatus == 'approved') {
    return group.status == 'active'
        ? DonationAccess.allowed
        : DonationAccess.groupInactive;
  }
  if (group.status != 'active') return DonationAccess.groupInactive;

  switch (group.myStatus) {
    case 'pending':
      return DonationAccess.pending;
    case 'banned':
      return DonationAccess.banned;
    default:
      return DonationAccess.notMember;
  }
}
