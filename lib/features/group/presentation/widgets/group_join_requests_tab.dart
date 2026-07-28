import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/join_request_entity.dart';
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
              return const AppEmptyState(
                icon: Icons.person_add_alt_rounded,
                title: 'Không có yêu cầu nào',
                message:
                    'Yêu cầu tham gia nhóm sẽ hiện ở đây khi có người xin vào.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length + (state.hasReachedMax ? 0 : 1),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xem thêm'),
                    ),
                  );
                }
                final request = requests[index];
                return _JoinRequestCard(groupId: groupId, request: request);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({required this.groupId, required this.request});

  final String groupId;
  final JoinRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = request.message?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: request.userAvatar,
                name: request.userName ?? '',
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName?.trim().isNotEmpty == true
                          ? request.userName!
                          : 'Người dùng #${request.userId.substring(0, 8).toUpperCase()}',
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(request.createdAt, locale: 'vi'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$message"',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<GroupJoinRequestsCubit>().rejectRequest(
                      groupId,
                      request.id,
                    );
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  label: Text(
                    'Từ chối',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<GroupJoinRequestsCubit>().approveRequest(
                      groupId,
                      request.id,
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Chấp nhận'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
