import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../../../../core/constants/app_constants.dart';

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 20,
      toolbarHeight: 70,
      title: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          String fullName = 'Sarah'; // Default
          String avatarUrl = 'https://lh3.googleusercontent.com/aida-public/AB6AXuCDYVRLICKcmv_sXnU8dADoNXW3vxsG7233lr5AlNzAsPcUmD3I8SBurgJgBhXVgFeW-O4awNziFATbGbmrXk1LnkF5lpRnbK1IhRxMLB0NAvaHdpHqj529o1V_7DsRtg4jOMMCu18m6Ki_qynGay6ke6WpAqWA4Yg9Yvb3i-tRgAT4iZF8PvXJuBOl-Ma-T_XYb2LLY-mBmQ3xltiWNeWZ7JIKqJc7nM3UjPIDIHOHvUwIGlQSyeUyWQ';

          if (state is UserLoaded) {
            fullName = state.user.fullName;
            if (state.user.avatar != null && state.user.avatar!.isNotEmpty) {
              final avatar = state.user.avatar!;
              if (avatar.startsWith('http')) {
                avatarUrl = avatar;
              } else {
                avatarUrl = '${AppConstants.mediaApiBaseUrl}/$avatar';
              }
            }
          }

          // Format name (e.g. only show first name)
          final firstName = fullName.split(' ').first;

          return Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surfaceContainerHighest,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, color: colorScheme.onSurfaceVariant);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Greeting
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Good Morning,',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$firstName!',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          color: colorScheme.onSurfaceVariant,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          color: colorScheme.onSurfaceVariant,
          onPressed: () {},
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              color: colorScheme.onSurfaceVariant,
              onPressed: () {},
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
