import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge trạng thái nhỏ (pending/approved/rejected/...), màu theo semantic.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.status, this.label});

  final String status;

  /// Override text hiển thị; mặc định map từ status.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final (Color fg, Color bg, String text) = switch (status) {
      'pending' || 'pending_review' => (
          isDark ? AppColors.warningDark : AppColors.warning,
          isDark ? AppColors.warningContainerDark : AppColors.warningContainer,
          'Chờ duyệt',
        ),
      'approved' || 'active' => (
          isDark ? AppColors.successDark : AppColors.success,
          isDark ? AppColors.successContainerDark : AppColors.successContainer,
          status == 'active' ? 'Hoạt động' : 'Đã duyệt',
        ),
      'accepted' => (
          isDark ? AppColors.infoDark : AppColors.info,
          isDark ? AppColors.infoContainerDark : AppColors.infoContainer,
          'Đã tiếp nhận',
        ),
      'scheduled' => (
          isDark ? AppColors.infoDark : AppColors.info,
          isDark ? AppColors.infoContainerDark : AppColors.infoContainer,
          'Đã hẹn',
        ),
      'received' => (
          isDark ? AppColors.infoDark : AppColors.info,
          isDark ? AppColors.infoContainerDark : AppColors.infoContainer,
          'Đang kiểm tra',
        ),
      'completed' || 'delivered' => (
          isDark ? AppColors.successDark : AppColors.success,
          isDark ? AppColors.successContainerDark : AppColors.successContainer,
          status == 'completed' ? 'Hoàn tất' : 'Đã trao',
        ),
      'in_stock' => (
          isDark ? AppColors.successDark : AppColors.success,
          isDark ? AppColors.successContainerDark : AppColors.successContainer,
          'Trong kho',
        ),
      'listed' => (
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primaryContainer,
          'Đã đăng',
        ),
      'reserved' => (
          isDark ? AppColors.warningDark : AppColors.warning,
          isDark ? AppColors.warningContainerDark : AppColors.warningContainer,
          'Đã giữ',
        ),
      'rejected' || 'banned' || 'suspended' || 'blocked' => (
          Theme.of(context).colorScheme.error,
          Theme.of(context).colorScheme.errorContainer,
          switch (status) {
            'rejected' => 'Bị từ chối',
            'banned' => 'Bị cấm',
            'suspended' => 'Tạm khóa',
            _ => 'Bị chặn',
          },
        ),
      'no_show' => (
          Theme.of(context).colorScheme.error,
          Theme.of(context).colorScheme.errorContainer,
          'Khách bùng',
        ),
      'left' || 'closed' || 'hidden' || 'cancelled' => (
          Theme.of(context).colorScheme.onSurfaceVariant,
          Theme.of(context).colorScheme.surfaceContainerHigh,
          switch (status) {
            'left' => 'Đã rỜi',
            'closed' => 'Đã đóng',
            'cancelled' => 'Đã huỷ',
            _ => 'Đã ẩn',
          },
        ),
      _ => (
          Theme.of(context).colorScheme.onSurfaceVariant,
          Theme.of(context).colorScheme.surfaceContainerHigh,
          status,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: isDark ? 0.6 : 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label ?? text,
        style: textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
