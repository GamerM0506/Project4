import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        String fullName = 'Người dùng';
        String avatarUrl = 'https://ui-avatars.com/api/?name=User&background=random';

        if (state is UserLoaded) {
          fullName = state.user.fullName;
          if (state.user.avatar != null && state.user.avatar!.isNotEmpty) {
            final avatar = state.user.avatar!;
            if (avatar.startsWith('http')) {
              avatarUrl = avatar;
            } else {
              avatarUrl = '${AppConstants.mediaApiBaseUrl}/$avatar';
            }
          } else {
            avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=random';
          }
        } else if (state is UserLoading) {
          // Retain layout while loading
        }

        return Column(
          children: [
            // Avatar Container
            GestureDetector(
              onTap: () {
                context.push(AppRoutes.editProfile);
              },
              child: SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Image
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'avatar_hero',
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, size: 60, color: colorScheme.onSurfaceVariant);
                            },
                          ),
                        ),
                      ),
                    ),
                    // Edit Badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              fullName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 36 / 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Trust Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Người dùng uy tín',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
