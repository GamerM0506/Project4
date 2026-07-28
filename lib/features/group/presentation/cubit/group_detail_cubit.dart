import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_group_detail_usecase.dart';
import '../../domain/usecases/join_group_usecase.dart';
import '../../data/models/group_model.dart';

abstract class GroupDetailState {}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final GroupModel group;
  final bool isJoining;

  GroupDetailLoaded(this.group, {this.isJoining = false});
}

class GroupDetailError extends GroupDetailState {
  final String message;

  GroupDetailError(this.message);
}

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GetGroupDetailUseCase getGroupDetailUseCase;
  final JoinGroupUseCase joinGroupUseCase;

  GroupDetailCubit({
    required this.getGroupDetailUseCase,
    required this.joinGroupUseCase,
  }) : super(GroupDetailInitial());

  Future<void> fetchGroupDetail(String groupId) async {
    emit(GroupDetailLoading());
    final result = await getGroupDetailUseCase(groupId);
    
    result.fold(
      (error) => emit(GroupDetailError(error)),
      (group) => emit(GroupDetailLoaded(group)),
    );
  }

  Future<void> joinGroup(String groupId, {String? message}) async {
    if (state is GroupDetailLoaded) {
      final currentState = state as GroupDetailLoaded;
      final currentGroup = currentState.group;
      
      emit(GroupDetailLoaded(currentGroup, isJoining: true));
      
      final result = await joinGroupUseCase(groupId, message: message);
      
      result.fold((failure) {
        emit(GroupDetailError(failure));
        emit(GroupDetailLoaded(currentGroup, isJoining: false));
      }, (request) {
        emit(
          GroupDetailLoaded(
            currentGroup.copyWith(myStatus: request.status),
            isJoining: false,
          ),
        );
      });
    }
  }
}
