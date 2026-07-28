import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../../chat/presentation/utils/open_context_conversation.dart';
import '../../../marketplace/domain/entities/request_entity.dart';
import '../../../marketplace/presentation/cubit/my_requests_cubit.dart';
import '../../../marketplace/presentation/cubit/my_requests_state.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyRequestsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yêu cầu của tôi'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Cập nhật trạng thái',
                onPressed: () => context.read<MyRequestsCubit>().load(),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ],
        ),
        body: BlocConsumer<MyRequestsCubit, MyRequestsState>(
          listener: (context, state) {
            if (state.error != null && state.requests.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.requests.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && state.requests.isEmpty) {
              return Center(
                child: FilledButton.icon(
                  onPressed: context.read<MyRequestsCubit>().load,
                  icon: const Icon(Icons.refresh),
                  label: Text(state.error!),
                ),
              );
            }
            if (state.requests.isEmpty) {
              return RefreshIndicator(
                onRefresh: context.read<MyRequestsCubit>().load,
                child: ListView(
                  children: const [
                    SizedBox(height: 180),
                    Icon(Icons.inbox_outlined, size: 56),
                    SizedBox(height: 12),
                    Center(child: Text('Bạn chưa gửi yêu cầu nhận đồ nào.')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: context.read<MyRequestsCubit>().load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: state.requests.length,
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  return _RequestCard(
                    request: request,
                    title: state.listingTitles[request.listingId] ?? 'Vật phẩm',
                    isProcessing: state.processingId == request.id,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestEntity request;
  final String title;
  final bool isProcessing;

  const _RequestCard({
    required this.request,
    required this.title,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canCancel = const {
      'pending',
      'approved',
      'scheduled',
    }.contains(request.status);
    final canChat = const {
      'approved',
      'scheduled',
      'completed',
    }.contains(request.status);
    final canShowQr = const {'approved', 'scheduled'}.contains(request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.code.isEmpty ? request.id : request.code,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.layers_outlined,
                  text: 'Số lượng ${request.quantity}',
                ),
                if (request.scheduledAt != null)
                  _InfoPill(
                    icon: Icons.event_outlined,
                    text: _date(request.scheduledAt!),
                  ),
              ],
            ),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Lý do: ${request.reason}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
            if (request.rejectReason?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Lý do từ chối: ${request.rejectReason}',
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Tiến trình nhận đồ',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _RequestTimeline(request: request),
            const SizedBox(height: 14),
            _QrStatusPanel(
              request: request,
              onShowQr: () => _showRequestQr(context),
            ),
            if (canCancel || canChat || canShowQr) ...[
              const SizedBox(height: 8),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request.status == 'completed')
                    FilledButton.tonalIcon(
                      onPressed: () => _confirmReceived(context),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Xác nhận đã nhận'),
                    ),
                  if (canChat)
                    FilledButton.tonalIcon(
                      onPressed: () => openContextConversation(
                        context,
                        contextType: 'request',
                        contextId: request.id,
                        groupId: request.groupId,
                        name: title,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Nhắn tin với nhóm'),
                    ),
                  if (canCancel)
                    OutlinedButton(
                      onPressed: isProcessing
                          ? null
                          : () => context.read<MyRequestsCubit>().cancel(
                              request.id,
                            ),
                      child: isProcessing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Hủy'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReceived(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null || !context.mounted) return;
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đã nhận đồ'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Ghi chú (không bắt buộc)',
            hintText: 'Ví dụ: Đã nhận đủ và đúng tình trạng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: const Text('Gửi xác nhận'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !context.mounted) return;
    final error = await context.read<MyRequestsCubit>().confirmReceived(
      request.id,
      await image.readAsBytes(),
      'image/jpeg',
      note,
    );
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _showRequestQr(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã QR nhận đồ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: request.code,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              semanticsLabel: 'QR yêu cầu ${request.code}',
            ),
            const SizedBox(height: 14),
            SelectableText(
              request.code,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đưa mã này cho moderator quét khi bạn nhận đồ.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

class _QrStatusPanel extends StatelessWidget {
  final RequestEntity request;
  final VoidCallback onShowQr;

  const _QrStatusPanel({required this.request, required this.onShowQr});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isReady = const {'approved', 'scheduled'}.contains(request.status);
    final isCompleted = request.status == 'completed';
    final isPending = request.status == 'pending';
    final title = isReady
        ? 'QR nhận đồ đã sẵn sàng'
        : isCompleted
        ? 'QR đã được xác nhận'
        : isPending
        ? 'QR đang chờ mở khóa'
        : 'QR không còn hiệu lực';
    final detail = isReady
        ? 'Mở mã này tại điểm hẹn để moderator quét.'
        : isCompleted
        ? 'Món đồ đã được bàn giao thành công.'
        : isPending
        ? 'QR sẽ xuất hiện ngay sau khi nhóm duyệt yêu cầu.'
        : 'Yêu cầu đã kết thúc nên không thể sử dụng QR.';
    final foreground = isReady
        ? colorScheme.onSecondaryContainer
        : isCompleted
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    final background = isReady || isCompleted
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted
                  ? Icons.verified_outlined
                  : isReady
                  ? Icons.qr_code_2
                  : Icons.lock_outline,
              color: foreground,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (isReady)
            FilledButton(
              onPressed: request.code.trim().isEmpty ? null : onShowQr,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 13),
              ),
              child: const Text('Mở QR'),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = const {'rejected', 'cancelled', 'no_show'}.contains(status);
    final isDone = status == 'completed';
    final background = isError
        ? colorScheme.errorContainer
        : isDone
        ? colorScheme.secondaryContainer
        : colorScheme.tertiaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : isDone
        ? colorScheme.onSecondaryContainer
        : colorScheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTimeline extends StatelessWidget {
  final RequestEntity request;

  const _RequestTimeline({required this.request});

  @override
  Widget build(BuildContext context) {
    final steps = _timelineSteps(request);
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          _TimelineRow(step: steps[index], isLast: index == steps.length - 1),
      ],
    );
  }
}

enum _StepState { done, current, upcoming, failed }

class _TimelineData {
  final String title;
  final String detail;
  final DateTime? time;
  final IconData icon;
  final _StepState state;

  const _TimelineData({
    required this.title,
    required this.detail,
    required this.icon,
    required this.state,
    this.time,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineData step;
  final bool isLast;

  const _TimelineRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (step.state) {
      _StepState.done => colorScheme.secondary,
      _StepState.current => colorScheme.primary,
      _StepState.failed => colorScheme.error,
      _StepState.upcoming => colorScheme.outline,
    };
    final filled = step.state != _StepState.upcoming;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: filled ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    step.icon,
                    size: 15,
                    color: filled ? Colors.white : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.state == _StepState.done
                          ? colorScheme.secondary
                          : colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: step.state == _StepState.upcoming
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.detail,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (step.time != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _date(step.time!),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_TimelineData> _timelineSteps(RequestEntity request) {
  final isTerminal = const {
    'rejected',
    'cancelled',
    'no_show',
  }.contains(request.status);
  final hasApproval =
      request.reviewedAt != null && request.status != 'rejected';
  final hasSchedule = request.scheduledAt != null;
  final steps = <_TimelineData>[
    _TimelineData(
      title: 'Đã gửi yêu cầu',
      detail: 'Yêu cầu đã được gửi tới hội nhóm',
      time: request.createdAt,
      icon: Icons.send_outlined,
      state: _StepState.done,
    ),
  ];

  if (request.status == 'rejected') {
    steps.add(
      _TimelineData(
        title: 'Nhóm đã từ chối',
        detail: request.rejectReason ?? 'Yêu cầu không được chấp nhận',
        time: request.reviewedAt ?? request.updatedAt,
        icon: Icons.close,
        state: _StepState.failed,
      ),
    );
    return steps;
  }

  steps.add(
    _TimelineData(
      title: 'Nhóm duyệt yêu cầu',
      detail: request.status == 'pending'
          ? 'Đang chờ owner/moderator xem xét'
          : 'Yêu cầu đã được chấp nhận',
      time: hasApproval ? request.reviewedAt : null,
      icon: hasApproval ? Icons.check : Icons.hourglass_empty,
      state: hasApproval
          ? _StepState.done
          : request.status == 'pending'
          ? _StepState.current
          : _StepState.upcoming,
    ),
  );
  if (request.status == 'cancelled') {
    steps.add(_terminalStep('Yêu cầu đã hủy', request, Icons.cancel_outlined));
    return steps;
  }

  steps.add(
    _TimelineData(
      title: 'Hẹn lịch nhận đồ',
      detail: request.status == 'approved'
          ? 'Nhóm đang sắp xếp thời gian bàn giao'
          : 'Chờ nhóm đặt lịch nhận đồ',
      time: hasSchedule ? request.scheduledAt : null,
      icon: Icons.event_outlined,
      state: hasSchedule
          ? _StepState.done
          : request.status == 'approved'
          ? _StepState.current
          : _StepState.upcoming,
    ),
  );
  if (request.status == 'no_show') {
    steps.add(
      _terminalStep('Không đến nhận đồ', request, Icons.person_off_outlined),
    );
    return steps;
  }
  if (isTerminal) return steps;

  steps.add(
    _TimelineData(
      title: 'Hoàn tất nhận đồ',
      detail: request.status == 'scheduled'
          ? 'Mang QR tới điểm hẹn để moderator xác nhận'
          : 'Hoàn tất sau khi quét QR bàn giao',
      time: request.completedAt,
      icon: request.status == 'completed'
          ? Icons.redeem
          : Icons.qr_code_scanner,
      state: request.status == 'completed'
          ? _StepState.done
          : request.status == 'scheduled'
          ? _StepState.current
          : _StepState.upcoming,
    ),
  );
  return steps;
}

_TimelineData _terminalStep(
  String title,
  RequestEntity request,
  IconData icon,
) => _TimelineData(
  title: title,
  detail: 'Tiến trình nhận đồ đã kết thúc',
  time: request.updatedAt,
  icon: icon,
  state: _StepState.failed,
);

String _statusLabel(String status) => switch (status) {
  'pending' => 'Chờ duyệt',
  'approved' => 'Đã duyệt',
  'rejected' => 'Đã từ chối',
  'scheduled' => 'Đã hẹn',
  'completed' => 'Đã nhận',
  'cancelled' => 'Đã hủy',
  'no_show' => 'Không đến nhận',
  _ => status,
};

String _date(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
