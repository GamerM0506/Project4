import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../cubit/create_donation_cubit.dart';

class CreateDonationPage extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const CreateDonationPage({super.key, this.groupId, this.groupName});

  @override
  State<CreateDonationPage> createState() => _CreateDonationPageState();
}

class _CreateDonationPageState extends State<CreateDonationPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _addressController = TextEditingController();
  int _quantity = 1;
  String _condition = 'good';
  String _pickup = 'drop_off';

  static const _conditions = {
    'new': 'Mới',
    'like_new': 'Như mới',
    'good': 'Tốt',
    'used': 'Đã dùng',
    'worn': 'Cũ',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _itemNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => CreateDonationCubit(createDonationUseCase: sl()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.groupName != null
                ? 'Quyên góp · ${widget.groupName}'
                : 'Tạo đơn quyên góp',
          ),
        ),
        body: BlocConsumer<CreateDonationCubit, CreateDonationState>(
          listener: (context, state) {
            if (state.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi đơn quyên góp!')),
              );
              context.pop(true);
            } else if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (groupId.isEmpty)
                    Card(
                      color: colorScheme.errorContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                            'Thiếu groupId. Hãy mở màn này từ trang chi tiết nhóm.'),
                      ),
                    ),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề đơn *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Món đồ',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên món *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Số lượng'),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_quantity',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _condition,
                    decoration: const InputDecoration(
                      labelText: 'Tình trạng',
                      border: OutlineInputBorder(),
                    ),
                    items: _conditions.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _condition = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _pickup,
                    decoration: const InputDecoration(
                      labelText: 'Hình thức',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'drop_off', child: Text('Mang đến nhóm')),
                      DropdownMenuItem(
                          value: 'pickup', child: Text('Nhóm đến lấy')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _pickup = v);
                    },
                  ),
                  if (_pickup == 'pickup') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ lấy đồ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: state.isSubmitting || groupId.isEmpty
                        ? null
                        : () {
                            context.read<CreateDonationCubit>().submit(
                                  groupId: groupId,
                                  title: _titleController.text,
                                  description: _descController.text,
                                  pickupMethod: _pickup,
                                  pickupAddress: _addressController.text,
                                  itemName: _itemNameController.text,
                                  quantity: _quantity,
                                  condition: _condition,
                                );
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Gửi đơn quyên góp'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
