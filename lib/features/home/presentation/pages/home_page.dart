import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_featured_groups.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_recent_items.dart';
import '../widgets/home_section_title.dart';
import '../widgets/home_sliver_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..fetchHomeData(),
      child: Scaffold(
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().fetchHomeData(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const HomeSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const HomeHeroBanner()
                            .animate()
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut),
                        const SizedBox(height: 28),
                        const HomeQuickActions()
                            .animate(delay: 100.ms)
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut),
                        const SizedBox(height: 28),
                        if (state is HomeLoading)
                          const _HomeSkeleton()
                        else if (state is HomeLoaded) ...[
                          HomeSectionTitle(
                            title: 'Hội nhóm nổi bật',
                            action: 'Xem tất cả',
                            onActionTap: () => context.go(AppRoutes.groups),
                          ),
                          const SizedBox(height: 16),
                          HomeFeaturedGroups(groups: state.groups),
                          const SizedBox(height: 28),
                          HomeSectionTitle(
                            title: 'Vật phẩm miễn phí gần đây',
                            action: 'Xem tất cả',
                            onActionTap: () =>
                                context.go(AppRoutes.marketplace),
                          ),
                          const SizedBox(height: 16),
                          HomeRecentItems(items: state.listings),
                        ] else if (state is HomeError)
                          _HomeError(
                            message: state.message,
                            onRetry: () => context
                                .read<HomeCubit>()
                                .fetchHomeData(),
                          ),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget box({double? width, required double height, double radius = 16}) {
      return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(radius),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1200.ms,
            color: colorScheme.surface.withValues(alpha: 0.6),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(width: 180, height: 22, radius: 8),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(child: box(height: 200, radius: 24)),
              const SizedBox(width: 14),
              Expanded(child: box(height: 200, radius: 24)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        box(width: 220, height: 22, radius: 8),
        const SizedBox(height: 16),
        box(height: 104, radius: 20),
        const SizedBox(height: 12),
        box(height: 104, radius: 20),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 34,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tải được dữ liệu',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
