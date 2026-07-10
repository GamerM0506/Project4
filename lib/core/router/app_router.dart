import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../layout/main_layout.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verification_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
// import '../../features/search/presentation/pages/search_page.dart';
// import '../../features/chat/presentation/pages/chat_page.dart';
// import '../../features/profile/presentation/pages/profile_page.dart';
// import '../../features/notifications/presentation/pages/notification_page.dart';

// Import the flutter global navigator key
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Return the MainLayout with the navigation shell
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Branch 1: Marketplace
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.marketplace,
              builder: (context, state) => const Scaffold(body: Center(child: Text('Marketplace Page'))),
            ),
          ],
        ),
        // Branch 2: Messages
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.messages,
              builder: (context, state) => const Scaffold(body: Center(child: Text('Chat Page'))),
            ),
          ],
        ),
        // Branch 3: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const Scaffold(body: Center(child: Text('Profile Page'))),
            ),
          ],
        ),
      ],
    ),
    
    // Other top-level routes that don't need BottomNavigationBar
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.verify,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final emailOrPhone = state.extra as String? ?? '';
        return VerificationPage(emailOrPhone: emailOrPhone);
      },
    ),
    GoRoute(
      path: AppRoutes.productDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const Scaffold(body: Center(child: Text('Product Detail Page'))),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const Scaffold(body: Center(child: Text('Notification Page')));
      },
    ),
  ],
);


