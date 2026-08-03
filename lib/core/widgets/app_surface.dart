import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Bề mặt chứa nội dung dùng chung — thay cho `Container` + `BoxDecoration`
/// dựng thủ công (khảo sát đếm được 135 chỗ, mỗi chỗ một kiểu bo góc và viền).
///
/// Mặc định là thẻ viền mảnh trên nền nổi nhẹ, khớp với `cardTheme`.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.radius = AppRadius.lg,
    this.onTap,
    this.tone = AppSurfaceTone.card,
    this.border = true,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final AppSurfaceTone tone;
  final bool border;

  /// Bật khi bên trong có ảnh cần cắt theo góc bo.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);

    final content = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        color: switch (tone) {
          AppSurfaceTone.card => colors.surfaceContainerLowest,
          AppSurfaceTone.muted => colors.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          AppSurfaceTone.primary => colors.primaryContainer.withValues(
            alpha: 0.45,
          ),
          AppSurfaceTone.error => colors.errorContainer.withValues(alpha: 0.5),
        },
        borderRadius: borderRadius,
        border: border
            ? Border.all(color: colors.outlineVariant.withValues(alpha: 0.5))
            : null,
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: content,
              ),
            ),
    );
  }
}

enum AppSurfaceTone {
  /// Thẻ nội dung tiêu chuẩn.
  card,

  /// Nền chìm, dùng cho ô nhập hoặc vùng phụ.
  muted,

  /// Nhấn mạnh tích cực: gợi ý bước tiếp theo.
  primary,

  /// Cảnh báo, lỗi.
  error,
}

/// Khối thông tin một dòng có icon — thay cho các `_InfoBanner` viết lại ở
/// từng file.
class AppNote extends StatelessWidget {
  const AppNote({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = AppNoteTone.info,
  });

  final String message;
  final IconData icon;
  final AppNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      AppNoteTone.info => (
        colors.secondaryContainer.withValues(alpha: 0.5),
        colors.onSecondaryContainer,
      ),
      AppNoteTone.primary => (
        colors.primaryContainer.withValues(alpha: 0.45),
        colors.onPrimaryContainer,
      ),
      AppNoteTone.error => (
        colors.errorContainer.withValues(alpha: 0.5),
        colors.onErrorContainer,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm + 2, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

enum AppNoteTone { info, primary, error }

/// Tiêu đề một nhóm nội dung, kèm hành động tuỳ chọn ở bên phải.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSizes.iconSm, color: colors.primary),
          const SizedBox(width: AppSpacing.xs + 2),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Vòng quay chờ đặt giữa màn — thay cho 59 chỗ gọi
/// `Center(child: CircularProgressIndicator())` rời rạc.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vòng quay nhỏ đặt trong nút hoặc cạnh chữ.
class AppInlineSpinner extends StatelessWidget {
  const AppInlineSpinner({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// Thông báo nhanh thống nhất — thay cho 58 chỗ tự dựng `SnackBar`, trong đó
/// nhiều chỗ dùng `Colors.red` nên hỏng ở chế độ tối.
extension AppSnack on BuildContext {
  void showSnack(String message) => _snack(this, message, _SnackTone.neutral);

  void showSuccessSnack(String message) =>
      _snack(this, message, _SnackTone.success);

  void showErrorSnack(String message) =>
      _snack(this, message, _SnackTone.error);
}

enum _SnackTone { neutral, success, error }

void _snack(BuildContext context, String message, _SnackTone tone) {
  final colors = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            switch (tone) {
              _SnackTone.success => Icons.check_circle_outline_rounded,
              _SnackTone.error => Icons.error_outline_rounded,
              _SnackTone.neutral => Icons.info_outline_rounded,
            },
            size: AppSizes.iconMd,
            color: tone == _SnackTone.error
                ? colors.onError
                : colors.onInverseSurface,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: tone == _SnackTone.error ? colors.error : null,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: tone == _SnackTone.error ? 5 : 3),
    ),
  );
}
