import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_members_usecase.dart';
import '../../domain/usecases/update_member_role_usecase.dart';
import '../../domain/usecases/update_member_status_usecase.dart';
import 'group_members_state.dart';

class GroupMembersCubit extends Cubit<GroupMembersState> {
  final GetMembersUseCase getMembersUseCase;
  final UpdateMemberRoleUseCase updateMemberRoleUseCase;
  final UpdateMemberStatusUseCase updateMemberStatusUseCase;

  GroupMembersCubit({
    required this.getMembersUseCase,
    required this.updateMemberRoleUseCase,
    required this.updateMemberStatusUseCase,
  }) : super(GroupMembersInitial());

  Future<void> fetchMembers(String groupId, {String? status}) async {
    emit(GroupMembersLoading());
    final result = await getMembersUseCase(groupId, status: status);

    result.fold(
      (failure) => emit(GroupMembersError(failure)),
      (members) => emit(GroupMembersLoaded(members)),
    );
  }

  Future<void> updateRole(String groupId, String userId, String role) async {
    final result = await updateMemberRoleUseCase(groupId, userId, role);
    result.fold((error) => emit(GroupMembersError(error)), (_) {
      // Re-fetch members to reflect changes
      fetchMembers(groupId);
    });
  }

  Future<void> kickMember(String groupId, String userId) async {
    // Set status to banned or left
    final result = await updateMemberStatusUseCase(groupId, userId, 'banned');
    result.fold((error) => emit(GroupMembersError(error)), (_) {
      fetchMembers(groupId);
    });
  }
}
