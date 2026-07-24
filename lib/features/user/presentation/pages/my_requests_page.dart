import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';
import '../../../marketplace/domain/entities/request_entity.dart';
import '../../../marketplace/presentation/cubit/my_requests_cubit.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyRequestsCubit(
        getRequestsUseCase: sl(),
        prefs: sl(),
      )..load(),
      child: const _MyRequestsView(),
    );
  }
}

class _MyRequestsView extends StatelessWidget {
  const _MyRequestsView();

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Đang chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'scheduled':
        return 'Đã hẹn lịch';
      case 'completed':
        return 'Đã trao tặng';
      case 'cancelled':
        return 'Đã hủy';
      case 'no_show':
        return 'Không đến nhận';
      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'scheduled':
        return Colors.green;
      case 'completed':
        return cs.primary;
      case 'rejected':
      case 'cancelled':
      case 'no_show':
        return cs.error;
      default:
        return Colors.orange;
    }
  }

  void _showQr(BuildContext context, RequestEntity request) {
    // Backend stores qr_token on complete; receiver shows request id for mod to confirm.
    final token =
        (request.qrToken != null && request.qrToken!.isNotEmpty)
            ? request.qrToken!
            : request.id;
    if (token.isEmpty) return;

    final status = request.status.toLowerCase();
    if (!['approved', 'scheduled', 'completed'].contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã QR chỉ hiện sau khi nhóm duyệt yêu cầu.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mã QR nhận đồ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: token,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            SelectableText(
              token,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Đưa mã này cho người của hội nhóm khi nhận đồ.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu của tôi'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<MyRequestsCubit, MyRequestsState>(
        builder: (context, state) {
          if (state.isLoading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.read<MyRequestsCubit>().load(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có yêu cầu nhận đồ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.marketplace),
                    child: const Text('Xem gian hàng'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<MyRequestsCubit>().load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final item = state.requests[index];
                final color = _statusColor(context, item.status);
                final showQr = ['approved', 'scheduled', 'completed']
                    .contains(item.status.toLowerCase());

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      if (item.listingId.isNotEmpty) {
                        context.push(
                            '${AppRoutes.marketplace}/detail/${item.listingId}');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.volunteer_activism,
                                color: colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.reason.isNotEmpty
                                      ? item.reason
                                      : 'Yêu cầu #${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SL: ${item.quantity} · ${_formatDate(item.createdAt)}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _statusLabel(item.status),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (showQr) ...[
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showQr(context, item),
                                        icon: const Icon(Icons.qr_code, size: 18),
                                        label: const Text('QR'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
