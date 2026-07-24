import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../user/presentation/cubit/user_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _progressController.forward();
    _heartController.repeat(reverse: true);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authCubit = context.read<AuthCubit>();
    final sessionOk = await authCubit.restoreSession();

    // Wait at least for progress animation (or remaining time)
    if (_progressController.status != AnimationStatus.completed) {
      await _progressController.forward();
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    if (sessionOk) {
      context.read<UserCubit>().fetchProfile();
      context.go(AppRoutes.home);
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
