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
      create: (context) => sl<HomeCubit>()..fetchHomeData(),
      child: Scaffold(
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // 1. Sticky Header
                const HomeSliverAppBar(),

                // 2. Body Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero Banner
                      const HomeHeroBanner(),
                      const SizedBox(height: 32),
                      
                      // Quick Actions
                      const HomeQuickActions(),
                      const SizedBox(height: 32),
                      
                      if (state is HomeLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (state is HomeLoaded) ...[
                        // Featured Charity Groups
                        HomeSectionTitle(
                          title: 'Featured Groups',
                          action: 'See all',
                          onActionTap: () {},
                        ),
                        const SizedBox(height: 16),
                        HomeFeaturedGroups(groups: state.groups),
                        const SizedBox(height: 32),
                        
                        // Recent Free Items
                        HomeSectionTitle(
                          title: 'Recent Free Items',
                          action: 'View map',
                          onActionTap: () {},
                        ),
                        const SizedBox(height: 16),
                        HomeRecentItems(items: state.listings),
                      ] else if (state is HomeError) ...[
                        Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
                      ],
                      const SizedBox(height: 80), // Padding for Bottom Navigation
                    ]),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
