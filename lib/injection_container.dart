import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/verify_usecase.dart';
import 'features/auth/domain/usecases/resend_verification_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

import 'features/user/data/datasources/user_remote_data_source.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/domain/repositories/user_repository.dart';
import 'features/user/domain/usecases/get_profile_usecase.dart';
import 'features/user/presentation/cubit/user_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiClient(dio: sl(), sharedPreferences: sl()));

  // Features - Auth
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyUseCase(sl()));
  sl.registerLazySingleton(() => ResendVerificationUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));

  // Cubit
  sl.registerFactory(() => AuthCubit(
        loginUseCase: sl(),
        registerUseCase: sl(),
        verifyUseCase: sl(),
        resendVerificationUseCase: sl(),
        sharedPreferences: sl(),
      ));
  sl.registerFactory(() => UserCubit(
        getProfileUseCase: sl(),
      ));
}
