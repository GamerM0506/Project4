import 'package:flutter/material.dart';

/// Avatar mạng có fallback chữ cái đầu khi lỗi/không có ảnh.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name = '',
    this.radius = 24,
  });

  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim()[0].toUpperCase();

    final url = imageUrl?.trim() ?? '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: url.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
              ),
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius,
                      height: radius,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
