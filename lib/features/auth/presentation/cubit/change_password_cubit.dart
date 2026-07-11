import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/change_password_usecase.dart';

abstract class ChangePasswordState {}

class ChangePasswordInitial extends ChangePasswordState {}

class ChangePasswordLoading extends ChangePasswordState {}

class ChangePasswordSuccess extends ChangePasswordState {}

class ChangePasswordFailure extends ChangePasswordState {
  final String message;
  ChangePasswordFailure({required this.message});
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ChangePasswordCubit({required this.changePasswordUseCase}) : super(ChangePasswordInitial());

  Future<void> changePassword(String currentPassword, String newPassword) async {
    emit(ChangePasswordLoading());
    final result = await changePasswordUseCase(currentPassword, newPassword);
    result.fold(
      (failure) => emit(ChangePasswordFailure(message: failure)),
      (_) => emit(ChangePasswordSuccess()),
    );
  }
}
