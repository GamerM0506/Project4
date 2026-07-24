import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/update_group_usecase.dart';
import '../../data/models/group_model.dart';

abstract class UpdateGroupState {}

class UpdateGroupInitial extends UpdateGroupState {}

class UpdateGroupLoading extends UpdateGroupState {}

class UpdateGroupSuccess extends UpdateGroupState {
  final GroupModel group;
  final String message;

  UpdateGroupSuccess(this.group, this.message);
}

class UpdateGroupError extends UpdateGroupState {
  final String message;

  UpdateGroupError(this.message);
}

class UpdateGroupCubit extends Cubit<UpdateGroupState> {
  final UpdateGroupUseCase updateGroupUseCase;

  UpdateGroupCubit({required this.updateGroupUseCase})
    : super(UpdateGroupInitial());

  Future<void> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? address,
    String? provinceCode,
    String? districtCode,
    bool? allowMemberPost,
    bool? requirePostReview,
  }) async {
    emit(UpdateGroupLoading());
    final result = await updateGroupUseCase(
      groupId,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      address: address,
      provinceCode: provinceCode,
      districtCode: districtCode,
      allowMemberPost: allowMemberPost,
      requirePostReview: requirePostReview,
    );

    result.fold(
      (error) => emit(UpdateGroupError(error)),
      (group) => emit(UpdateGroupSuccess(group, 'Cập nhật nhóm thành công!')),
    );
  }
}
