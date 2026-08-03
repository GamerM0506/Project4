import 'package:flutter/material.dart';

import '../../../../injection_container.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../data/donation_eligibility.dart';

/// Banner giải thích vì sao chưa quyên góp được, kèm hành động khắc phục.
class DonationGateBanner extends StatelessWidget {
  const DonationGateBanner({
    super.key,
    required this.eligibility,
    this.onJoined,
    this.onRetry,
  });

  final DonationEligibility eligibility;

  /// Gọi sau khi gửi yêu cầu tham gia thành công.
  final VoidCallback? onJoined;

  /// Gọi khi người dùng muốn kiểm tra lại (trường hợp lỗi mạng).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (eligibility.canDonate) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final isBlocking = eligibility.access == DonationAccess.banned ||
        eligibility.access == DonationAccess.groupInactive;
    final tint = isBlocking ? colors.error : colors.primary;
    final bg = isBlocking
        ? colors.errorContainer.withValues(alpha: 0.45)
        : colors.primaryContainer.withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(eligibility.access), size: 20, color: tint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  eligibility.reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (eligibility.canRequestJoin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showJoinGroupSheet(
                  context,
                  groupId: eligibility.group?.id ?? '',
                  groupName: eligibility.groupName,
                  onJoined: onJoined,
                ),
                icon: const Icon(Icons.group_add_rounded, size: 18),
                label: const Text('Tham gia hội nhóm'),
              ),
            ),
          ] else if (eligibility.access == DonationAccess.unknown &&
              onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Kiểm tra lại'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(DonationAccess access) {
    switch (access) {
      case DonationAccess.pending:
        return Icons.hourglass_top_rounded;
      case DonationAccess.banned:
        return Icons.block_rounded;
      case DonationAccess.groupInactive:
        return Icons.pause_circle_outline_rounded;
      case DonationAccess.unknown:
        return Icons.wifi_off_rounded;
      case DonationAccess.notMember:
      case DonationAccess.allowed:
        return Icons.group_add_rounded;
    }
  }
}

/// Bottom sheet xin tham gia hội nhóm ngay tại màn quyên góp.
///
/// Trả về `true` nếu đã gửi yêu cầu thành công.
Future<bool?> showJoinGroupSheet(
  BuildContext context, {
  required String groupId,
  required String groupName,
  VoidCallback? onJoined,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _JoinGroupSheet(
      groupId: groupId,
      groupName: groupName,
      onJoined: onJoined,
    ),
  );
}

class _JoinGroupSheet extends StatefulWidget {
  const _JoinGroupSheet({
    required this.groupId,
    required this.groupName,
    this.onJoined,
  });

  final String groupId;
  final String groupName;
  final VoidCallback? onJoined;

  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.groupId.trim().isEmpty) {
      setState(() => _error = 'Không xác định được hội nhóm.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await sl<GroupRemoteDataSource>().joinGroup(
        widget.groupId,
        message: _message.text.trim().isEmpty ? null : _message.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      widget.onJoined?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu tham gia. Bạn có thể quyên góp sau khi được duyệt.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.group_add_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tham gia hội nhóm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.groupName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hội nhóm cần duyệt thành viên trước khi tiếp nhận quyên góp. '
            'Bạn có thể gửi kèm lời nhắn để được duyệt nhanh hơn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lời nhắn (không bắt buộc)',
              hintText: 'Ví dụ: Mình muốn góp áo ấm cho bà con vùng cao.',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: Text(_sending ? 'Đang gửi...' : 'Gửi yêu cầu tham gia'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
        ],
      ),
    );
  }
}
