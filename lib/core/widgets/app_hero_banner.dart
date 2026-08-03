import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Số liệu nhỏ dạng viên thuốc nền kính mờ, đặt trên [AppHeroBanner].
class AppHeroStat {
  const AppHeroStat({required this.value, required this.label});

  final String value;
  final String label;
}

/// Banner đầu trang dùng chung: nền brand đậm, slogan, số liệu tổng quan.
///
/// Tồn tại để trang Hội nhóm và trang Đợt quyên góp không mỗi nơi một kiểu —
/// trước đây một bên là nền đỏ có số liệu, bên kia chỉ là chữ đen trên nền
/// trắng, nhìn như hai ứng dụng khác nhau.
///
/// Đặt trong `flexibleSpace` của một [SliverAppBar] có `expandedHeight` và
/// `bottom` cao [bottomBarHeight].
class AppHeroBanner extends StatelessWidget {
  const AppHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.collapsedTitle,
    required this.icon,
    required this.expandedHeight,
    this.stats = const [],
    this.bottomBarHeight = 0,
  });

  /// Slogan hiển thị khi banner mở rộng.
  final String title;

  /// Dòng phụ giải thích slogan.
  final String subtitle;

  /// Tiêu đề ngắn hiện khi đã cuộn thu gọn.
  final String collapsedTitle;

  /// Hình chìm góc phải.
  final IconData icon;

  /// Phải khớp `expandedHeight` của SliverAppBar để tính độ thu gọn.
  final double expandedHeight;

  final List<AppHeroStat> stats;

  /// Chiều cao của `bottom` (thanh lọc/tab) để chừa chỗ, tránh bị che.
  final double bottomBarHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topPad = MediaQuery.paddingOf(context).top;

    // Tự tính độ thu gọn để đổi giữa slogan và tiêu đề ngắn. Dùng `title` của
    // SliverAppBar sẽ bị chồng lên slogan lúc mở rộng.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = expandedHeight + topPad + bottomBarHeight;
        final minH = kToolbarHeight + topPad + bottomBarHeight;
        final t = maxH <= minH
            ? 1.0
            : ((maxH - constraints.maxHeight) / (maxH - minH)).clamp(0.0, 1.0);
        final expandedOpacity = (1 - t * 1.8).clamp(0.0, 1.0);

        return FlexibleSpaceBar(
          // Tiêu đề ngắn khi thu gọn. Dùng title của FlexibleSpaceBar thay vì
          // tự vẽ trong background: Flutter tự đặt đúng vị trí toolbar lúc
          // collapsed và làm mờ dần lúc mở rộng, không bị parallax đè lên.
          title: Text(
            collapsedTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          titlePadding: const EdgeInsetsDirectional.only(
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            bottom: AppSpacing.md + 2,
          ),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  Color.lerp(colors.primary, Colors.black, 0.24)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -18,
                  child: Icon(
                    icon,
                    size: 156,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        topPad + AppSpacing.sm,
                        AppSpacing.lg,
                        bottomBarHeight + AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Số liệu đặt dưới slogan: thông điệp đọc trước, con
                          // số là phần bổ trợ.
                          if (stats.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              // Nhiều viên có thể vượt bề ngang máy hẹp.
                              child: Row(
                                children: [
                                  for (final stat in stats)
                                    _StatPill(stat: stat),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.stat});

  final AppHeroStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 1),
          Text(
            stat.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh lọc ngang đặt ở `bottom` của SliverAppBar có [AppHeroBanner].
///
/// Nền đục để chip không chìm vào banner đỏ, đồng thời tạo ranh giới với
/// danh sách bên dưới.
class AppFilterBar extends StatelessWidget {
  const AppFilterBar({super.key, required this.children});

  static const double height = 52;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        children: [
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: child,
            ),
        ],
      ),
    );
  }
}
