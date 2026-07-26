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
  final bool isLoadingMore;

  GroupLoaded(
    this.groups, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });
}

class GroupError extends GroupState {
  final String message;

  GroupError(this.message);
}

class GroupCubit extends Cubit<GroupState> {
  final GetGroupsUseCase getGroupsUseCase;
  final GetMyGroupsUseCase getMyGroupsUseCase;
  static const _limit = 20;
  int _generation = 0;
  String? _query;
  String? _provinceCode;
  bool _myGroups = false;
  String? _memberStatus;

  GroupCubit({required this.getGroupsUseCase, required this.getMyGroupsUseCase})
    : super(GroupInitial());

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
    emit(
      GroupLoaded(
        current.groups,
        hasReachedMax: current.hasReachedMax,
        isLoadingMore: true,
      ),
    );
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
        GroupLoaded([
          ...current.groups,
          ...groups,
        ], hasReachedMax: groups.length < _limit),
      ),
    );
  }
}
