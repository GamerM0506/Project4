import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_public_profile_usecase.dart';
import 'public_profile_state.dart';

class PublicProfileCubit extends Cubit<PublicProfileState> {
  final GetPublicProfileUseCase getPublicProfileUseCase;

  PublicProfileCubit({required this.getPublicProfileUseCase})
    : super(const PublicProfileState());

  Future<void> load(String accountId) async {
    if (accountId.trim().isEmpty) {
      emit(
        state.copyWith(
          status: PublicProfileStatus.error,
          errorMessage: 'Không xác định được người dùng.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PublicProfileStatus.loading));

    final result = await getPublicProfileUseCase(accountId.trim());
    result.fold(
      (error) => emit(
        state.copyWith(
          status: PublicProfileStatus.error,
          errorMessage: error,
        ),
      ),
      (user) => emit(
        state.copyWith(status: PublicProfileStatus.loaded, user: user),
      ),
    );
  }
}
