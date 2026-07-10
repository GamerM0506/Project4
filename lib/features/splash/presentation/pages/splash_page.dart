import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Progress from 0 to 1 over 3 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 2. Beating heart animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _progressController.forward();
    _heartController.repeat(reverse: true);

    // Navigate to Login after 3 seconds
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          context.go(AppRoutes.login);
        }
      }
    });
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
                        final currentPosition = progress * (maxWidth - heartSize);

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
