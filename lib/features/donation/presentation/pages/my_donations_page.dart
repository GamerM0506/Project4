import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../cubit/my_donations_cubit.dart';

class MyDonationsPage extends StatelessWidget {
  const MyDonationsPage({super.key});

  String _label(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'accepted':
        return 'Nhóm đã nhận';
      case 'scheduled':
        return 'Đã hẹn lịch';
      case 'received':
        return 'Đã giao đồ';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => MyDonationsCubit(getDonationsUseCase: sl())..load(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quyên góp của tôi'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<MyDonationsCubit, MyDonationsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.read<MyDonationsCubit>().load(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (state.donations.isEmpty) {
              return Center(
                child: Text(
                  'Bạn chưa có đơn quyên góp',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<MyDonationsCubit>().load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.donations.length,
                itemBuilder: (context, index) {
                  final d = state.donations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.volunteer_activism,
                            color: colorScheme.onPrimaryContainer),
                      ),
                      title: Text(
                        d.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${d.code.isNotEmpty ? d.code : d.id.substring(0, d.id.length.clamp(0, 8))} · ${_label(d.status)}\n${d.items.length} món',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/donations/${d.id}');
                      },
                    ),
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
