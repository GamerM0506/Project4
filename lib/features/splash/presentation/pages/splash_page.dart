import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/network/session_token.dart';
import '../../../../features/user/presentation/cubit/user_cubit.dart';
import '../../../../injection_container.dart';
import '../../../notification/application/push_notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;

  /// Thời gian tối thiểu giữ màn chờ. Đủ để thanh chạy trọn một lượt mà không
  /// bắt người dùng đợi vô cớ — trước đây cố định 3s và còn cộng thêm thời
  /// gian tải hồ sơ vì hai việc chạy nối tiếp.
  static const _minSplash = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: _minSplash,
    );

    // Nhịp tim đập, đồng bộ với độ dài thanh chạy.
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _progressController.forward();
    _heartController.repeat(reverse: true);
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    final prefs = sl<SharedPreferences>();
    final accessToken = prefs.getString(AppConstants.keyAccessToken);
    final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
    final hasSession =
        isUsableAccessToken(accessToken) || (refreshToken?.isNotEmpty ?? false);

    // Chạy song song: mạng nhanh thì chỉ tốn đúng _minSplash, mạng chậm thì
    // hoạt ảnh không phải chờ thêm.
    //
    // Bọc catch riêng cho mỗi nhánh: một lỗi bất ngờ không được phép giữ người
    // dùng kẹt lại ở màn chờ.
    await Future.wait([
      if (hasSession)
        context.read<UserCubit>().fetchProfile().catchError((_) {}),
      _progressController.forward().orCancel.catchError((_) {}),
    ]);
    if (!mounted) return;

    final validAccessToken = prefs.getString(AppConstants.keyAccessToken);
    if (isUsableAccessToken(validAccessToken)) {
      context.go(AppRoutes.home);
      await Future<void>.delayed(Duration.zero);
      await sl<PushNotificationService>().onAuthenticated();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background Image (Toàn bộ màn hình Splash lấy từ file screen.png)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Thanh loading và trái tim chạy ở dưới cùng
          Positioned(
            left: 40,
            right: 40,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading bar container
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;

                    return AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        final progress = _progressController.value;
                        const heartSize = 32.0;
                        final currentPosition =
                            progress * (maxWidth - heartSize);

                        return SizedBox(
                          height: heartSize + 12,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Thanh Loading chạy dọc (Nền)
                              Positioned(
                                left: 0,
                                top: heartSize / 2,
                                child: Container(
                                  width: maxWidth,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              // Thanh Loading chạy dọc (Đã chạy)
                              Positioned(
                                left: 0,
                                top: heartSize / 2,
                                child: Container(
                                  width: progress * maxWidth,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),

                              // Trái tim đập chạy dọc thanh
                              Positioned(
                                left: currentPosition,
                                top: 0,
                                child: AnimatedBuilder(
                                  animation: _heartScaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _heartScaleAnimation.value,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    Icons.favorite,
                                    color: colorScheme.primary,
                                    size: heartSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
