import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../injection_container.dart';
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
            return CustomScrollView(
              slivers: [
                const HomeSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const HomeHeroBanner(),
                      const SizedBox(height: 32),
                      const HomeQuickActions(),
                      const SizedBox(height: 32),
                      if (state is HomeLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (state is HomeLoaded) ...[
                        HomeSectionTitle(
                          title: 'Hội nhóm nổi bật',
                          action: 'Xem tất cả',
                          onActionTap: () {},
                        ),
                        const SizedBox(height: 16),
                        HomeFeaturedGroups(groups: state.groups),
                        const SizedBox(height: 32),
                        HomeSectionTitle(
                          title: 'Vật phẩm miễn phí gần đây',
                          action: 'Xem bản đồ',
                          onActionTap: () {},
                        ),
                        const SizedBox(height: 16),
                        HomeRecentItems(items: state.listings),
                      ] else if (state is HomeError)
                        Center(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
