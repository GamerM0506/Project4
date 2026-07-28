import 'package:flutter/material.dart';

/// Card chuẩn: nền surfaceContainerLowest, viền outlineVariant, radius 20.
/// [elevated] = true dùng soft shadow thay viền (cho hero card).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = 20,
    this.elevated = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final bool elevated;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final decoration = BoxDecoration(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: elevated
          ? null
          : Border.all(color: colorScheme.outlineVariant),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: decoration,
            child: content,
          ),
        ),
      ),
    );
  }
}
