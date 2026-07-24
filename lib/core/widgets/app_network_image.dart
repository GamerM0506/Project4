import 'package:flutter/material.dart';

/// Ảnh network dùng chung: placeholder loading, lỗi, URL rỗng, fade-in.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final Color? backgroundColor;
  final Alignment alignment;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
    this.backgroundColor,
    this.alignment = Alignment.center,
  });

  bool get _hasUrl => url != null && url!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colorScheme.surfaceContainerHighest;

    Widget child;
    if (!_hasUrl) {
      child = _Placeholder(
        backgroundColor: bg,
        icon: placeholderIcon,
        iconColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      );
    } else {
      child = Image.network(
        url!.trim(),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, image, progress) {
          if (progress == null) {
            return image;
          }
          final total = progress.expectedTotalBytes;
          final loaded = progress.cumulativeBytesLoaded;
          final value = total != null && total > 0 ? loaded / total : null;
          return _LoadingFrame(
            backgroundColor: bg,
            progress: value,
            color: colorScheme.primary,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _Placeholder(
            backgroundColor: bg,
            icon: Icons.broken_image_outlined,
            iconColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _LoadingFrame(
            backgroundColor: bg,
            progress: null,
            color: colorScheme.primary,
          );
        },
      );
    }

    if (width != null || height != null) {
      child = SizedBox(width: width, height: height, child: child);
    } else {
      child = SizedBox.expand(child: child);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}

class _LoadingFrame extends StatelessWidget {
  final Color backgroundColor;
  final double? progress;
  final Color color;

  const _LoadingFrame({
    required this.backgroundColor,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            value: progress,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  const _Placeholder({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Icon(icon, size: 40, color: iconColor),
      ),
    );
  }
}

/// Gallery ảnh bài viết: 1 / 2 / 3+ layout gọn, bo góc.
class AppImageGallery extends StatelessWidget {
  final List<String> urls;
  final double maxHeight;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const AppImageGallery({
    super.key,
    required this.urls,
    this.maxHeight = 280,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onTap,
  });

  List<String> get _valid =>
      urls.where((u) => u.trim().isNotEmpty).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final images = _valid;
    if (images.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    Widget gallery;
    if (images.length == 1) {
      gallery = SizedBox(
        width: double.infinity,
        height: maxHeight,
        child: AppNetworkImage(
          url: images[0],
          borderRadius: borderRadius,
          fit: BoxFit.cover,
        ),
      );
    } else if (images.length == 2) {
      gallery = SizedBox(
        height: maxHeight * 0.72,
        child: Row(
          children: [
            Expanded(
              child: AppNetworkImage(
                url: images[0],
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius.topLeft,
                  bottomLeft: borderRadius.bottomLeft,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: AppNetworkImage(
                url: images[1],
                borderRadius: BorderRadius.only(
                  topRight: borderRadius.topRight,
                  bottomRight: borderRadius.bottomRight,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final extra = images.length - 3;
      gallery = SizedBox(
        height: maxHeight,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: AppNetworkImage(
                url: images[0],
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius.topLeft,
                  bottomLeft: borderRadius.bottomLeft,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: AppNetworkImage(
                      url: images[1],
                      borderRadius: BorderRadius.only(
                        topRight: borderRadius.topRight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          url: images[2],
                          borderRadius: BorderRadius.only(
                            bottomRight: borderRadius.bottomRight,
                          ),
                        ),
                        if (extra > 0)
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomRight: borderRadius.bottomRight,
                            ),
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Center(
                                child: Text(
                                  '+$extra',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: gallery);
    }
    return gallery;
  }
}
