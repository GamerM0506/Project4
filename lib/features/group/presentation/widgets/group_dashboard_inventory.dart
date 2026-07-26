import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../data/models/group_model.dart';
import '../cubit/group_inventory_cubit.dart';
import '../cubit/group_inventory_state.dart';
import 'group_requests_tab.dart';

class GroupDashboardInventory extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardInventory({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Quản lý Vật phẩm',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TabBar(
            labelColor: const Color(0xFFB73A41),
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: const Color(0xFFB73A41),
            tabs: const [
              Tab(text: 'Kho đồ'),
              Tab(text: 'Yêu cầu nhận đồ'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BlocProvider(
                  create: (_) =>
                      sl<GroupInventoryCubit>()..fetchInventory(group.id),
                  child: _InventoryView(group: group),
                ),
                GroupRequestsTab(groupId: group.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryView extends StatelessWidget {
  final GroupModel group;

  const _InventoryView({required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupInventoryCubit, GroupInventoryState>(
      listener: (context, state) {
        if (state is GroupInventoryError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is GroupInventoryLoaded && state.actionError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionError!)));
        }
      },
      builder: (context, state) {
        if (state is GroupInventoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is GroupInventoryError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () =>
                  context.read<GroupInventoryCubit>().fetchInventory(group.id),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại kho'),
            ),
          );
        }
        if (state is! GroupInventoryLoaded) return const SizedBox.shrink();

        final actionableDonations = state.donations
            .where(
              (donation) =>
                  donation.status == 'pending' ||
                  donation.status == 'accepted' ||
                  donation.status == 'scheduled' ||
                  donation.status == 'received',
            )
            .toList();

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () =>
                  context.read<GroupInventoryCubit>().fetchInventory(group.id),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Đơn quyên góp cần xử lý',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (actionableDonations.isEmpty)
                    const _EmptyCard(text: 'Không có đơn cần xử lý')
                  else
                    ...actionableDonations.map(
                      (donation) =>
                          _DonationCard(groupId: group.id, donation: donation),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Vật phẩm trong kho',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.items.isEmpty)
                    const _EmptyCard(text: 'Kho đồ đang trống')
                  else
                    ...state.items.map(
                      (item) => _InventoryCard(
                        groupId: group.id,
                        item: item,
                        isPublishing: state.publishingItemId == item.id,
                        publishLocked: state.publishingItemId != null,
                      ),
                    ),
                ],
              ),
            ),
            if (state.isProcessing)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DonationCard extends StatelessWidget {
  final String groupId;
  final DonationModel donation;

  const _DonationCard({required this.groupId, required this.donation});

  @override
  Widget build(BuildContext context) {
    final pendingItems = donation.items
        .where((item) => item.status == 'pending')
        .toList();
    final imageUrls = donation.items
        .expand((item) => item.images)
        .map((image) => image.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();

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
                    donation.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(label: Text(_statusText(donation.status))),
              ],
            ),
            Text('${donation.code} • ${donation.items.length} vật phẩm'),
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrls[index],
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 88,
                        child: ColoredBox(
                          color: Color(0xFFE0E0E0),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (donation.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(donation.description!),
            ],
            const SizedBox(height: 12),
            if (donation.status == 'accepted')
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _schedule(context),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Đặt lịch tiếp nhận'),
                ),
              ),
            if (donation.status == 'pending')
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => context.read<GroupInventoryCubit>().review(
                      groupId,
                      donation.id,
                      'accepted',
                    ),
                    child: const Text('Tiếp nhận đơn'),
                  ),
                  OutlinedButton(
                    onPressed: () => _rejectDonation(context),
                    child: const Text('Từ chối'),
                  ),
                ],
              )
            else if (pendingItems.isNotEmpty) ...[
              const Text(
                'Kiểm tra vật phẩm thực tế',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...pendingItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    'SL ${item.quantity} • Khai báo: ${_conditionText(item.conditionDeclared)}',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => _checkItem(context, item),
                    child: const Text('Kiểm tra'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rejectDonation(BuildContext context) async {
    final reason = await _textDialog(
      context,
      title: 'Từ chối đơn quyên góp',
      label: 'Lý do từ chối',
    );
    if (reason == null || !context.mounted) return;
    await context.read<GroupInventoryCubit>().review(
      groupId,
      donation.id,
      'rejected',
      reason: reason,
    );
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
    await context.read<GroupInventoryCubit>().schedule(
      groupId,
      donation.id,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _checkItem(BuildContext context, DonationItemModel item) async {
    var condition = item.conditionDeclared;
    final noteController = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Kiểm tra ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: condition,
                decoration: const InputDecoration(
                  labelText: 'Tình trạng thực tế',
                ),
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('Mới')),
                  DropdownMenuItem(
                    value: 'like_new',
                    child: Text('Gần như mới'),
                  ),
                  DropdownMenuItem(value: 'good', child: Text('Tốt')),
                  DropdownMenuItem(value: 'used', child: Text('Đã sử dụng')),
                  DropdownMenuItem(value: 'worn', child: Text('Hao mòn')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => condition = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú hoặc lý do từ chối',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'rejected'),
              child: const Text('Từ chối vật phẩm'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'accepted'),
              child: const Text('Nhập kho'),
            ),
          ],
        ),
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (action == null || !context.mounted) return;
    if (action == 'rejected' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần nhập lý do từ chối vật phẩm.')),
      );
      return;
    }
    await context.read<GroupInventoryCubit>().checkItem(
      groupId: groupId,
      donationId: donation.id,
      itemId: item.id,
      action: action,
      conditionActual: action == 'accepted' ? condition : null,
      note: note,
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final String groupId;
  final InventoryItemModel item;
  final bool isPublishing;
  final bool publishLocked;

  const _InventoryCard({
    required this.groupId,
    required this.item,
    required this.isPublishing,
    required this.publishLocked,
  });

  @override
  Widget build(BuildContext context) {
    final canPublish = item.status == 'in_stock';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(item.name),
        subtitle: Text(
          '${item.code} • SL ${item.quantity} • ${_conditionText(item.condition)}',
        ),
        trailing: FilledButton.tonal(
          onPressed: canPublish && !publishLocked
              ? () => context.read<GroupInventoryCubit>().publish(groupId, item)
              : null,
          child: isPublishing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(canPublish ? 'Đăng gian hàng' : _statusText(item.status)),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(text)),
      ),
    );
  }
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(dialogContext, text);
          },
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

String _conditionText(String value) {
  return switch (value) {
    'new' => 'Mới',
    'like_new' => 'Gần như mới',
    'good' => 'Tốt',
    'used' => 'Đã sử dụng',
    'worn' => 'Hao mòn',
    _ => 'Không xác định',
  };
}

String _statusText(String value) {
  return switch (value) {
    'pending' => 'Chờ duyệt',
    'accepted' => 'Đã tiếp nhận',
    'scheduled' => 'Đã hẹn',
    'received' => 'Đang kiểm tra',
    'completed' => 'Hoàn tất',
    'in_stock' => 'Trong kho',
    'listed' => 'Đã đăng',
    'reserved' => 'Đã giữ',
    'delivered' => 'Đã trao',
    _ => 'Không xác định',
  };
}
