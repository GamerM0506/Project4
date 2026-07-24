import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_routes.dart';
import '../constants/app_constants.dart';
import '../layout/main_layout.dart';
import '../../injection_container.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verification_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_verification_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/two_factor_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/create_listing_page.dart';
import '../../features/marketplace/presentation/pages/listing_detail_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/group/presentation/pages/groups_page.dart';
import '../../features/group/presentation/pages/group_detail_page.dart';
import '../../features/group/presentation/pages/create_group_page.dart';
import '../../features/group/presentation/pages/group_dashboard_page.dart';
import '../../features/group/presentation/pages/edit_group_page.dart';
import '../../features/group/data/models/group_model.dart';
import '../../features/chat/presentation/pages/chat_inbox_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/user/presentation/pages/profile_page.dart';
import '../../features/user/presentation/pages/edit_profile_page.dart';
import '../../features/user/presentation/pages/settings_page.dart';
import '../../features/user/presentation/pages/support_page.dart';
import '../../features/user/presentation/pages/my_items_page.dart';
import '../../features/user/presentation/pages/my_requests_page.dart';
import '../../features/user/presentation/pages/saved_groups_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final GlobalKey<NavigatorState> _shellMarketplaceKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellMarketplace');
final GlobalKey<NavigatorState> _shellGroupsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellGroups',
);
final GlobalKey<NavigatorState> _shellProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellProfile',
);

CustomTransitionPage _buildPageWithAnimation(
  Widget page, {
  bool slideUp = false,
}) {
  return CustomTransitionPage(
    child: page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (slideUp) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      }
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final prefs = sl<SharedPreferences>();
    final hasSession =
        (prefs.getString(AppConstants.keyAccessToken)?.isNotEmpty ?? false) ||
        (prefs.getString(AppConstants.keyRefreshToken)?.isNotEmpty ?? false);
    final path = state.uri.path;
    final publicPaths = {
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.verify,
      AppRoutes.forgotPassword,
      AppRoutes.forgotPasswordVerification,
      AppRoutes.resetPassword,
    };

    if (!hasSession && !publicPaths.contains(path)) {
      return AppRoutes.login;
    }
    if (hasSession && path == AppRoutes.login) {
      return AppRoutes.splash;
    }
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          navigatorKey: _shellHomeKey,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Branch 1: Marketplace
        StatefulShellBranch(
          navigatorKey: _shellMarketplaceKey,
          routes: [
            GoRoute(
              path: AppRoutes.marketplace,
              builder: (context, state) => const MarketplacePage(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return ListingDetailPage(listingId: id);
                  },
                ),
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final groupId =
                        extra?['groupId'] as String? ??
                        state.uri.queryParameters['groupId'];
                    return CreateListingPage(groupId: groupId);
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Groups
        StatefulShellBranch(
          navigatorKey: _shellGroupsKey,
          routes: [
            GoRoute(
              path: AppRoutes.groups,
              builder: (context, state) => const GroupsPage(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return GroupDetailPage(groupId: id);
                  },
                ),
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const CreateGroupPage(),
                ),
                GoRoute(
                  path: 'dashboard/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return GroupDashboardPage(groupId: id);
                  },
                ),
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final group = state.extra as GroupModel;
                    return EditGroupPage(group: group);
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 3: Profile
        StatefulShellBranch(
          navigatorKey: _shellProfileKey,
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: AppRoutes.editProfile,
              pageBuilder: (context, state) => _buildPageWithAnimation(
                const EditProfilePage(),
                slideUp: true,
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) =>
                  _buildPageWithAnimation(const SettingsPage(), slideUp: true),
            ),
            GoRoute(
              path: AppRoutes.support,
              pageBuilder: (context, state) =>
                  _buildPageWithAnimation(const SupportPage(), slideUp: true),
            ),
            GoRoute(
              path: AppRoutes.myItems,
              pageBuilder: (context, state) =>
                  _buildPageWithAnimation(const MyItemsPage(), slideUp: false),
            ),
            GoRoute(
              path: AppRoutes.myRequests,
              pageBuilder: (context, state) => _buildPageWithAnimation(
                const MyRequestsPage(),
                slideUp: false,
              ),
            ),
            GoRoute(
              path: AppRoutes.savedGroups,
              pageBuilder: (context, state) => _buildPageWithAnimation(
                const SavedGroupsPage(),
                slideUp: false,
              ),
            ),
          ],
        ),
      ],
    ),

    // Standalone full-screen routes on _rootNavigatorKey
    GoRoute(
      path: AppRoutes.splash,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithAnimation(const LoginPage()),
    ),
    GoRoute(
      path: AppRoutes.register,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithAnimation(const RegisterPage()),
    ),
    GoRoute(
      path: AppRoutes.verify,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final emailOrPhone =
            state.extra as String? ?? state.uri.queryParameters['email'] ?? '';
        return _buildPageWithAnimation(
          VerificationPage(emailOrPhone: emailOrPhone),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithAnimation(const ForgotPasswordPage()),
    ),
    GoRoute(
      path: AppRoutes.forgotPasswordVerification,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final email =
            state.extra as String? ?? state.uri.queryParameters['email'] ?? '';
        return _buildPageWithAnimation(
          ForgotPasswordVerificationPage(email: email),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extraArgs = state.extra as Map<String, String>?;
        final args =
            extraArgs ??
            {
              'email': state.uri.queryParameters['email'] ?? '',
              'code': state.uri.queryParameters['code'] ?? '',
              'resetToken': state.uri.queryParameters['token'] ?? '',
            };
        return _buildPageWithAnimation(ResetPasswordPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithAnimation(const ChangePasswordPage()),
    ),
    GoRoute(
      path: AppRoutes.twoFactor,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithAnimation(const TwoFactorPage()),
    ),
    GoRoute(
      path: AppRoutes.productDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Trang chi tiết vật phẩm'))),
    ),
    GoRoute(
      path: AppRoutes.chatInbox,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChatInboxPage(),
    ),
    GoRoute(
      path: AppRoutes.chatRoom,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extraArgs = state.extra as Map<String, dynamic>?;
        final conversationId = extraArgs?['conversationId'] as String? ?? '1';
        final name = extraArgs?['name'] as String? ?? 'Hội nhóm';
        return ChatRoomPage(conversationId: conversationId, name: name);
      },
    ),
    GoRoute(
      path: AppRoutes.notifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const Scaffold(body: Center(child: Text('Trang thông báo')));
      },
    ),
  ],
);
