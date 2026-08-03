import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/network/location_service.dart';
import 'core/network/media_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/home/data/home_repository.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/login_two_factor_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
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
import 'features/auth/domain/usecases/get_two_factor_status_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/change_password_cubit.dart';
import 'features/auth/presentation/cubit/two_factor_cubit.dart';

import 'features/user/data/datasources/user_remote_data_source.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/domain/repositories/user_repository.dart';
import 'features/user/domain/usecases/get_profile_usecase.dart';
import 'features/user/domain/usecases/update_profile_usecase.dart';
import 'features/user/domain/usecases/get_activities_usecase.dart';
import 'features/user/domain/usecases/get_public_profile_usecase.dart';
import 'features/user/presentation/cubit/user_cubit.dart';
import 'features/user/presentation/cubit/activity_cubit.dart';
import 'features/user/presentation/cubit/public_profile_cubit.dart';

import 'features/group/data/datasources/group_remote_data_source.dart';
import 'features/group/data/repositories/group_repository_impl.dart';
import 'features/group/domain/repositories/group_repository.dart';
import 'features/group/domain/usecases/get_groups_usecase.dart';
import 'features/group/domain/usecases/get_my_groups_usecase.dart';
import 'features/group/domain/usecases/create_group_usecase.dart';
import 'features/group/domain/usecases/get_group_detail_usecase.dart';
import 'features/group/domain/usecases/cancel_join_request_usecase.dart';
import 'features/group/domain/usecases/join_group_usecase.dart';
import 'features/group/domain/usecases/get_join_requests_usecase.dart';
import 'features/group/domain/usecases/approve_join_usecase.dart';
import 'features/group/domain/usecases/reject_join_usecase.dart';
import 'features/group/domain/usecases/get_members_usecase.dart';
import 'features/group/domain/usecases/update_member_role_usecase.dart';
import 'features/group/domain/usecases/update_member_status_usecase.dart';
import 'features/group/domain/usecases/update_group_usecase.dart';
import 'features/donation/data/datasources/campaign_remote_data_source.dart';
import 'features/ai/data/ai_service.dart';
import 'features/group/presentation/cubit/group_cubit.dart';
import 'features/group/presentation/cubit/group_detail_cubit.dart';
import 'features/group/presentation/cubit/create_group_cubit.dart';
import 'features/group/presentation/cubit/group_join_requests_cubit.dart';
import 'features/group/presentation/cubit/group_members_cubit.dart';
import 'features/group/presentation/cubit/group_dashboard_posts_cubit.dart';
import 'features/group/presentation/cubit/update_group_cubit.dart';

import 'features/post/data/datasources/post_remote_data_source.dart';
import 'features/post/data/repositories/post_repository_impl.dart';
import 'features/post/domain/repositories/post_repository.dart';
import 'features/post/domain/usecases/get_post_detail_usecase.dart';
import 'features/post/domain/usecases/set_post_pinned_usecase.dart';
import 'features/post/domain/usecases/update_post_status_usecase.dart';
import 'features/post/domain/usecases/get_posts_usecase.dart';
import 'features/post/domain/usecases/create_post_usecase.dart';
import 'features/post/domain/usecases/delete_post_usecase.dart';
import 'features/post/domain/usecases/like_post_usecase.dart';
import 'features/post/domain/usecases/unlike_post_usecase.dart';
import 'features/post/domain/usecases/get_comments_usecase.dart';
import 'features/post/domain/usecases/add_comment_usecase.dart';
import 'features/post/presentation/cubit/group_feed_cubit.dart';
import 'features/post/presentation/cubit/post_comments_cubit.dart';
import 'features/post/presentation/cubit/post_detail_cubit.dart';

import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/usecases/chat_usecases.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/chat/presentation/cubit/chat_inbox_cubit.dart';

import 'features/notification/data/datasources/notification_remote_data_source.dart';
import 'features/notification/domain/repositories/notification_repository.dart';
import 'features/notification/data/repositories/notification_repository_impl.dart';
import 'features/notification/presentation/cubit/notification_cubit.dart';
import 'features/notification/application/notification_navigator.dart';
import 'features/notification/application/push_notification_service.dart';

