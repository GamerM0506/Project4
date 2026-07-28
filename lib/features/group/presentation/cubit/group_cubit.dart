import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_groups_usecase.dart';
import '../../domain/usecases/get_my_groups_usecase.dart';
import '../../domain/usecases/cancel_join_request_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';
import '../../data/models/group_model.dart';

abstract class GroupState {}

class GroupInitial extends GroupState {}

class GroupLoading extends GroupState {}

class GroupLoaded extends GroupState {
  final List<GroupModel> groups;
  final bool hasReachedMax;
  final bool isLoadingMore;

  /// Id của các nhóm đang gửi yêu cầu tham gia.
  final Set<String> joiningIds;

  GroupLoaded(
    this.groups, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.joiningIds = const {},
  });

  GroupLoaded copyWith({
    List<GroupModel>? groups,
    bool? hasReachedMax,
    bool? isLoadingMore,
    Set<String>? joiningIds,
  }) {
    return GroupLoaded(
      groups ?? this.groups,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      joiningIds: joiningIds ?? this.joiningIds,
    );
  }
}

/// Kết quả gửi yêu cầu tham gia nhóm, dùng để hiện thông báo ở UI.
class JoinGroupResult {
  final bool success;
  final String message;

  const JoinGroupResult({required this.success, required this.message});
}

class GroupError extends GroupState {
  final String message;

  GroupError(this.message);
}

class GroupCubit extends Cubit<GroupState> {
  final GetGroupsUseCase getGroupsUseCase;
  final GetMyGroupsUseCase getMyGroupsUseCase;
  final JoinGroupUseCase joinGroupUseCase;
  final CancelJoinRequestUseCase cancelJoinRequestUseCase;
  static const _limit = 20;
  int _generation = 0;
  String? _query;
  String? _provinceCode;
  bool _myGroups = false;
  String? _memberStatus;

  GroupCubit({
    required this.getGroupsUseCase,
    required this.getMyGroupsUseCase,
    required this.joinGroupUseCase,
    required this.cancelJoinRequestUseCase,
  }) : super(GroupInitial());

  Future<void> fetchGroups({String? query, String? provinceCode}) async {
    final generation = ++_generation;
    _query = query;
    _provinceCode = provinceCode;
    _myGroups = false;
    emit(GroupLoading());
    final result = await getGroupsUseCase(
      limit: _limit,
      offset: 0,
      query: query,
      provinceCode: provinceCode,
    );
    if (generation != _generation) return;
    result.fold(
      (error) => emit(GroupError(error)),
      (groups) =>
          emit(GroupLoaded(groups, hasReachedMax: groups.length < _limit)),
    );
  }

  Future<void> fetchMyGroups({String? memberStatus}) async {
    final generation = ++_generation;
    _myGroups = true;
    _memberStatus = memberStatus;
    emit(GroupLoading());
    final result = await getMyGroupsUseCase(
      limit: _limit,
      offset: 0,
      memberStatus: memberStatus,
    );
    if (generation != _generation) return;
    result.fold(
      (error) => emit(GroupError(error)),
      (groups) =>
          emit(GroupLoaded(groups, hasReachedMax: groups.length < _limit)),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true));
    final result = _myGroups
        ? await getMyGroupsUseCase(
            limit: _limit,
            offset: current.groups.length,
            memberStatus: _memberStatus,
          )
        : await getGroupsUseCase(
            limit: _limit,
            offset: current.groups.length,
            query: _query,
            provinceCode: _provinceCode,
          );
    if (generation != _generation) return;
    result.fold(
      (error) => emit(GroupError(error)),
      (groups) => emit(
        current.copyWith(
          groups: [...current.groups, ...groups],
          hasReachedMax: groups.length < _limit,
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Gửi yêu cầu tham gia nhóm và cập nhật thẻ nhóm tương ứng tại chỗ.
  Future<JoinGroupResult> joinGroup(String groupId, {String? message}) async {
    final current = state;
    if (current is! GroupLoaded || current.joiningIds.contains(groupId)) {
      return const JoinGroupResult(
        success: false,
        message: 'Không thể gửi yêu cầu lúc này.',
      );
    }

    emit(current.copyWith(joiningIds: {...current.joiningIds, groupId}));

    final result = await joinGroupUseCase(groupId, message: message);

    final latest = state;
    if (latest is! GroupLoaded) {
      return result.fold(
        (error) => JoinGroupResult(success: false, message: error),
        (_) => const JoinGroupResult(
          success: true,
          message: 'Đã gửi yêu cầu tham gia nhóm.',
        ),
      );
    }

    final remaining = {...latest.joiningIds}..remove(groupId);

    return result.fold(
      (error) {
        emit(latest.copyWith(joiningIds: remaining));
        return JoinGroupResult(success: false, message: error);
      },
      (request) {
        final groups = latest.groups
            .map(
              (group) => group.id == groupId
                  ? group.copyWith(myStatus: request.status)
                  : group,
            )
            .toList();
        emit(latest.copyWith(groups: groups, joiningIds: remaining));
        return JoinGroupResult(
          success: true,
          message: request.status == 'approved'
              ? 'Bạn đã tham gia nhóm.'
              : 'Đã gửi yêu cầu, vui lòng chờ duyệt.',
        );
      },
    );
  }

  /// Huỷ yêu cầu tham gia đang chờ duyệt.
  Future<JoinGroupResult> cancelJoinRequest(String groupId) async {
    final current = state;
    if (current is! GroupLoaded || current.joiningIds.contains(groupId)) {
      return const JoinGroupResult(
        success: false,
        message: 'Không thể huỷ yêu cầu lúc này.',
      );
    }

    emit(current.copyWith(joiningIds: {...current.joiningIds, groupId}));

    final result = await cancelJoinRequestUseCase(groupId);

    final latest = state;
    if (latest is! GroupLoaded) {
      return result.fold(
        (error) => JoinGroupResult(success: false, message: error),
        (_) => const JoinGroupResult(
          success: true,
          message: 'Đã huỷ yêu cầu tham gia.',
        ),
      );
    }

    final remaining = {...latest.joiningIds}..remove(groupId);

    return result.fold(
      (error) {
        emit(latest.copyWith(joiningIds: remaining));
        return JoinGroupResult(success: false, message: error);
      },
      (_) {
        final groups = latest.groups
            .map(
              (group) => group.id == groupId
                  ? group.copyWith(myStatus: null)
                  : group,
            )
            .toList();
        emit(latest.copyWith(groups: groups, joiningIds: remaining));
        return const JoinGroupResult(
          success: true,
          message: 'Đã huỷ yêu cầu tham gia.',
        );
      },
    );
  }
}
