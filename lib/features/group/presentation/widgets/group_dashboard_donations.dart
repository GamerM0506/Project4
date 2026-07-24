import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../donation/domain/entities/donation_entity.dart';
import '../../../donation/presentation/cubit/group_donations_cubit.dart';
import '../../data/models/group_model.dart';

class GroupDashboardDonations extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardDonations({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupDonationsCubit(
        getDonationsUseCase: sl(),
        reviewDonationUseCase: sl(),
        checkDonationItemUseCase: sl(),
      )..load(group.id),
      child: _DonationsView(groupId: group.id),
    );
  }
}

class _DonationsView extends StatelessWidget {
  final String groupId;

  const _DonationsView({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<GroupDonationsCubit, GroupDonationsState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn quyên góp',
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<GroupDonationsCubit>().load(groupId),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.donations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.donations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => context
                                    .read<GroupDonationsCubit>()
                                    .load(groupId),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : state.donations.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có đơn quyên góp',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => context
                                  .read<GroupDonationsCubit>()
                                  .load(groupId),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.donations.length,
                                itemBuilder: (context, index) {
                                  final d = state.donations[index];
                                  return _DonationCard(
                                    donation: d,
                                    busy: state.actionId == d.id,
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

class _DonationCard extends StatelessWidget {
  final DonationEntity donation;
  final bool busy;

  const _DonationCard({required this.donation, required this.busy});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pending = donation.status.toLowerCase() == 'pending';
    final accepted = donation.status.toLowerCase() == 'accepted' ||
        donation.status.toLowerCase() == 'scheduled' ||
        donation.status.toLowerCase() == 'received';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  donation.code.isNotEmpty ? donation.code : donation.status,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Trạng thái: ${donation.status} · ${donation.items.length} món',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (donation.description != null &&
                donation.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                donation.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              )
            else if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => context
                        .read<GroupDonationsCubit>()
                        .review(donation.id, 'accepted'),
                    child: const Text('Chấp nhận'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => context
                        .read<GroupDonationsCubit>()
                        .review(donation.id, 'rejected',
                            reason: 'Không phù hợp'),
                    child: const Text('Từ chối'),
                  ),
                ],
              ),
            ] else if (accepted && donation.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Kiểm tra món (nhập kho)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...donation.items.map((item) {
                final itemPending = item.status.toLowerCase() == 'pending';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item.name),
                  subtitle: Text(
                      'SL ${item.quantity} · ${item.conditionDeclared} · ${item.status}'),
                  trailing: itemPending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Nhập kho',
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.green),
                              onPressed: () => context
                                  .read<GroupDonationsCubit>()
                                  .checkItem(
                                    donationId: donation.id,
                                    itemId: item.id,
                                    action: 'accepted',
                                  ),
                            ),
                            IconButton(
                              tooltip: 'Từ chối món',
                              icon: Icon(Icons.cancel_outlined,
                                  color: colorScheme.error),
                              onPressed: () => context
                                  .read<GroupDonationsCubit>()
                                  .checkItem(
                                    donationId: donation.id,
                                    itemId: item.id,
                                    action: 'rejected',
                                  ),
                            ),
                          ],
                        )
                      : Icon(
                          item.status == 'accepted'
                              ? Icons.inventory_2
                              : Icons.block,
                          color: item.status == 'accepted'
                              ? Colors.green
                              : colorScheme.error,
                        ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
