import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  late Future<_MyItemsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MyItemsData> _load() async {
    final results = await Future.wait([
      sl<GetDonationsUseCase>()(mine: true, limit: 20),
      sl<GetInventoryUseCase>()(mine: true, limit: 20),
    ]);
    final donations = results[0] as dynamic;
    final inventory = results[1] as dynamic;
    String? error;
    List<DonationModel> donationItems = [];
    List<InventoryItemModel> inventoryItems = [];
    donations.fold((value) => error = value, (value) => donationItems = value);
    inventory.fold(
      (value) => error ??= value,
      (value) => inventoryItems = value,
    );
    if (error != null) throw Exception(error);
    return _MyItemsData(donationItems, inventoryItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vật phẩm của tôi'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<_MyItemsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final data = snapshot.data!;
          if (data.donations.isEmpty && data.inventory.isEmpty) {
            return const _MessageState(
              message: 'Bạn chưa có đơn quyên góp hoặc vật phẩm trong kho.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionTitle('Đơn quyên góp của tôi'),
                if (data.donations.isEmpty)
                  const _EmptyText('Chưa có đơn quyên góp')
                else
                  ...data.donations.map((d) => _DonationTile(donation: d)),
                const SizedBox(height: 20),
                const _SectionTitle('Vật phẩm đã nhập kho'),
                if (data.inventory.isEmpty)
                  const _EmptyText('Chưa có vật phẩm được nhập kho')
                else
                  ...data.inventory.map((item) => _InventoryTile(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyItemsData {
  final List<DonationModel> donations;
  final List<InventoryItemModel> inventory;
  const _MyItemsData(this.donations, this.inventory);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text));
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _MessageState({required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ],
      ),
    ),
  );
}

class _DonationTile extends StatelessWidget {
  final DonationModel donation;
  const _DonationTile({required this.donation});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.volunteer_activism_outlined),
      ),
      title: Text(donation.title),
      subtitle: Text('${donation.code} • ${_status(donation.status)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog(
        context: context,
        builder: (_) => _DonationDialog(donation: donation),
      ),
    ),
  );
}

class _InventoryTile extends StatelessWidget {
  final InventoryItemModel item;
  const _InventoryTile({required this.item});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
      title: Text(item.name),
      subtitle: Text(
        '${item.code} • SL ${item.quantity} • ${_status(item.status)}',
      ),
      trailing: const Icon(Icons.history),
      onTap: () => showDialog(
        context: context,
        builder: (_) => _InventoryDialog(item: item),
      ),
    ),
  );
}

class _DonationDialog extends StatefulWidget {
  final DonationModel donation;
  const _DonationDialog({required this.donation});
  @override
  State<_DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends State<_DonationDialog> {
  late Future<List<dynamic>> _timeline;
  @override
  void initState() {
    super.initState();
    _timeline = sl<GetDonationTimelineUseCase>()(
      widget.donation.id,
    ).then((r) => r.fold((e) => throw Exception(e), (v) => v));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.donation.title),
    content: SizedBox(
      width: 420,
      child: FutureBuilder<List<dynamic>>(
        future: _timeline,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Text(
              snapshot.error.toString().replaceFirst('Exception: ', ''),
            );
          final events = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: events
                  .map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(_status(e.event)),
                      subtitle: Text(
                        '${e.at.toLocal()}${e.note == null ? '' : '\n${e.note}'}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    ),
    actions: [
      if (!{
        'completed',
        'cancelled',
        'rejected',
      }.contains(widget.donation.status))
        TextButton(onPressed: _cancel, child: const Text('Hủy đơn')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
  Future<void> _cancel() async {
    final result = await sl<CancelDonationUseCase>()(widget.donation.id);
    if (!mounted) return;
    result.fold((e) => _showError(e), (_) => Navigator.pop(context));
  }

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _InventoryDialog extends StatelessWidget {
  final InventoryItemModel item;
  const _InventoryDialog({required this.item});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(item.name),
    content: FutureBuilder<dynamic>(
      future: sl<GetInventoryHistoryUseCase>()(
        item.id,
      ).then((r) => r.fold((e) => throw Exception(e), (v) => v)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const CircularProgressIndicator();
        if (snapshot.hasError)
          return Text(
            snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        final history = snapshot.data as List<InventoryHistoryModel>;
        return SizedBox(
          width: 420,
          child: history.isEmpty
              ? const Text('Chưa có lịch sử trạng thái.')
              : SingleChildScrollView(
                  child: Column(
                    children: history
                        .map(
                          (h) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${_status(h.fromStatus ?? 'mới')} → ${_status(h.toStatus)}',
                            ),
                            subtitle: Text(
                              '${h.createdAt.toLocal()}${h.note == null ? '' : '\n${h.note}'}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
        );
      },
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}

String _status(String value) => switch (value) {
  'pending' => 'Chờ xử lý',
  'accepted' => 'Đã tiếp nhận',
  'scheduled' => 'Đã đặt lịch',
  'received' => 'Đã nhận',
  'completed' => 'Hoàn tất',
  'cancelled' => 'Đã hủy',
  'in_stock' => 'Trong kho',
  'listed' => 'Đã đăng',
  'reserved' => 'Đã giữ',
  'delivered' => 'Đã trao',
  _ => value,
};
