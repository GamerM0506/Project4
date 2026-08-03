import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/features/donation/data/donation_eligibility.dart';
import 'package:project4_chosv/features/group/data/datasources/group_remote_data_source.dart';
import 'package:project4_chosv/features/group/data/models/group_model.dart';

class MockGroupRemoteDataSource extends Mock
    implements GroupRemoteDataSource {}

GroupModel group({
  String status = 'active',
  String? myRole,
  String? myStatus,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return GroupModel(
    id: 'group-1',
    name: 'Quỹ Mùa Lũ',
    slug: 'quy-mua-lu',
    ownerId: 'owner-1',
    status: status,
    allowMemberPost: true,
    requirePostReview: false,
    memberCount: 3,
    reputationScore: 0,
    createdAt: now,
    updatedAt: now,
    myRole: myRole,
    myStatus: myStatus,
  );
}

void main() {
  late MockGroupRemoteDataSource ds;

  setUp(() {
    ds = MockGroupRemoteDataSource();
  });

  Future<DonationEligibility> check() =>
      checkDonationEligibility(ds, 'group-1');

  test('thành viên đã duyệt được quyên góp', () async {
    when(() => ds.getGroupDetail(any())).thenAnswer(
      (_) async => group(myRole: 'member', myStatus: 'approved'),
    );

    final result = await check();

    expect(result.access, DonationAccess.allowed);
    expect(result.canDonate, isTrue);
    expect(result.reason, isEmpty);
  });

  test('chủ nhóm được quyên góp dù my_status trống', () async {
    when(
      () => ds.getGroupDetail(any()),
    ).thenAnswer((_) async => group(myRole: 'owner'));

    final result = await check();

    expect(result.access, DonationAccess.allowed);
  });

  test('đang chờ duyệt thì chưa quyên góp được và không mời join lại', () async {
    when(
      () => ds.getGroupDetail(any()),
    ).thenAnswer((_) async => group(myStatus: 'pending'));

    final result = await check();

    expect(result.access, DonationAccess.pending);
    expect(result.canDonate, isFalse);
    expect(result.canRequestJoin, isFalse, reason: 'đã gửi yêu cầu rồi');
    expect(result.reason, contains('chờ duyệt'));
  });

  test('chưa tham gia thì được mời gửi yêu cầu', () async {
    when(() => ds.getGroupDetail(any())).thenAnswer((_) async => group());

    final result = await check();

    expect(result.access, DonationAccess.notMember);
    expect(result.canRequestJoin, isTrue);
    expect(result.reason, contains('Quỹ Mùa Lũ'));
  });

  test('bị cấm thì không mời gửi yêu cầu', () async {
    when(
      () => ds.getGroupDetail(any()),
    ).thenAnswer((_) async => group(myStatus: 'banned'));

    final result = await check();

    expect(result.access, DonationAccess.banned);
    expect(result.canRequestJoin, isFalse);
  });

  test('nhóm không hoạt động thì chặn kể cả thành viên', () async {
    when(() => ds.getGroupDetail(any())).thenAnswer(
      (_) async => group(status: 'suspended', myStatus: 'approved'),
    );

    final result = await check();

    expect(result.access, DonationAccess.groupInactive);
    expect(result.canDonate, isFalse);
  });

  test('lỗi mạng trả unknown kèm thông điệp', () async {
    when(
      () => ds.getGroupDetail(any()),
    ).thenThrow(Exception('Không kết nối được máy chủ'));

    final result = await check();

    expect(result.access, DonationAccess.unknown);
    expect(result.canDonate, isFalse);
    expect(result.errorMessage, contains('Không kết nối'));
    expect(result.reason, contains('Không kết nối'));
  });

  test('groupId rỗng không gọi API', () async {
    final result = await checkDonationEligibility(ds, '   ');

    expect(result.access, DonationAccess.unknown);
    verifyNever(() => ds.getGroupDetail(any()));
  });
}
