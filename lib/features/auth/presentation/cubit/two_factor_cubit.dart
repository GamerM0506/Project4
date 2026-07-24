import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/two_factor_setup_entity.dart';
import '../../domain/usecases/disable_two_factor_usecase.dart';
import '../../domain/usecases/enable_two_factor_usecase.dart';
import '../../domain/usecases/get_two_factor_status_usecase.dart';
import '../../domain/usecases/setup_two_factor_usecase.dart';

abstract class TwoFactorState {
  final bool isEnabled;
  final TwoFactorSetupEntity? pendingSetup;

  const TwoFactorState({required this.isEnabled, this.pendingSetup});
}

class TwoFactorInitial extends TwoFactorState {
  const TwoFactorInitial({required super.isEnabled, super.pendingSetup});
}

class TwoFactorLoading extends TwoFactorState {
  const TwoFactorLoading({required super.isEnabled, super.pendingSetup});
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
  final GetTwoFactorStatusUseCase getTwoFactorStatusUseCase;
  final EnableTwoFactorUseCase enableTwoFactorUseCase;
  final DisableTwoFactorUseCase disableTwoFactorUseCase;
  final SharedPreferences sharedPreferences;

  TwoFactorCubit({
    required this.setupTwoFactorUseCase,
    required this.getTwoFactorStatusUseCase,
    required this.enableTwoFactorUseCase,
    required this.disableTwoFactorUseCase,
    required this.sharedPreferences,
  }) : super(
         TwoFactorInitial(
           isEnabled:
               sharedPreferences.getBool(AppConstants.keyTwoFactorEnabled) ??
               false,
         ),
       );

  Future<void> loadStatus() async {
    emit(TwoFactorLoading(isEnabled: state.isEnabled));
    final result = await getTwoFactorStatusUseCase();
    if (isClosed) return;

    await result.fold<Future<void>>(
      (error) async {
        emit(TwoFactorFailure(message: error, isEnabled: state.isEnabled));
      },
      (enabled) async {
        await sharedPreferences.setBool(
          AppConstants.keyTwoFactorEnabled,
          enabled,
        );
        if (isClosed) return;
        emit(TwoFactorInitial(isEnabled: enabled));
      },
    );
  }

  Future<void> startSetup() async {
    final wasEnabled = state.isEnabled;
    if (wasEnabled) {
      emit(
        const TwoFactorFailure(
          message: '2FA đang được bật. Hãy tắt trước khi thiết lập lại.',
          isEnabled: true,
        ),
      );
      return;
    }
    emit(TwoFactorLoading(isEnabled: wasEnabled));

    final result = await setupTwoFactorUseCase();
    if (isClosed) return;

    result.fold(
      (error) => emit(TwoFactorFailure(message: error, isEnabled: wasEnabled)),
      (setup) => emit(TwoFactorSetupReady(setup: setup, isEnabled: false)),
    );
  }

  Future<void> enable(String code) async {
    final trimmed = code.trim();
    final pending = state.pendingSetup;

    if (trimmed.length < 6) {
      emit(
        TwoFactorFailure(
          message: 'Vui lòng nhập mã 6 số từ app Authenticator.',
          isEnabled: false,
          pendingSetup: pending,
        ),
      );
      return;
    }

    emit(TwoFactorLoading(isEnabled: false, pendingSetup: pending));
    final result = await enableTwoFactorUseCase(trimmed);
    if (isClosed) return;

    await result.fold<Future<void>>(
      (error) async {
        emit(
          TwoFactorFailure(
            message: error,
            isEnabled: false,
            pendingSetup: pending,
          ),
        );
      },
      (_) async {
        await _syncAfterMutation(
          fallbackEnabled: true,
          message: 'Đã bật xác thực 2 bước.',
        );
      },
    );
  }

  Future<void> disable(String code) async {
    final trimmed = code.trim();
    if (trimmed.length < 6) {
      emit(
        TwoFactorFailure(
          message: 'Vui lòng nhập mã 6 số từ app Authenticator.',
          isEnabled: true,
        ),
      );
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
        await _syncAfterMutation(
          fallbackEnabled: false,
          message: 'Đã tắt xác thực 2 bước.',
        );
      },
    );
  }

  void resetToIdle() {
    emit(TwoFactorInitial(isEnabled: state.isEnabled));
  }

  Future<void> _syncAfterMutation({
    required bool fallbackEnabled,
    required String message,
  }) async {
    final status = await getTwoFactorStatusUseCase();
    var enabled = fallbackEnabled;
    status.fold((_) {}, (value) => enabled = value);
    await sharedPreferences.setBool(AppConstants.keyTwoFactorEnabled, enabled);
    if (isClosed) return;
    emit(TwoFactorSuccess(message: message, isEnabled: enabled));
  }
}
