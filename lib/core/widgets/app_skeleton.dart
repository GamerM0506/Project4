import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Khối skeleton có shimmer, dùng cho placeholder lúc loading.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
        );
  }
}

/// Preset skeleton hình card trong danh sách (cover + 3 dòng chữ).
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton(height: 140, radius: 0),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(height: 18, width: 180),
                SizedBox(height: 10),
                AppSkeleton(height: 12, width: 240),
                SizedBox(height: 6),
                AppSkeleton(height: 12, width: 140),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: AppSkeleton(height: 44, radius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: AppSkeleton(height: 44, radius: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
