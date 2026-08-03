import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../injection_container.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../data/models/group_model.dart';

/// Băng chuyền hội nhóm nổi bật ở trang chủ.
///
/// Dùng [PageView] thay cho [ListView] ngang để thẻ tự bám mép khi vuốt, kèm
/// chấm chỉ vị trí — người dùng biết còn nhóm phía sau để xem tiếp.
class HomeFeaturedGroups extends StatefulWidget {
  const HomeFeaturedGroups({super.key, required this.groups, this.onJoined});

  final List<GroupModel> groups;

  /// Báo cho trang chủ biết đã gửi yêu cầu tham gia, để đồng bộ trạng thái.
  final ValueChanged<String>? onJoined;

  @override
  State<HomeFeaturedGroups> createState() => _HomeFeaturedGroupsState();
}

class _HomeFeaturedGroupsState extends State<HomeFeaturedGroups> {
  // Chừa mép để thấy hé thẻ kế bên — gợi ý rằng còn vuốt được.
  late final PageController _controller = PageController(viewportFraction: 0.87);
  int _page = 0;

  /// Nhóm vừa gửi yêu cầu trong phiên này. Giữ ở local để nút đổi trạng thái
  /// ngay, không phải chờ tải lại cả trang chủ.
  final Set<String> _requested = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markRequested(String groupId) {
    setState(() => _requested.add(groupId));
    widget.onJoined?.call(groupId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 268,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            // Cho phép vuốt cả khi chỉ có vài thẻ, và bắt cử chỉ trên toàn bộ
            // vùng thẻ kể cả khoảng trống giữa các phần tử.
            physics: const ClampingScrollPhysics(),
            dragStartBehavior: DragStartBehavior.down,
            itemCount: widget.groups.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final group = widget.groups[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? AppSpacing.lg : AppSpacing.sm,
                  right: index == widget.groups.length - 1
                      ? AppSpacing.lg
                      : AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: _GroupCard(
                  group: group,
                  justRequested: _requested.contains(group.id),
                  onRequested: () => _markRequested(group.id),
                ),
              );
            },
          ),
        ),
        if (widget.groups.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _PageDots(count: widget.groups.length, active: _page),
        ],
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == active;
        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: selected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: 0.8),
            borderRadius: AppRadius.brPill,
          ),
        );
      }),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.justRequested,
    required this.onRequested,
  });

  final GroupModel group;
  final bool justRequested;
  final VoidCallback onRequested;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppSurface(
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      clip: true,
      onTap: () => context.push('${AppRoutes.groupDetail}/${group.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverBanner(group: group),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        group.location,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.people_alt_rounded,
                      size: 13,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${group.memberCount}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Chiều cao cố định để mọi thẻ bằng nhau dù mô tả dài ngắn khác nhau.
                SizedBox(
                  height: 34,
                  child: Text(
                    group.description ?? 'Hội nhóm chưa có lời giới thiệu.',
                    style: textTheme.bodySmall?.copyWith(
                      color: group.description == null
                          ? colors.onSurfaceVariant.withValues(alpha: 0.7)
                          : colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _JoinButton(
                  group: group,
                  justRequested: justRequested,
                  onRequested: onRequested,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh bìa + avatar chồng lên, có lớp phủ tối để avatar luôn nổi trên mọi ảnh.
class _CoverBanner extends StatelessWidget {
  const _CoverBanner({required this.group});

  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cover = group.coverUrl ?? group.imageUrl;

    return SizedBox(
      height: 92,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover != null)
            Image.network(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _GradientCover(colors: colors),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : _GradientCover(colors: colors),
            )
          else
            _GradientCover(colors: colors),
          // Tối dần về phía dưới để chữ và avatar không chìm vào ảnh sáng.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceContainerLowest,
              ),
              child: AppAvatar(
                imageUrl: group.imageUrl,
                name: group.name,
                radius: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

/// Nút hành động đổi theo quan hệ giữa người xem và nhóm.
class _JoinButton extends StatefulWidget {
  const _JoinButton({
    required this.group,
    required this.justRequested,
    required this.onRequested,
  });

  final GroupModel group;
  final bool justRequested;
  final VoidCallback onRequested;

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _sending = false;

  Future<void> _join() async {
    setState(() => _sending = true);
    try {
      await sl<GroupRemoteDataSource>().joinGroup(widget.group.id);
      if (!mounted) return;
      widget.onRequested();
      context.showSuccessSnack(
        'Đã gửi yêu cầu tham gia "${widget.group.name}".',
      );
    } catch (error) {
      if (!mounted) return;
      context.showErrorSnack(
        error.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final pending = group.isPending || widget.justRequested;

    if (group.isMember) {
      return _OutlinedAction(
        icon: Icons.check_circle_outline_rounded,
        label: 'Đã tham gia',
        onPressed: () =>
            context.push('${AppRoutes.groupDetail}/${group.id}'),
      );
    }
    if (pending) {
      return _OutlinedAction(
        icon: Icons.hourglass_top_rounded,
        label: 'Đang chờ duyệt',
        onPressed: null,
      );
    }
    if (!group.canRequestJoin) {
      return _OutlinedAction(
        icon: Icons.visibility_outlined,
        label: 'Xem hội nhóm',
        onPressed: () =>
            context.push('${AppRoutes.groupDetail}/${group.id}'),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightCompact,
      child: FilledButton.icon(
        onPressed: _sending ? null : _join,
        icon: _sending
            ? const AppInlineSpinner(size: 15)
            : const Icon(Icons.group_add_rounded, size: 17),
        label: Text(_sending ? 'Đang gửi...' : 'Tham gia'),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightCompact,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),
    );
  }
}
