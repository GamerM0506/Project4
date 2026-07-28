import 'package:flutter/material.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';

/// Thẻ nhóm trong danh sách. Nhận dữ liệu đã chuẩn hoá sẵn từ page.
class GroupCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final String logoUrl;
  final String members;
  final String location;
  final String description;
  final VoidCallback onJoin;
  final VoidCallback onView;
  final VoidCallback? onCancel;
  final bool isOwner;
  final bool isMember;
  final bool isPending;
  final bool isJoining;

  const GroupCard({
    super.key,
    required this.name,
    required this.coverUrl,
    required this.logoUrl,
    required this.members,
    required this.location,
    required this.description,
    required this.onJoin,
    required this.onView,
    this.onCancel,
    this.isOwner = false,
    this.isMember = false,
    this.isPending = false,
    this.isJoining = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover + avatar chồng lớp
          SizedBox(
            height: 148,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _CoverImage(url: coverUrl),
                ),
                // Gradient mờ dưới để chữ/meta dễ đọc hơn nếu có
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: -18,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: AppAvatar(
                      imageUrl: logoUrl,
                      name: name,
                      radius: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nội dung
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      members,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        location,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _ActionRow(
                  isOwner: isOwner,
                  isMember: isMember,
                  isPending: isPending,
                  isJoining: isJoining,
                  onJoin: onJoin,
                  onView: onView,
                  onCancel: onCancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isOwner,
    required this.isMember,
    required this.isPending,
    required this.isJoining,
    required this.onJoin,
    required this.onView,
    required this.onCancel,
  });

  final bool isOwner;
  final bool isMember;
  final bool isPending;
  final bool isJoining;
  final VoidCallback onJoin;
  final VoidCallback onView;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Nút chính theo vai trò
    final Widget primary = switch ((isOwner, isMember, isPending)) {
      (true, _, _) => AppButton(
          label: 'Quản lý nhóm',
          icon: Icons.settings_rounded,
          variant: AppButtonVariant.tonal,
          onPressed: onView,
          compact: true,
        ),
      (false, true, _) => AppButton(
          label: 'Đã tham gia',
          icon: Icons.check_rounded,
          variant: AppButtonVariant.outline,
          onPressed: onView,
          compact: true,
        ),
      (false, false, true) => AppButton(
          label: 'Huỷ yêu cầu',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.outline,
          loading: isJoining,
          onPressed: onCancel,
          compact: true,
        ),
      _ => AppButton(
          label: 'Tham gia nhóm',
          icon: Icons.group_add_rounded,
          loading: isJoining,
          onPressed: onJoin,
          compact: true,
        ),
    };

    // Owner/member: 1 nút full-width. Khách: 2 nút (chính + xem chi tiết).
    if (isOwner || isMember) {
      return Row(children: [Expanded(child: primary)]);
    }

    return Row(
      children: [
        Expanded(flex: 3, child: primary),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: Theme.of(context).textTheme.labelLarge,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: const Text('Chi tiết'),
          ),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (url.isEmpty) {
      return Container(color: colorScheme.surfaceContainerHigh);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: colorScheme.surfaceContainerHigh,
        child: Icon(
          Icons.image_outlined,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: colorScheme.surfaceContainer);
      },
    );
  }
}
