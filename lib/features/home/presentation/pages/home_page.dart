import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_featured_groups.dart';
import '../widgets/home_feed_card.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_section_title.dart';
import '../widgets/home_sliver_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..fetchHomeData(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Tải trước khi chạm đáy để cuộn liên tục, không bị khựng.
    if (_scroll.position.extentAfter < 600) {
      context.read<HomeCubit>().loadMoreFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().fetchHomeData(),
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const HomeSliverAppBar(),

                // Phần đầu: banner, hành động nhanh, hội nhóm nổi bật
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
                      if (state.status == HomeStatus.loading)
                        const _HomeSkeleton()
                      else if (state.status == HomeStatus.error)
                        _HomeError(
                          message: state.errorMessage ?? 'Đã xảy ra lỗi',
                          onRetry: () =>
                              context.read<HomeCubit>().fetchHomeData(),
                        )
                      else if (state.status == HomeStatus.loaded) ...[
                        if (state.groups.isNotEmpty)
                          HomeSectionTitle(
                            title: 'Hội nhóm nổi bật',
                            action: 'Xem tất cả',
                            onActionTap: () => context.go(AppRoutes.groups),
                          ),
                      ],
                    ]),
                  ),
                ),

                // Băng chuyền hội nhóm nằm ngoài SliverPadding để thẻ chạm sát
                // mép màn hình và vùng vuốt trải hết chiều ngang.
                if (state.status == HomeStatus.loaded &&
                    state.groups.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: HomeFeaturedGroups(
                        groups: state.groups,
                        onJoined: (groupId) => context
                            .read<HomeCubit>()
                            .markJoinRequested(groupId),
                      ),
                    ),
                  ),

                if (state.status == HomeStatus.loaded)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.volunteer_activism_rounded,
                            ),
                            title: const Text('Đợt quyên góp đang mở'),
                            subtitle: const Text(
                              'Xem nhu cầu cụ thể và tiến độ tiếp nhận của các hội nhóm.',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go(AppRoutes.campaigns),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const HomeSectionTitle(title: 'Bảng tin'),
                        const SizedBox(height: 4),
                      ]),
                    ),
                  ),

                // Feed bài viết
                if (state.status == HomeStatus.loaded) ...[
                  if (state.feedError != null)
                    SliverToBoxAdapter(
                      child: _FeedNotice(
                        icon: Icons.cloud_off_rounded,
                        message: state.feedError!,
                      ),
                    )
                  else if (state.feed.isEmpty)
                    const SliverToBoxAdapter(
                      child: _FeedNotice(
                        icon: Icons.forum_outlined,
                        message:
                            'Chưa có bài viết nào. Hãy tham gia hội nhóm để '
                            'theo dõi hoạt động quyên góp.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverList.separated(
                        itemCount: state.feed.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = state.feed[index];
                          return HomeFeedCard(
                            item: item,
                            onToggleLike: () => context
                                .read<HomeCubit>()
                                .toggleLike(item.post.id),
                            onJoinRequested: (groupId) => context
                                .read<HomeCubit>()
                                .markJoinRequested(groupId),
                          );
                        },
                      ),
                    ),
                  if (state.loadingMoreFeed)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (!state.hasMoreFeed && state.feed.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: _FeedEndMarker(),
                    ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedNotice extends StatelessWidget {
  const _FeedNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEndMarker extends StatelessWidget {
  const _FeedEndMarker();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Đã xem hết',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.outlineVariant)),
        ],
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
        box(width: 120, height: 22, radius: 8),
        const SizedBox(height: 16),
        box(height: 190, radius: 20),
        const SizedBox(height: 14),
        box(height: 190, radius: 20),
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
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
