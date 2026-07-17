import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_groups_usecase.dart';
import '../../domain/usecases/get_my_groups_usecase.dart';
import '../../data/models/group_model.dart';

abstract class GroupState {}

class GroupInitial extends GroupState {}

class GroupLoading extends GroupState {}

class GroupLoaded extends GroupState {
  final List<GroupModel> groups;
  final bool hasReachedMax;

  GroupLoaded(this.groups, {this.hasReachedMax = false});
}

class GroupError extends GroupState {
  final String message;

  GroupError(this.message);
}

class GroupCubit extends Cubit<GroupState> {
  final GetGroupsUseCase getGroupsUseCase;
  final GetMyGroupsUseCase getMyGroupsUseCase;

  GroupCubit({
    required this.getGroupsUseCase,
    required this.getMyGroupsUseCase,
  }) : super(GroupInitial());

  Future<void> fetchGroups({String? query, String? provinceCode}) async {
    emit(GroupLoading());
    final result = await getGroupsUseCase(limit: 20, offset: 0, query: query, provinceCode: provinceCode);
    
    result.fold(
      (error) => emit(GroupError(error)),
      (groups) => emit(GroupLoaded(groups, hasReachedMax: groups.length < 20)),
    );
  }

  Future<void> fetchMyGroups({String? memberStatus}) async {
    emit(GroupLoading());
    final result = await getMyGroupsUseCase(limit: 20, offset: 0, memberStatus: memberStatus);
    
    result.fold(
      (error) => emit(GroupError(error)),
      (groups) => emit(GroupLoaded(groups, hasReachedMax: groups.length < 20)),
    );
  }
}
