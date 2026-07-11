import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/entities/user_entity.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  UserCubit({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
  }) : super(UserInitial());

  Future<void> fetchProfile() async {
    emit(UserLoading());
    final result = await getProfileUseCase();
    result.fold(
      (error) => emit(UserError(message: error)),
      (user) => emit(UserLoaded(user: user)),
    );
  }

  Future<void> updateProfile(UserEntity updatedUser) async {
    emit(UserUpdating());
    final result = await updateProfileUseCase(updatedUser);
    result.fold(
      (error) => emit(UserUpdateError(message: error)),
      (user) {
        emit(UserUpdateSuccess(user: user));
        // After success, emit UserLoaded again to keep state
        emit(UserLoaded(user: user));
      },
    );
  }
}
