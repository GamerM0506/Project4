import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../chat/presentation/utils/open_context_conversation.dart';

import '../../../../core/widgets/app_status_badge.dart';
import '../../../../injection_container.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';
import '../../data/models/group_model.dart';
import '../cubit/group_inventory_cubit.dart';
import '../cubit/group_inventory_state.dart';
import 'group_requests_tab.dart';

class GroupDashboardInventory extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardInventory({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            tabs: [
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

class _InventoryView extends StatefulWidget {
  final GroupModel group;

  const _InventoryView({required this.group});

  @override
  State<_InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<_InventoryView> {
  final _codeController = TextEditingController();
  String _codeQuery = '';
  DonationModel? _lookupResult;
  String? _lookupError;
  bool _isLookingUp = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

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
              onPressed: () => context
                  .read<GroupInventoryCubit>()
                  .fetchInventory(widget.group.id),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại kho'),
            ),
          );
        }
        if (state is! GroupInventoryLoaded) return const SizedBox.shrink();

        final normalizedQuery = _codeQuery.trim().toLowerCase();
        final locallyVisibleDonations = normalizedQuery.isEmpty
            ? state.donations
                  .where(
                    (donation) =>
                        donation.status == 'pending' ||
                        donation.status == 'accepted' ||
                        donation.status == 'scheduled' ||
                        donation.status == 'received',
                  )
                  .toList()
            : state.donations
                  .where(
                    (donation) =>
                        donation.code.toLowerCase().contains(normalizedQuery),
                  )
                  .toList();
        final visibleDonations = _lookupResult == null
            ? locallyVisibleDonations
            : [_lookupResult!];

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => context
                  .read<GroupInventoryCubit>()
                  .fetchInventory(widget.group.id),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    normalizedQuery.isEmpty
                        ? 'Đơn quyên góp cần xử lý'
                        : 'Kết quả tìm mã đơn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) => setState(() {
                      _codeQuery = value;
                      _lookupResult = null;
                      _lookupError = null;
                    }),
                    onSubmitted: (_) => _lookupDonation(),
                    decoration: InputDecoration(
                      labelText: 'Tìm theo mã đơn',
                      hintText: 'Ví dụ: DON-ABCDEF',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      suffixIcon: _codeQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa mã tìm kiếm',
                              onPressed: () {
                                _codeController.clear();
                                setState(() {
                                  _codeQuery = '';
                                  _lookupResult = null;
                                  _lookupError = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: normalizedQuery.isEmpty || _isLookingUp
                          ? null
                          : _lookupDonation,
                      icon: _isLookingUp
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Tra cứu mã'),
                    ),
                  ),
                  if (_lookupError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lookupError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (visibleDonations.isEmpty)
                    _EmptyCard(
                      text: normalizedQuery.isEmpty
                          ? 'Không có đơn cần xử lý'
                          : 'Không tìm thấy đơn có mã "${_codeQuery.trim()}"',
                    )
                  else
                    ...visibleDonations.map(
                      (donation) => _DonationCard(
                        groupId: widget.group.id,
                        donation: donation,
                      ),
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
                        groupId: widget.group.id,
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

  Future<void> _lookupDonation() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _isLookingUp) return;

    setState(() {
      _isLookingUp = true;
      _lookupResult = null;
      _lookupError = null;
    });
    final result = await sl<GetDonationByCodeUseCase>()(code, widget.group.id);
    if (!mounted) return;
    result.fold(
      (error) => setState(() {
        _isLookingUp = false;
        _lookupError = error;
      }),
      (donation) => setState(() {
        _isLookingUp = false;
        _lookupResult = donation;
      }),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final String groupId;
  final DonationModel donation;

  const _DonationCard({required this.groupId, required this.donation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pendingItems = donation.items
        .where((item) => item.status == 'pending')
        .toList();
    final imageUrls = donation.items
        .expand((item) => item.images)
        .map((image) => image.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  donation.title,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(status: donation.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${donation.code} • ${donation.items.length} vật phẩm',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrls[index],
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 84,
                      height: 84,
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (donation.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              donation.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => openContextConversation(
                  context,
                  contextType: 'donation',
                  contextId: donation.id,
                  groupId: groupId,
                  name: donation.title,
                  participantUserId: donation.donorId,
                  asGroup: true,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Nhắn ngườі gửi'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                ),
              ),
              if (donation.status == 'accepted')
                FilledButton.tonalIcon(
                  onPressed: () => _schedule(context),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: const Text('Đặt lịch tiếp nhận'),
                ),
            ],
          ),
          if (donation.status == 'pending') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectDonation(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => context.read<GroupInventoryCubit>().review(
                      groupId,
                      donation.id,
                      'accepted',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text('Tiếp nhận đơn'),
                  ),
                ),
              ],
            ),
          ] else if (pendingItems.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Kiểm tra vật phẩm thực tế', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            ...pendingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            'SL ${item.quantity} • Khai báo: ${_conditionText(item.conditionDeclared)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _checkItem(context, item),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Kiểm tra'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canPublish = item.status == 'in_stock';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.code} • SL ${item.quantity} • ${_conditionText(item.condition)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canPublish)
            FilledButton.tonal(
              onPressed: publishLocked
                  ? null
                  : () =>
                      context.read<GroupInventoryCubit>().publish(groupId, item),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
              child: isPublishing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng tin'),
            )
          else
            AppStatusBadge(status: item.status),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 36,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
