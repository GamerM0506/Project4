import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_group_usecase.dart';

abstract class CreateGroupState {}

class CreateGroupInitial extends CreateGroupState {}

class CreateGroupLoading extends CreateGroupState {}

class CreateGroupSuccess extends CreateGroupState {
  final String message;

  CreateGroupSuccess(this.message);
}

class CreateGroupError extends CreateGroupState {
  final String message;

  CreateGroupError(this.message);
}

class CreateGroupCubit extends Cubit<CreateGroupState> {
  final CreateGroupUseCase createGroupUseCase;

  CreateGroupCubit({required this.createGroupUseCase}) : super(CreateGroupInitial());

  Future<void> createGroup(CreateGroupParams params) async {
    emit(CreateGroupLoading());
    final result = await createGroupUseCase(params);
    
    result.fold(
      (error) => emit(CreateGroupError(error)),
      (group) => emit(CreateGroupSuccess('Tạo nhóm ${group.name} thành công!')),
    );
  }
}
