import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../marketplace/domain/entities/request_entity.dart';
import '../../../marketplace/presentation/cubit/group_requests_cubit.dart';
import '../../data/models/group_model.dart';

class GroupDashboardRequests extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardRequests({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupRequestsCubit(
        getRequestsUseCase: sl(),
        approveRequestUseCase: sl(),
        rejectRequestUseCase: sl(),
        completeRequestUseCase: sl(),
        prefs: sl(),
      )..load(group.id),
      child: _GroupRequestsView(groupId: group.id),
    );
  }
}

class _GroupRequestsView extends StatelessWidget {
  final String groupId;

  const _GroupRequestsView({required this.groupId});

  String _label(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'scheduled':
        return 'Đã hẹn';
      case 'completed':
        return 'Hoàn tất';
      case 'rejected':
        return 'Từ chối';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _color(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'scheduled':
        return Colors.green;
      case 'completed':
        return cs.primary;
      case 'rejected':
      case 'cancelled':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  Future<void> _rejectDialog(BuildContext context, RequestEntity r) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Lý do',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Từ chối')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final reason =
          controller.text.trim().isEmpty ? 'Không phù hợp' : controller.text.trim();
      await context.read<GroupRequestsCubit>().reject(r.id, reason);
    }
  }

  Future<void> _completeDialog(BuildContext context, RequestEntity r) async {
    final qrController = TextEditingController(text: r.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận trao tặng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập mã QR từ người nhận (mặc định: mã yêu cầu).',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qrController,
              decoration: const InputDecoration(
                labelText: 'Mã QR / Request ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hoàn tất')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<GroupRequestsCubit>().complete(
            requestId: r.id,
            qrToken: qrController.text.trim().isEmpty ? r.id : qrController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<GroupRequestsCubit, GroupRequestsState>(
      listener: (context, state) {
        if (state.actionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: colorScheme.error,
            ),
          );
        } else if (state.actionSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionSuccess!)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Yêu cầu nhận đồ',
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<GroupRequestsCubit>().load(groupId),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.requests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.requests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(state.error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => context
                                      .read<GroupRequestsCubit>()
                                      .load(groupId),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : state.requests.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có yêu cầu nhận đồ',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => context
                                  .read<GroupRequestsCubit>()
                                  .load(groupId),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.requests.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final r = state.requests[index];
                                  final busy = state.actionId == r.id;
                                  final statusColor = _color(context, r.status);
                                  final pending =
                                      r.status.toLowerCase() == 'pending';
                                  final canComplete = [
                                    'approved',
                                    'scheduled',
                                  ].contains(r.status.toLowerCase());

                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  r.reason.isNotEmpty
                                                      ? r.reason
                                                      : 'Yêu cầu #${r.id.length > 8 ? r.id.substring(0, 8) : r.id}',
                                                  style: textTheme.titleSmall
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                      alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _label(r.status),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'SL: ${r.quantity} · Người nhận: ${r.receiverId.length > 8 ? r.receiverId.substring(0, 8) : r.receiverId}…',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                          ),
                                          if (pending || canComplete) ...[
                                            const SizedBox(height: 12),
                                            if (busy)
                                              const LinearProgressIndicator()
                                            else
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  if (pending) ...[
                                                    FilledButton(
                                                      onPressed: () => context
                                                          .read<
                                                              GroupRequestsCubit>()
                                                          .approve(r.id),
                                                      child:
                                                          const Text('Duyệt'),
                                                    ),
                                                    OutlinedButton(
                                                      onPressed: () =>
                                                          _rejectDialog(
                                                              context, r),
                                                      child:
                                                          const Text('Từ chối'),
                                                    ),
                                                  ],
                                                  if (canComplete)
                                                    FilledButton.tonal(
                                                      onPressed: () =>
                                                          _completeDialog(
                                                              context, r),
                                                      child: const Text(
                                                          'Trao tặng (QR)'),
                                                    ),
                                                ],
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}
