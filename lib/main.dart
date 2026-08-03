import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/session_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'injection_container.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/user/presentation/cubit/user_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'features/notification/application/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Native Firebase client configuration may not be installed yet.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      firebaseReady = true;
    } catch (error) {
      debugPrint('Firebase is not configured: $error');
    }
  }
  timeago.setLocaleMessages('vi', timeago.ViMessages());
  final preferences = await SharedPreferences.getInstance();
  await SessionBootstrap.clearNonPersistentSession(preferences);
  await initDependencies(preferences: preferences);
  await sl<PushNotificationService>().initialize(firebaseReady: firebaseReady);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final authCubit = sl<AuthCubit>();
            AuthInterceptor.onSessionExpired = () {
              authCubit.handleSessionExpired();
            };
            return authCubit;
          },
        ),
        BlocProvider(create: (_) => sl<UserCubit>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthSuccess) {
            await sl<PushNotificationService>().onAuthenticated();
          } else if (state is AuthUnauthenticated) {
            await sl<PushNotificationService>().onSessionEnded();
            if (!context.mounted) return;
            context.read<UserCubit>().clear();
            appRouter.go(AppRoutes.login);
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              themeAnimationDuration: const Duration(milliseconds: 500),
              themeAnimationCurve: Curves.easeInOutCubic,
              routerConfig: appRouter,
            );
          },
        ),
      ),
    );
  }
}
