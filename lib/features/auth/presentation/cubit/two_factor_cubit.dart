import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/two_factor_setup_entity.dart';
import '../../domain/usecases/disable_two_factor_usecase.dart';
import '../../domain/usecases/enable_two_factor_usecase.dart';
import '../../domain/usecases/setup_two_factor_usecase.dart';

abstract class TwoFactorState {
  final bool isEnabled;
  final TwoFactorSetupEntity? pendingSetup;

  const TwoFactorState({
    required this.isEnabled,
    this.pendingSetup,
  });
}

class TwoFactorInitial extends TwoFactorState {
  const TwoFactorInitial({
    required super.isEnabled,
    super.pendingSetup,
  });
}

class TwoFactorLoading extends TwoFactorState {
  const TwoFactorLoading({
    required super.isEnabled,
    super.pendingSetup,
  });
}

class TwoFactorSetupReady extends TwoFactorState {
  const TwoFactorSetupReady({
    required TwoFactorSetupEntity setup,
    required super.isEnabled,
  }) : super(pendingSetup: setup);

  TwoFactorSetupEntity get setup => pendingSetup!;
}

class TwoFactorSuccess extends TwoFactorState {
  final String message;

  const TwoFactorSuccess({
    required this.message,
    required super.isEnabled,
    super.pendingSetup,
  });
}

class TwoFactorFailure extends TwoFactorState {
  final String message;

  const TwoFactorFailure({
    required this.message,
    required super.isEnabled,
    super.pendingSetup,
  });
}

class TwoFactorCubit extends Cubit<TwoFactorState> {
  final SetupTwoFactorUseCase setupTwoFactorUseCase;
  final EnableTwoFactorUseCase enableTwoFactorUseCase;
  final DisableTwoFactorUseCase disableTwoFactorUseCase;
  final SharedPreferences sharedPreferences;

  TwoFactorCubit({
    required this.setupTwoFactorUseCase,
    required this.enableTwoFactorUseCase,
    required this.disableTwoFactorUseCase,
    required this.sharedPreferences,
  }) : super(
          TwoFactorInitial(
            isEnabled: sharedPreferences.getBool(
                  AppConstants.keyTwoFactorEnabled,
                ) ??
                false,
          ),
        );

  Future<void> startSetup() async {
    final wasEnabled = state.isEnabled;
    emit(TwoFactorLoading(isEnabled: wasEnabled));

    final result = await setupTwoFactorUseCase();
    if (isClosed) return;

    result.fold(
      (error) => emit(TwoFactorFailure(
        message: error,
        isEnabled: wasEnabled,
      )),
      (setup) => emit(TwoFactorSetupReady(
        setup: setup,
        isEnabled: false,
      )),
    );
  }

  Future<void> enable(String code) async {
    final trimmed = code.trim();
    final pending = state.pendingSetup;

    if (trimmed.length < 6) {
      emit(TwoFactorFailure(
        message: 'Vui lòng nhập mã 6 số từ app Authenticator.',
        isEnabled: false,
        pendingSetup: pending,
      ));
      return;
    }

    emit(TwoFactorLoading(isEnabled: false, pendingSetup: pending));
    final result = await enableTwoFactorUseCase(trimmed);
    if (isClosed) return;

    await result.fold<Future<void>>(
      (error) async {
        emit(TwoFactorFailure(
          message: error,
          isEnabled: false,
          pendingSetup: pending,
        ));
      },
      (_) async {
        await sharedPreferences.setBool(
          AppConstants.keyTwoFactorEnabled,
          true,
        );
        if (isClosed) return;
        emit(const TwoFactorSuccess(
          message: 'Đã bật xác thực 2 bước.',
          isEnabled: true,
        ));
      },
    );
  }

  Future<void> disable(String code) async {
    final trimmed = code.trim();
    if (trimmed.length < 6) {
      emit(TwoFactorFailure(
        message: 'Vui lòng nhập mã 6 số từ app Authenticator.',
        isEnabled: true,
      ));
      return;
    }

    emit(const TwoFactorLoading(isEnabled: true));
    final result = await disableTwoFactorUseCase(trimmed);
    if (isClosed) return;

    await result.fold<Future<void>>(
      (error) async {
        emit(TwoFactorFailure(message: error, isEnabled: true));
      },
      (_) async {
        await sharedPreferences.setBool(
          AppConstants.keyTwoFactorEnabled,
          false,
        );
        if (isClosed) return;
        emit(const TwoFactorSuccess(
          message: 'Đã tắt xác thực 2 bước.',
          isEnabled: false,
        ));
      },
    );
  }

  void resetToIdle() {
    emit(TwoFactorInitial(isEnabled: state.isEnabled));
  }
}
