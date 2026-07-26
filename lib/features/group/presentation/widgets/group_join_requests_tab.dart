import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../injection_container.dart';
import '../cubit/group_join_requests_cubit.dart';
import '../cubit/group_join_requests_state.dart';

class GroupJoinRequestsTab extends StatelessWidget {
  final String groupId;

  const GroupJoinRequestsTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<GroupJoinRequestsCubit>()
            ..fetchRequests(groupId, status: 'pending'),
      child: BlocConsumer<GroupJoinRequestsCubit, GroupJoinRequestsState>(
        listener: (context, state) {
          if (state is GroupJoinRequestsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is GroupJoinRequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupJoinRequestsLoaded) {
            final requests = state.requests;

            if (requests.isEmpty) {
              return const Center(child: Text('Không có yêu cầu tham gia nào'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + (state.hasReachedMax ? 0 : 1),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                if (index == requests.length) {
                  return Center(
                    child: TextButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => context
                                .read<GroupJoinRequestsCubit>()
                                .loadMore(groupId),
                      child: state.isLoadingMore
                          ? const CircularProgressIndicator()
                          : const Text('Xem thêm'),
                    ),
                  );
                }
                final request = requests[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    request.userId,
                  ), // Should show User Name (Backend needs to join it or we fetch it)
                  subtitle: Text(
                    request.message != null && request.message!.isNotEmpty
                        ? 'Lời nhắn: ${request.message}'
                        : 'Tham gia: ${timeago.format(request.createdAt, locale: 'vi')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          context.read<GroupJoinRequestsCubit>().approveRequest(
                            groupId,
                            request.id,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          context.read<GroupJoinRequestsCubit>().rejectRequest(
                            groupId,
                            request.id,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
