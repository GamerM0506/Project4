import 'package:flutter/material.dart';

enum AppButtonVariant { primary, tonal, outline, ghost }

/// Nút chuẩn của app: hỗ trợ loading, icon, full-width và 4 variant.
/// Dùng thay cho FilledButton/OutlinedButton dựng tay ở từng trang.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;

  /// true = nút thấp hơn (36) dùng trong card/toolbar.
  final bool compact;

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final height = compact ? 38.0 : 48.0;
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 14 : 20,
    );

    final spinnerColor = switch (variant) {
      AppButtonVariant.primary => colorScheme.onPrimary,
      AppButtonVariant.tonal => colorScheme.onSecondaryContainer,
      AppButtonVariant.outline || AppButtonVariant.ghost => colorScheme.primary,
    };

    final Widget child = loading
        ? SizedBox(
            width: compact ? 16 : 20,
            height: compact ? 16 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 16 : 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          );

    final onTap = _disabled ? null : onPressed;

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, height),
            padding: padding,
          ),
          child: child,
        ),
      AppButtonVariant.tonal => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, height),
            padding: padding,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, height),
            padding: padding,
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: Size(0, height),
            padding: padding,
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
