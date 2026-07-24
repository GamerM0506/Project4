import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/entities/user_entity.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final SharedPreferences? sharedPreferences;

  UserCubit({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    this.sharedPreferences,
  }) : super(UserInitial());

  Future<void> fetchProfile() async {
    final previous = state.userOrNull;
    emit(UserLoading(previousUser: previous));

    final result = await getProfileUseCase();
    result.fold(
      (error) => emit(UserError(message: error, previousUser: previous)),
      (user) {
        final prefs = sharedPreferences;
        if (prefs != null && user.id.isNotEmpty) {
          prefs.setString(AppConstants.keyUserId, user.id);
        }
        emit(UserLoaded(user: user));
      },
    );
  }

  Future<void> updateProfile(UserEntity updatedUser) async {
    final previous = state.userOrNull ?? updatedUser;
    emit(UserUpdating(currentUser: previous));

    final result = await updateProfileUseCase(updatedUser);
    result.fold(
      (error) {
        emit(UserUpdateError(message: error, previousUser: previous));
        emit(UserLoaded(user: previous));
      },
      (user) {
        emit(UserUpdateSuccess(user: user));
        emit(UserLoaded(user: user));
      },
    );
  }

  void clear() {
    emit(UserInitial());
  }
}
