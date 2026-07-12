import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/network/media_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/verify_usecase.dart';
import 'features/auth/domain/usecases/resend_verification_usecase.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/verify_reset_code_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';
import 'features/auth/domain/usecases/setup_two_factor_usecase.dart';
import 'features/auth/domain/usecases/enable_two_factor_usecase.dart';
import 'features/auth/domain/usecases/disable_two_factor_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/change_password_cubit.dart';
import 'features/auth/presentation/cubit/two_factor_cubit.dart';

import 'features/user/data/datasources/user_remote_data_source.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/domain/repositories/user_repository.dart';
import 'features/user/domain/usecases/get_profile_usecase.dart';
import 'features/user/domain/usecases/update_profile_usecase.dart';
import 'features/user/presentation/cubit/user_cubit.dart';

import 'core/theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiClient(dio: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => MediaService(prefs: sl()));

  sl.registerFactory(() => ThemeCubit(prefs: sl()));

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyUseCase(sl()));
  sl.registerLazySingleton(() => ResendVerificationUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => VerifyResetCodeUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => SetupTwoFactorUseCase(sl()));
  sl.registerLazySingleton(() => EnableTwoFactorUseCase(sl()));
  sl.registerLazySingleton(() => DisableTwoFactorUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  sl.registerLazySingleton(() => AuthCubit(
        loginUseCase: sl(),
        registerUseCase: sl(),
        verifyUseCase: sl(),
        resendVerificationUseCase: sl(),
        forgotPasswordUseCase: sl(),
        verifyResetCodeUseCase: sl(),
        resetPasswordUseCase: sl(),
        sharedPreferences: sl(),
      ));
  sl.registerFactory(
    () => ChangePasswordCubit(
      changePasswordUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => TwoFactorCubit(
      setupTwoFactorUseCase: sl(),
      enableTwoFactorUseCase: sl(),
      disableTwoFactorUseCase: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerFactory(() => UserCubit(
        getProfileUseCase: sl(),
        updateProfileUseCase: sl(),
      ));
}
