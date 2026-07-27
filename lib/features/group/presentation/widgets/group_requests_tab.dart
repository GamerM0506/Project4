import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../injection_container.dart';
import '../../../chat/presentation/utils/open_context_conversation.dart';
import '../../../marketplace/domain/entities/request_entity.dart';
import '../cubit/group_requests_cubit.dart';
import '../cubit/group_requests_state.dart';

class GroupRequestsTab extends StatelessWidget {
  final String groupId;

  const GroupRequestsTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupRequestsCubit>()..fetchRequests(groupId),
      child: BlocConsumer<GroupRequestsCubit, GroupRequestsState>(
        listener: (context, state) {
          if (state is GroupRequestsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionError!)));
          }
        },
        builder: (context, state) {
          if (state is GroupRequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GroupRequestsError) {
            return Center(child: Text(state.message));
          } else if (state is GroupRequestsLoaded) {
            if (state.requests.isEmpty) {
              return const Center(child: Text('Không có đơn xin đồ nào.'));
            }
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<GroupRequestsCubit>().fetchRequests(groupId),
              child: ListView.builder(
                itemCount: state.requests.length,
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  return _RequestCard(
                    groupId: groupId,
                    request: request,
                    receiverName:
                        state.userNames[request.receiverId] ?? 'Người dùng',
                    listingTitle:
                        state.listingTitles[request.listingId] ?? 'Vật phẩm',
                    isProcessing: state.processingId == request.id,
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String groupId;
  final RequestEntity request;
  final String receiverName;
  final String listingTitle;
  final bool isProcessing;

  const _RequestCard({
    required this.groupId,
    required this.request,
    required this.receiverName,
    required this.listingTitle,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String statusText;
    Color statusColor;
    switch (request.status) {
      case 'pending':
        statusText = 'Chờ duyệt';
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusText = 'Đã duyệt';
        statusColor = Colors.blue;
        break;
      case 'scheduled':
        statusText = 'Đã hẹn ngày';
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusText = 'Đã hoàn tất';
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusText = 'Đã từ chối';
        statusColor = Colors.red;
        break;
      case 'cancelled':
        statusText = 'Đã huỷ';
        statusColor = Colors.grey;
        break;
      case 'no_show':
        statusText = 'Khách bùng';
        statusColor = Colors.black54;
        break;
      default:
        statusText = request.status;
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Món đồ: $listingTitle',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  receiverName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mã đơn: ${request.code.isEmpty ? request.id : request.code} '
              '| Số lượng: ${request.quantity}',
            ),
            const SizedBox(height: 4),
            Text(
              'Lý do: ${request.reason}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              timeago.format(request.createdAt, locale: 'vi'),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (request.status != 'pending' &&
                request.status != 'rejected') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => openContextConversation(
                  context,
                  contextType: 'request',
                  contextId: request.id,
                  groupId: groupId,
                  name: receiverName,
                  asGroup: true,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Nhắn tin người nhận'),
              ),
            ],
            if (request.status == 'pending') ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isProcessing ? null : () => _reject(context),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () {
                            context.read<GroupRequestsCubit>().approveRequest(
                              groupId,
                              request.id,
                            );
                          },
                    child: const Text('Duyệt'),
                  ),
                ],
              ),
            ] else if (request.status == 'approved' ||
                request.status == 'scheduled') ...[
              const Divider(),
              Wrap(
                spacing: 8,
                children: [
                  if (request.status == 'approved')
                    OutlinedButton(
                      onPressed: isProcessing ? null : () => _schedule(context),
                      child: const Text('Hẹn lịch nhận'),
                    ),
                  ElevatedButton(
                    onPressed: isProcessing ? null : () => _complete(context),
                    child: const Text('Đã giao xong'),
                  ),
                  OutlinedButton(
                    onPressed: isProcessing
                        ? null
                        : () => context
                              .read<GroupRequestsCubit>()
                              .noShowRequest(groupId, request.id),
                    child: const Text('Không đến nhận'),
                  ),
                ],
              ),
            ],
            if (request.status == 'completed') ...[
              const Divider(),
              TextButton(
                onPressed: () => _confirmation(context),
                child: const Text('Xem biên nhận'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await _textInput(
      context,
      title: 'Từ chối yêu cầu',
      label: 'Lý do từ chối',
    );
    if (reason != null && context.mounted) {
      context.read<GroupRequestsCubit>().rejectRequest(
        groupId,
        request.id,
        reason,
      );
    }
  }

  Future<void> _schedule(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !context.mounted) return;
    context.read<GroupRequestsCubit>().scheduleRequest(
      groupId,
      request.id,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final values = await _completionDialog(context);
    if (values != null && context.mounted) {
      context.read<GroupRequestsCubit>().completeRequest(
        groupId,
        request.id,
        values.$1,
        photoUrl: values.$2,
        note: values.$3,
      );
    }
  }

  Future<void> _confirmation(BuildContext context) async {
    final message = await context.read<GroupRequestsCubit>().confirmation(
      request.id,
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biên nhận giao đồ'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

Future<String?> _textInput(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<(String, String?, String?)?> _completionDialog(
  BuildContext context,
) async {
  final qr = TextEditingController();
  final photo = TextEditingController();
  final note = TextEditingController();
  final result = await showDialog<(String, String?, String?)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận đã giao'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qr,
              decoration: const InputDecoration(labelText: 'QR token *'),
            ),
            TextField(
              controller: photo,
              decoration: const InputDecoration(labelText: 'URL ảnh giao nhận'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (qr.text.trim().isEmpty) return;
            Navigator.pop(context, (
              qr.text.trim(),
              photo.text.trim().isEmpty ? null : photo.text.trim(),
              note.text.trim().isEmpty ? null : note.text.trim(),
            ));
          },
          child: const Text('Hoàn tất'),
        ),
      ],
    ),
  );
  qr.dispose();
  photo.dispose();
  note.dispose();
  return result;
}
