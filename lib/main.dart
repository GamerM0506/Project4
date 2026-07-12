import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/network/auth_interceptor.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'injection_container.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/user/presentation/cubit/user_cubit.dart';
import 'core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
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
        BlocProvider(
          create: (_) {
            final cubit = sl<UserCubit>();
            final token = sl<SharedPreferences>()
                .getString(AppConstants.keyAccessToken);
            if (token != null && token.isNotEmpty) {
              cubit.fetchProfile();
            }
            return cubit;
          },
        ),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
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
