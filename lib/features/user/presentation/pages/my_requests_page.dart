import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
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
                padding: const EdgeInsets.all(16),
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
    final canCancel = const {
      'pending',
      'approved',
      'scheduled',
    }.contains(request.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(_statusLabel(request.status))),
              ],
            ),
            Text('Mã: ${request.code.isEmpty ? request.id : request.code}'),
            Text('Số lượng: ${request.quantity}'),
            if (request.reason.isNotEmpty) Text('Lý do: ${request.reason}'),
            if (request.rejectReason?.isNotEmpty ?? false)
              Text('Lý do từ chối: ${request.rejectReason}'),
            if (request.scheduledAt != null)
              Text('Lịch nhận: ${_date(request.scheduledAt!)}'),
            Text('Ngày gửi: ${_date(request.createdAt)}'),
            if (canCancel) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: isProcessing
                      ? null
                      : () =>
                            context.read<MyRequestsCubit>().cancel(request.id),
                  child: isProcessing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Hủy yêu cầu'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
