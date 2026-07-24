import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/donation_entity.dart';
import '../../domain/usecases/donation_usecases.dart';

class DonationDetailPage extends StatefulWidget {
  final String donationId;

  const DonationDetailPage({super.key, required this.donationId});

  @override
  State<DonationDetailPage> createState() => _DonationDetailPageState();
}

class _DonationDetailPageState extends State<DonationDetailPage> {
  DonationEntity? _donation;
  List<DonationTimelineEntry> _timeline = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final detail = await sl<GetDonationDetailUseCase>()(widget.donationId);
    final timeline = await sl<GetDonationTimelineUseCase>()(widget.donationId);

    if (!mounted) return;

    detail.fold(
      (err) => setState(() {
        _loading = false;
        _error = err;
      }),
      (d) {
        timeline.fold(
          (_) => setState(() {
            _loading = false;
            _donation = d;
            _timeline = [];
          }),
          (t) => setState(() {
            _loading = false;
            _donation = d;
            _timeline = t;
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết quyên góp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _donation == null
                  ? const Center(child: Text('Không tìm thấy'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            _donation!.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mã: ${_donation!.code} · ${_donation!.status}',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant),
                          ),
                          if (_donation!.description != null) ...[
                            const SizedBox(height: 12),
                            Text(_donation!.description!),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Món đồ',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._donation!.items.map(
                            (i) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(i.name),
                              subtitle: Text(
                                  'SL ${i.quantity} · ${i.conditionDeclared} · ${i.status}'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Hành trình',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_timeline.isEmpty)
                            Text(
                              'Chưa có sự kiện',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            )
                          else
                            ..._timeline.map(
                              (e) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.timeline,
                                    color: colorScheme.primary),
                                title: Text(e.event),
                                subtitle: Text(
                                  '${e.at.day}/${e.at.month}/${e.at.year} ${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}'
                                  '${e.note != null ? ' · ${e.note}' : ''}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