import 'core/theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies({SharedPreferences? preferences}) async {
  final sharedPreferences =
      preferences ?? await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  // Bắt buộc có timeout: donation-service gọi đồng bộ sang community-service
  // khi tạo/sửa campaign, nếu upstream treo mà Dio không giới hạn thì UI
  // sẽ chờ vô hạn (nút kẹt ở trạng thái đang gửi).
  sl.registerLazySingleton(
    () => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    ),
  );
  sl.registerLazySingleton(() => ApiClient(dio: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => AiService(apiClient: sl()));
  sl.registerLazySingleton(() => MediaService(prefs: sl()));
  // Singleton để cache danh mục tỉnh/huyện dùng chung cho mọi màn hình.
  sl.registerLazySingleton(() => LocationService());

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
  sl.registerLazySingleton(() => CampaignRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<GroupRepository>(() => GroupRepositoryImpl(sl()));
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => const NotificationNavigator());
  sl.registerLazySingleton(
    () => PushNotificationService(
      repository: sl(),
      preferences: sl(),
      navigator: sl(),
    ),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LoginTwoFactorUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
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
  sl.registerLazySingleton(() => GetTwoFactorStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetActivitiesUseCase(sl()));
  sl.registerLazySingleton(() => GetPublicProfileUseCase(sl()));

  sl.registerLazySingleton(() => GetGroupsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyGroupsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGroupUseCase(sl()));
  sl.registerLazySingleton(() => GetGroupDetailUseCase(sl()));
  sl.registerLazySingleton(() => JoinGroupUseCase(sl()));
  sl.registerLazySingleton(() => CancelJoinRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetJoinRequestsUseCase(sl()));
  sl.registerLazySingleton(() => ApproveJoinUseCase(sl()));
  sl.registerLazySingleton(() => RejectJoinUseCase(sl()));
  sl.registerLazySingleton(() => GetMembersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMemberRoleUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMemberStatusUseCase(sl()));
  sl.registerLazySingleton(() => UpdateGroupUseCase(sl()));

  sl.registerLazySingleton(() => GetPostsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePostUseCase(sl()));
  sl.registerLazySingleton(() => DeletePostUseCase(sl()));
  sl.registerLazySingleton(() => GetPostDetailUseCase(sl()));
  sl.registerLazySingleton(() => SetPostPinnedUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePostStatusUseCase(sl()));
  sl.registerLazySingleton(() => LikePostUseCase(sl()));
  sl.registerLazySingleton(() => UnlikePostUseCase(sl()));
  sl.registerLazySingleton(() => GetCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));

  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));

  sl.registerLazySingleton(() => HomeRepository(apiClient: sl()));

  sl.registerLazySingleton(
    () => AuthCubit(
      loginUseCase: sl(),
      loginTwoFactorUseCase: sl(),
      logoutUseCase: sl(),
      registerUseCase: sl(),
      verifyUseCase: sl(),
      resendVerificationUseCase: sl(),
      forgotPasswordUseCase: sl(),
      verifyResetCodeUseCase: sl(),
      resetPasswordUseCase: sl(),
      sharedPreferences: sl(),
      pushNotificationService: sl(),
    ),
  );
  sl.registerFactory(() => ChangePasswordCubit(changePasswordUseCase: sl()));
  sl.registerFactory(
    () => HomeCubit(repository: sl(), postRepository: sl()),
  );
  sl.registerFactory(
    () => TwoFactorCubit(
      setupTwoFactorUseCase: sl(),
      getTwoFactorStatusUseCase: sl(),
      enableTwoFactorUseCase: sl(),
      disableTwoFactorUseCase: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerFactory(
    () => UserCubit(getProfileUseCase: sl(), updateProfileUseCase: sl()),
  );
  sl.registerFactory(() => ActivityCubit(getActivitiesUseCase: sl()));
  sl.registerFactory(
    () => PublicProfileCubit(getPublicProfileUseCase: sl()),
  );

  sl.registerFactory(
    () => GroupCubit(
      getGroupsUseCase: sl(),
      getMyGroupsUseCase: sl(),
      joinGroupUseCase: sl(),
      cancelJoinRequestUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => GroupDetailCubit(getGroupDetailUseCase: sl(), joinGroupUseCase: sl()),
  );
  sl.registerFactory(() => CreateGroupCubit(createGroupUseCase: sl()));
  sl.registerFactory(
    () => GroupJoinRequestsCubit(
      getJoinRequestsUseCase: sl(),
      approveJoinUseCase: sl(),
      rejectJoinUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => GroupMembersCubit(
      getMembersUseCase: sl(),
      updateMemberRoleUseCase: sl(),
      updateMemberStatusUseCase: sl(),
    ),
  );
  sl.registerFactory(() => UpdateGroupCubit(updateGroupUseCase: sl()));
  sl.registerFactory(
    () => GroupDashboardPostsCubit(
      getPostsUseCase: sl(),
      updatePostStatusUseCase: sl(),
      deletePostUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => GroupFeedCubit(
      getPostsUseCase: sl(),
      createPostUseCase: sl(),
      deletePostUseCase: sl(),
      likePostUseCase: sl(),
      unlikePostUseCase: sl(),
      setPostPinnedUseCase: sl(),
      mediaService: sl(),
    ),
  );
  sl.registerFactory(
    () => PostCommentsCubit(getCommentsUseCase: sl(), addCommentUseCase: sl()),
  );
  sl.registerFactory(() => PostDetailCubit(getPostDetailUseCase: sl()));

  sl.registerFactory(() => ChatInboxCubit(getConversationsUseCase: sl()));
  sl.registerFactory(
    () => ChatCubit(
      getMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
      markAsReadUseCase: sl(),
    ),
  );

  sl.registerFactory(() => NotificationCubit(repository: sl()));
}
