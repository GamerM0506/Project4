import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final GetProfileUseCase getProfileUseCase;

  UserCubit({required this.getProfileUseCase}) : super(UserInitial());

  Future<void> fetchProfile() async {
    emit(UserLoading());
    final result = await getProfileUseCase();
    result.fold(
      (error) => emit(UserError(message: error)),
      (user) => emit(UserLoaded(user: user)),
    );
  }
}
