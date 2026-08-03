import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionItem(
          icon: Icons.volunteer_activism_rounded,
          label: 'Đợt quyên góp',
          color: colorScheme.primary,
          onTap: () => context.go(AppRoutes.campaigns),
        ),
        _ActionItem(
          icon: Icons.groups_rounded,
          label: 'Tìm hội nhóm',
          color: colorScheme.secondary,
          onTap: () => context.go(AppRoutes.groups),
        ),
        _ActionItem(
          icon: Icons.my_location_rounded,
          label: 'Theo dõi',
          color: colorScheme.tertiary,
          onTap: () => context.push(AppRoutes.activity),
        ),
        _ActionItem(
          icon: Icons.card_giftcard_rounded,
          label: 'Đóng góp',
          color: colorScheme.error,
          onTap: () => context.push(AppRoutes.myItems),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.35), color)
        : color;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
