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

import 'features/group/data/datasources/group_remote_data_source.dart';
import 'features/group/data/repositories/group_repository_impl.dart';
import 'features/group/domain/repositories/group_repository.dart';
import 'features/group/domain/usecases/get_groups_usecase.dart';
import 'features/group/domain/usecases/get_my_groups_usecase.dart';
import 'features/group/domain/usecases/create_group_usecase.dart';
import 'features/group/domain/usecases/get_group_detail_usecase.dart';
import 'features/group/domain/usecases/join_group_usecase.dart';
import 'features/group/domain/usecases/get_join_requests_usecase.dart';
import 'features/group/domain/usecases/approve_join_usecase.dart';
import 'features/group/domain/usecases/reject_join_usecase.dart';
import 'features/group/domain/usecases/get_members_usecase.dart';
import 'features/group/domain/usecases/update_member_role_usecase.dart';
import 'features/group/domain/usecases/update_member_status_usecase.dart';
import 'features/marketplace/data/datasources/marketplace_remote_data_source.dart';
import 'features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'features/marketplace/domain/repositories/marketplace_repository.dart';
import 'features/marketplace/domain/usecases/listing_usecases.dart';
import 'features/marketplace/domain/usecases/request_usecases.dart';
import 'features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'features/marketplace/presentation/cubit/create_listing_cubit.dart';
import 'features/marketplace/presentation/cubit/listing_detail_cubit.dart';
import 'features/group/presentation/cubit/group_cubit.dart';
import 'features/group/presentation/cubit/group_detail_cubit.dart';
import 'features/group/presentation/cubit/create_group_cubit.dart';
import 'features/group/presentation/cubit/group_join_requests_cubit.dart';
import 'features/group/presentation/cubit/group_members_cubit.dart';

import 'features/post/data/datasources/post_remote_data_source.dart';
import 'features/post/data/repositories/post_repository_impl.dart';
import 'features/post/domain/repositories/post_repository.dart';
import 'features/post/domain/usecases/get_posts_usecase.dart';
import 'features/post/domain/usecases/create_post_usecase.dart';
import 'features/post/domain/usecases/delete_post_usecase.dart';
import 'features/post/domain/usecases/like_post_usecase.dart';
import 'features/post/domain/usecases/unlike_post_usecase.dart';
import 'features/post/domain/usecases/get_comments_usecase.dart';
import 'features/post/domain/usecases/add_comment_usecase.dart';
import 'features/post/presentation/cubit/group_feed_cubit.dart';
import 'features/post/presentation/cubit/post_comments_cubit.dart';

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
  sl.registerLazySingleton<GroupRemoteDataSource>(
    () => GroupRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<MarketplaceRemoteDataSource>(
    () => MarketplaceRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MarketplaceRepository>(
    () => MarketplaceRepositoryImpl(remoteDataSource: sl()),
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

  sl.registerLazySingleton(() => GetGroupsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyGroupsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGroupUseCase(sl()));
  sl.registerLazySingleton(() => GetGroupDetailUseCase(sl()));
  sl.registerLazySingleton(() => JoinGroupUseCase(sl()));
  sl.registerLazySingleton(() => GetJoinRequestsUseCase(sl()));
  sl.registerLazySingleton(() => ApproveJoinUseCase(sl()));
  sl.registerLazySingleton(() => RejectJoinUseCase(sl()));
  sl.registerLazySingleton(() => GetMembersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMemberRoleUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMemberStatusUseCase(sl()));

  sl.registerLazySingleton(() => GetPostsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePostUseCase(sl()));
  sl.registerLazySingleton(() => DeletePostUseCase(sl()));
  sl.registerLazySingleton(() => LikePostUseCase(sl()));
  sl.registerLazySingleton(() => UnlikePostUseCase(sl()));
  sl.registerLazySingleton(() => GetCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));

  sl.registerLazySingleton(() => GetCatalogUseCase(sl()));
  sl.registerLazySingleton(() => GetListingDetailUseCase(sl()));
  sl.registerLazySingleton(() => CreateListingUseCase(sl()));
  sl.registerLazySingleton(() => GetRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreateRequestUseCase(sl()));
  sl.registerLazySingleton(() => ApproveRequestUseCase(sl()));
  sl.registerLazySingleton(() => RejectRequestUseCase(sl()));
  sl.registerLazySingleton(() => ScheduleRequestUseCase(sl()));
  sl.registerLazySingleton(() => CompleteRequestUseCase(sl()));

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
    () => MarketplaceCubit(
      getCatalogUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => CreateListingCubit(
      createListingUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ListingDetailCubit(
      getListingDetailUseCase: sl(),
      createRequestUseCase: sl(),
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

  sl.registerFactory(() => GroupCubit(
        getGroupsUseCase: sl(),
        getMyGroupsUseCase: sl(),
      ));
  sl.registerFactory(() => GroupDetailCubit(
        getGroupDetailUseCase: sl(),
        joinGroupUseCase: sl(),
      ));
  sl.registerFactory(() => CreateGroupCubit(
        createGroupUseCase: sl(),
      ));
  sl.registerFactory(() => GroupJoinRequestsCubit(
        getJoinRequestsUseCase: sl(),
        approveJoinUseCase: sl(),
        rejectJoinUseCase: sl(),
      ));
  sl.registerFactory(() => GroupMembersCubit(
        getMembersUseCase: sl(),
        updateMemberRoleUseCase: sl(),
        updateMemberStatusUseCase: sl(),
      ));
  sl.registerFactory(
    () => GroupFeedCubit(
      getPostsUseCase: sl(),
      createPostUseCase: sl(),
      deletePostUseCase: sl(),
      likePostUseCase: sl(),
      unlikePostUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => PostCommentsCubit(
      getCommentsUseCase: sl(),
      addCommentUseCase: sl(),
    ),
  );
}
