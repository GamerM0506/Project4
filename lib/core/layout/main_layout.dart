import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.secondary.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          onPressed: () {
            // TODO: Navigate to create product page
          },
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _MainBottomAppBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _MainBottomAppBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MainBottomAppBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomAppBar(
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 12.0,
      elevation: 24,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: SizedBox(
        height: 80, // Tăng lên 80 để tránh tuyệt đối lỗi overflow
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Trang chủ',
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront,
              label: 'Gian hàng',
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            const SizedBox(width: 48), // Center FAB Space
            _NavItem(
              icon: Icons.groups_outlined,
              activeIcon: Icons.groups,
              label: 'Hội nhóm',
              index: 2,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Cá nhân',
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // Giảm padding dọc
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? primaryColor : unselectedColor,
                  size: 24, // Giảm kích thước icon từ 26 xuống 24
                ),
              ),
            ),
            const SizedBox(height: 2), // Giảm khoảng cách từ 6 xuống 2
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelSmall!.copyWith(
                color: isSelected ? primaryColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: isSelected ? 12 : 11,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}