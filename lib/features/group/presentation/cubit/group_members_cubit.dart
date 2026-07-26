import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_members_usecase.dart';
import '../../domain/usecases/update_member_role_usecase.dart';
import '../../domain/usecases/update_member_status_usecase.dart';
import 'group_members_state.dart';

class GroupMembersCubit extends Cubit<GroupMembersState> {
  final GetMembersUseCase getMembersUseCase;
  final UpdateMemberRoleUseCase updateMemberRoleUseCase;
  final UpdateMemberStatusUseCase updateMemberStatusUseCase;
  static const _limit = 20;
  String? _status;

  GroupMembersCubit({
    required this.getMembersUseCase,
    required this.updateMemberRoleUseCase,
    required this.updateMemberStatusUseCase,
  }) : super(GroupMembersInitial());

  Future<void> fetchMembers(String groupId, {String? status}) async {
    _status = status;
    emit(GroupMembersLoading());
    final result = await getMembersUseCase(
      groupId,
      status: status,
      limit: _limit,
    );

    result.fold(
      (failure) => emit(GroupMembersError(failure)),
      (members) => emit(
        GroupMembersLoaded(members, hasReachedMax: members.length < _limit),
      ),
    );
  }

  Future<void> loadMore(String groupId) async {
    final current = state;
    if (current is! GroupMembersLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    emit(
      GroupMembersLoaded(
        current.members,
        hasReachedMax: current.hasReachedMax,
        isLoadingMore: true,
      ),
    );
    final result = await getMembersUseCase(
      groupId,
      status: _status,
      limit: _limit,
      offset: current.members.length,
    );
    result.fold(
      (failure) => emit(GroupMembersError(failure)),
      (members) => emit(
        GroupMembersLoaded([
          ...current.members,
          ...members,
        ], hasReachedMax: members.length < _limit),
      ),
    );
  }

  Future<void> updateRole(String groupId, String userId, String role) async {
    final result = await updateMemberRoleUseCase(groupId, userId, role);
    result.fold((error) => emit(GroupMembersError(error)), (_) {
      // Re-fetch members to reflect changes
      fetchMembers(groupId, status: _status);
    });
  }

  Future<void> kickMember(String groupId, String userId) async {
    // Set status to banned or left
    final result = await updateMemberStatusUseCase(groupId, userId, 'banned');
    result.fold((error) => emit(GroupMembersError(error)), (_) {
      fetchMembers(groupId, status: _status);
    });
  }

  Future<void> unbanMember(String groupId, String userId) async {
    final result = await updateMemberStatusUseCase(groupId, userId, 'approved');
    result.fold(
      (error) => emit(GroupMembersError(error)),
      (_) => fetchMembers(groupId, status: _status),
    );
  }
}
