import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/group_model.dart';
import '../../domain/usecases/get_group_detail_usecase.dart';
import '../../domain/usecases/get_my_groups_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';

abstract class GroupDetailState {}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final GroupModel group;
  final bool isJoining;
  final String? flashMessage;
  final bool flashIsError;

  GroupDetailLoaded(
    this.group, {
    this.isJoining = false,
    this.flashMessage,
    this.flashIsError = false,
  });
}

class GroupDetailError extends GroupDetailState {
  final String message;

  GroupDetailError(this.message);
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GetGroupDetailUseCase getGroupDetailUseCase;
  final JoinGroupUseCase joinGroupUseCase;
  final GetMyGroupsUseCase getMyGroupsUseCase;

  GroupDetailCubit({
    required this.getGroupDetailUseCase,
    required this.joinGroupUseCase,
    required this.getMyGroupsUseCase,
  }) : super(GroupDetailInitial());

  Future<void> fetchGroupDetail(String groupId) async {
    emit(GroupDetailLoading());
    final result = await getGroupDetailUseCase(groupId);

    await result.fold(
      (error) async => emit(GroupDetailError(error)),
      (group) async {
        final merged = await _mergeMembership(group);
        emit(GroupDetailLoaded(merged));
      },
    );
  }

  /// Detail API không trả my_role/my_status — lấy từ /groups/me.
  Future<GroupModel> _mergeMembership(GroupModel group) async {
    // approved
    final approved = await getMyGroupsUseCase(memberStatus: 'approved');
    final pending = await getMyGroupsUseCase(memberStatus: 'pending');

    GroupModel? match;
    approved.fold((_) {}, (list) {
      for (final g in list) {
        if (g.id == group.id) match = g;
      }
    });
    if (match == null) {
      pending.fold((_) {}, (list) {
        for (final g in list) {
          if (g.id == group.id) match = g;
        }
      });
    }

    if (match != null) {
      return group.copyWith(
        myRole: match!.myRole,
        myStatus: match!.myStatus,
      );
    }
    return group;
  }

  Future<void> joinGroup(String groupId, {String? message}) async {
    if (state is! GroupDetailLoaded) return;
    final current = state as GroupDetailLoaded;
    final currentGroup = current.group;

    emit(GroupDetailLoaded(currentGroup, isJoining: true));

    final result = await joinGroupUseCase(groupId, message: message);

    result.fold(
      (failure) {
        emit(GroupDetailLoaded(
          currentGroup,
          isJoining: false,
          flashMessage: failure,
          flashIsError: true,
        ));
      },
      (request) {
        final updated = currentGroup.copyWith(
          myStatus: request.status.isNotEmpty ? request.status : 'pending',
          myRole: currentGroup.myRole,
        );
        emit(GroupDetailLoaded(
          updated,
          isJoining: false,
          flashMessage:
              'Đã gửi yêu cầu tham gia. Chờ quản trị viên / moderator duyệt.',
          flashIsError: false,
        ));
      },
    );
  }

  void clearFlash() {
    if (state is GroupDetailLoaded) {
      final s = state as GroupDetailLoaded;
      if (s.flashMessage != null) {
        emit(GroupDetailLoaded(s.group, isJoining: s.isJoining));
      }
    }
  }
}
