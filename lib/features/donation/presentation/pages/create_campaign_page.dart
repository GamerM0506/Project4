import 'package:flutter/material.dart';

import '../../../../injection_container.dart';
import '../../data/campaign_error.dart';
import '../../data/datasources/campaign_remote_data_source.dart';
import '../../data/models/campaign_item_input.dart';
import '../../data/models/category_model.dart';

/// Màn tạo đợt quyên góp cho hội nhóm.
///
/// Dùng trang đầy đủ thay vì bottom sheet: form có nhiều vật phẩm nên sheet
/// không đủ chỗ, bàn phím che mất nội dung và người dùng không thấy được
/// mình đã thêm những gì.
class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({
    super.key,
    required this.groupId,
    this.groupName,
  });

  final String groupId;
  final String? groupName;

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

/// Một dòng vật phẩm đang soạn. Giữ controller riêng để không mất dữ liệu
/// khi danh sách được vẽ lại.
class _ItemDraft {
  _ItemDraft()
    : name = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      unit = TextEditingController(text: 'món'),
      note = TextEditingController();

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController note;
  String? categoryId;
  String? condition;
  bool expanded = true;

  String? nameError;
  String? quantityError;
  String? unitError;

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    note.dispose();
  }

  int? get parsedQuantity => int.tryParse(quantity.text.trim());

  CampaignItemInput toInput() => CampaignItemInput(
    name: name.text,
    targetQuantity: parsedQuantity ?? 1,
    unit: unit.text,
    categoryId: categoryId,
    conditionRequired: condition,
    note: note.text,
  );
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _beneficiary = TextEditingController();
  final _scroll = ScrollController();

  final List<_ItemDraft> _items = [_ItemDraft()];
  late Future<List<CategoryModel>> _categoriesFuture;
  DateTime? _deadline;
  bool _submitting = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = sl<CampaignRemoteDataSource>().getCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _beneficiary.dispose();
    _scroll.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      // Thu gọn các món đã nhập để danh sách không quá dài.
      for (final item in _items) {
        item.expanded = false;
      }
      _items.add(_ItemDraft());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _removeItem(int index) async {
    final draft = _items[index];
    final hasContent = draft.name.text.trim().isNotEmpty;
    if (hasContent) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xoá vật phẩm?'),
          content: Text('Bỏ "${draft.name.text.trim()}" khỏi đợt quyên góp?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Giữ lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xoá'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    setState(() {
      _items.removeAt(index).dispose();
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Chọn hạn chót nhận quyên góp',
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  /// Validate khớp ràng buộc backend (CreateCampaignRequest / CampaignItemIn).
  bool _validate() {
    final title = _title.text.trim();
    String? titleError;
    if (title.isEmpty) {
      titleError = 'Vui lòng nhập tên đợt';
    } else if (title.length > 200) {
      titleError = 'Tên đợt tối đa 200 ký tự';
    }

    var firstInvalid = -1;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final name = item.name.text.trim();
      final unit = item.unit.text.trim();
      final qty = item.parsedQuantity;

      item.nameError = name.isEmpty
          ? 'Vui lòng nhập tên vật phẩm'
          : (name.length > 200 ? 'Tối đa 200 ký tự' : null);
      item.quantityError = qty == null
          ? 'Phải là số'
          : (qty < 1 ? 'Phải lớn hơn 0' : null);
      item.unitError = unit.length > 20 ? 'Tối đa 20 ký tự' : null;

      final invalid = item.nameError != null ||
          item.quantityError != null ||
          item.unitError != null;
      if (invalid) {
        item.expanded = true;
        if (firstInvalid < 0) firstInvalid = i;
      }
    }

    setState(() => _titleError = titleError);
    return titleError == null && firstInvalid < 0;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra lại thông tin.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await sl<CampaignRemoteDataSource>().createCampaign(
        groupId: widget.groupId,
        title: _title.text,
        description: _description.text,
        beneficiaryDescription: _beneficiary.text,
        deadline: _deadline,
        items: _items.map((item) => item.toInput()).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            campaignErrorMessage(error, fallback: 'Không tạo được đợt quyên góp.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đợt quyên góp'),
        bottom: widget.groupName == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.groupName!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionCard(
            icon: Icons.campaign_outlined,
            title: 'Thông tin đợt',
            children: [
              TextField(
                controller: _title,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tên đợt *',
                  hintText: 'Ví dụ: Áo ấm mùa đông cho vùng cao',
                  errorText: _titleError,
                  counterText: '',
                ),
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Hoàn cảnh, mục đích của đợt quyên góp...',
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _beneficiary,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Đối tượng thụ hưởng',
                  hintText: 'Ví dụ: Bà con vùng cao Hà Giang',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              _DeadlineField(
                deadline: _deadline,
                onPick: _pickDeadline,
                onClear: () => setState(() => _deadline = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ItemsHeader(count: _items.length),
          const SizedBox(height: 10),
          for (var i = 0; i < _items.length; i++) ...[
            _ItemCard(
              key: ObjectKey(_items[i]),
              index: i,
              draft: _items[i],
              categoriesFuture: _categoriesFuture,
              canRemove: _items.length > 1,
              onRemove: () => _removeItem(i),
              onToggle: () => setState(
                () => _items[i].expanded = !_items[i].expanded,
              ),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm vật phẩm'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: _submitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Đang tạo...'),
                    ],
                  )
                : Text(
                    _items.length > 1
                        ? 'Tạo đợt với ${_items.length} vật phẩm'
                        : 'Tạo đợt quyên góp',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          'Vật phẩm cần nhận',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ nhập một vật phẩm, thu gọn được để danh sách dài vẫn dễ nhìn.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.draft,
    required this.categoriesFuture,
    required this.canRemove,
    required this.onRemove,
    required this.onToggle,
    required this.onChanged,
  });

  final int index;
  final _ItemDraft draft;
  final Future<List<CategoryModel>> categoriesFuture;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onToggle;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError = draft.nameError != null ||
        draft.quantityError != null ||
        draft.unitError != null;
    final name = draft.name.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? colors.error
              : colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Vật phẩm ${index + 1}' : name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!draft.expanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Cần ${draft.quantity.text.trim()} '
                            '${draft.unit.text.trim()}'
                            '${draft.condition == null ? '' : ' · ${itemConditionLabel(draft.condition)}'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canRemove)
                    IconButton(
                      tooltip: 'Xoá vật phẩm',
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  Icon(
                    draft.expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (draft.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  TextField(
                    controller: draft.name,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Tên vật phẩm *',
                      hintText: 'Ví dụ: Áo khoác trẻ em',
                      errorText: draft.nameError,
                      counterText: '',
                      isDense: true,
                    ),
                    onChanged: (_) {
                      draft.nameError = null;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: draft.quantity,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Số lượng *',
                            errorText: draft.quantityError,
                            isDense: true,
                          ),
                          onChanged: (_) {
                            draft.quantityError = null;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: draft.unit,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: 'Đơn vị',
                            hintText: 'cái, bộ, kg...',
                            errorText: draft.unitError,
                            counterText: '',
                            isDense: true,
                          ),
                          onChanged: (_) {
                            draft.unitError = null;
                            onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CategoryDropdown(
                    future: categoriesFuture,
                    value: draft.categoryId,
                    onChanged: (value) {
                      draft.categoryId = value;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: draft.condition,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tình trạng tối thiểu',
                      helperText: 'Không bắt buộc',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Không yêu cầu'),
                      ),
                      for (final c in kItemConditions)
                        DropdownMenuItem<String>(
                          value: c.value,
                          child: Text(c.label),
                        ),
                    ],
                    onChanged: (value) {
                      draft.condition = value;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: draft.note,
                    maxLength: 1000,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú cho người quyên góp',
                      hintText: 'Ví dụ: Ưu tiên size trẻ em 5-10 tuổi',
                      counterText: '',
                      isDense: true,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dropdown danh mục lấy từ `GET /donation/categories`.
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.future,
    required this.value,
    required this.onChanged,
  });

  final Future<List<CategoryModel>> future;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InputDecorator(
            decoration: InputDecoration(labelText: 'Danh mục', isDense: true),
            child: SizedBox(
              height: 20,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          );
        }
        final categories = snapshot.data ?? const <CategoryModel>[];
        if (snapshot.hasError || categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Danh mục',
            helperText: 'Không bắt buộc',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Không chọn'),
            ),
            for (final category in categories)
              DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.deadline,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? deadline;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hạn chót',
          helperText: 'Không bắt buộc',
          suffixIcon: deadline == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(deadline == null ? 'Chưa đặt' : _formatDate(deadline!)),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
