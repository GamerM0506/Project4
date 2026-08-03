import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/media_service.dart';
import '../../../../injection_container.dart';
import '../../../ai/data/ai_service.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../data/campaign_error.dart';
import '../../data/datasources/campaign_remote_data_source.dart';
import '../../data/donation_eligibility.dart';
import '../../data/models/campaign_item_input.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/contribution_model.dart';
import '../widgets/donation_gate.dart';
import '../widgets/donation_photo_picker.dart';

/// Một dòng vật phẩm trong đơn đóng góp đang soạn.
///
/// Mỗi dòng giữ ảnh riêng vì backend nhận `images` theo từng phần tử của
/// `items`, không phải theo cả đơn.
class _ItemDraft {
  _ItemDraft({this.campaignItemId})
    : nameController = TextEditingController(),
      quantityController = TextEditingController(text: '1');

  final TextEditingController nameController;
  final TextEditingController quantityController;

  String? campaignItemId;
  String condition = 'good';
  List<PendingPhoto> photos = [];
  bool expanded = true;
  bool detecting = false;
  bool aiDetected = false;

  String? itemError;
  String? nameError;
  String? quantityError;

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 0;

  bool get isBlank =>
      nameController.text.trim().isEmpty &&
      photos.isEmpty &&
      campaignItemId == null;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

class CreateContributionPage extends StatefulWidget {
  const CreateContributionPage({
    super.key,
    this.campaignId,
    this.campaignItemId,
    this.groupId,
  });

  final String? campaignId;
  final String? campaignItemId;
  final String? groupId;

  @override
  State<CreateContributionPage> createState() => _CreateContributionPageState();
}

class _CreateContributionPageState extends State<CreateContributionPage> {
  final _addressController = TextEditingController();
  final _scrollController = ScrollController();
  final _photoPicker = DonationPhotoPicker();

  late Future<List<CampaignModel>> _campaignsFuture;
  List<CampaignModel> _campaigns = const [];
  String? _selectedCampaignId;
  String _pickupMethod = 'drop_off';
  bool _submitting = false;
  String? _addressError;

  final List<_ItemDraft> _items = [];
  bool _seeded = false;

  /// Quyền quyên góp với nhóm của đợt đang chọn. Kiểm tra ngay khi đổi đợt để
  /// không để người dùng điền hết form rồi mới nhận 403 từ backend.
  DonationEligibility? _eligibility;
  bool _checkingAccess = false;
  String? _accessGroupId;

  CampaignModel? get _selectedCampaign => _campaigns
      .where((campaign) => campaign.id == _selectedCampaignId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    _selectedCampaignId = widget.campaignId;
    _campaignsFuture = sl<CampaignRemoteDataSource>().getCampaigns(
      groupId: widget.groupId,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _scrollController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  /// Đọc lại quyền cho nhóm của đợt đang chọn.
  Future<void> _refreshAccess({bool force = false}) async {
    final groupId = _selectedCampaign?.groupId ?? '';
    if (groupId.isEmpty) {
      if (_eligibility != null || _accessGroupId != null) {
        setState(() {
          _eligibility = null;
          _accessGroupId = null;
        });
      }
      return;
    }
    if (_checkingAccess) return;
    if (!force && _accessGroupId == groupId) return;

    _accessGroupId = groupId;
    setState(() => _checkingAccess = true);
    final result = await checkDonationEligibility(
      sl<GroupRemoteDataSource>(),
      groupId,
    );
    if (!mounted) return;
    setState(() {
      _eligibility = result;
      _checkingAccess = false;
    });
  }

  /// Chọn đợt mặc định và tạo dòng vật phẩm đầu tiên, chỉ chạy một lần.
  void _seedSelection() {
    if (_seeded || _campaigns.isEmpty) return;
    _seeded = true;

    final hasCampaign = _campaigns.any(
      (campaign) => campaign.id == _selectedCampaignId,
    );
    if (!hasCampaign) _selectedCampaignId = _campaigns.first.id;

    final campaign = _selectedCampaign;
    if (campaign == null) return;
    final draft = _ItemDraft(
      campaignItemId: campaign.items.any(
        (item) => item.id == widget.campaignItemId,
      )
          ? widget.campaignItemId
          : _defaultItemIdFor(campaign),
    );
    _fillNameFromItem(draft);
    _items.add(draft);
  }

  /// Ưu tiên vật phẩm còn thiếu; nếu tất cả đã đủ thì vẫn chọn món đầu tiên
  /// để người dùng có thể quyên góp vượt mục tiêu (backend cho phép).
  String? _defaultItemIdFor(CampaignModel campaign) {
    if (campaign.items.isEmpty) return null;
    final pending = campaign.items.where((item) => item.remaining > 0);
    return (pending.isNotEmpty ? pending.first : campaign.items.first).id;
  }

  CampaignItemModel? _campaignItemOf(_ItemDraft draft) => _selectedCampaign
      ?.items
      .where((item) => item.id == draft.campaignItemId)
      .firstOrNull;

  void _fillNameFromItem(_ItemDraft draft) {
    final item = _campaignItemOf(draft);
    if (item != null && draft.nameController.text.trim().isEmpty) {
      draft.nameController.text = item.name;
    }
  }

  void _onCampaignChanged(String? value) {
    setState(() {
      _selectedCampaignId = value;
      final campaign = _selectedCampaign;
      // Vật phẩm thuộc về đợt cũ nên phải chọn lại toàn bộ.
      for (final draft in _items) {
        draft.campaignItemId = campaign == null
            ? null
            : _defaultItemIdFor(campaign);
        draft.nameController.clear();
        draft.quantityController.text = '1';
        draft.itemError = null;
        _fillNameFromItem(draft);
      }
    });
  }

  void _addItem() {
    final campaign = _selectedCampaign;
    if (campaign == null) return;
    setState(() {
      for (final draft in _items) {
        draft.expanded = false;
      }
      // Gợi ý món chưa được chọn ở dòng nào, tránh trùng lặp không cần thiết.
      final used = _items.map((draft) => draft.campaignItemId).toSet();
      final available = campaign.items
          .where((item) => !used.contains(item.id))
          .toList();
      final suggested = available.isNotEmpty
          ? (available.firstWhere(
              (item) => item.remaining > 0,
              orElse: () => available.first,
            )).id
          : _defaultItemIdFor(campaign);
      final draft = _ItemDraft(campaignItemId: suggested);
      _fillNameFromItem(draft);
      _items.add(draft);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _removeItem(int index) async {
    final draft = _items[index];
    if (!draft.isBlank) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xoá vật phẩm này?'),
          content: Text(
            'Thông tin đã nhập cho "${draft.nameController.text.trim().isEmpty ? 'vật phẩm' : draft.nameController.text.trim()}" sẽ bị mất.',
          ),
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
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() {
      _items.removeAt(index).dispose();
    });
  }

  Future<void> _addPhotos(_ItemDraft draft) async {
    final source = await showPhotoSourceSheet(context);
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final photo = await _photoPicker.pickOne(source);
        if (photo == null || !mounted) return;
        setState(() {
          if (draft.photos.length >= DonationPhotoPicker.maxPhotos) {
            draft.photos.removeLast();
          }
          draft.photos.add(photo);
          draft.aiDetected = false;
        });
        return;
      }
      final remaining = DonationPhotoPicker.maxPhotos - draft.photos.length;
      if (remaining <= 0) {
        _snack('Mỗi vật phẩm chỉ đính kèm tối đa 10 ảnh.');
        return;
      }
      final photos = await _photoPicker.pickMultiple(remaining: remaining);
      if (photos.isEmpty || !mounted) return;
      setState(() {
        draft.photos = [...draft.photos, ...photos];
        draft.aiDetected = false;
      });
    } catch (error) {
      if (mounted) _snack('Không chọn được ảnh: $error');
    }
  }

  Future<void> _detectItem(_ItemDraft draft) async {
    if (draft.photos.isEmpty || draft.detecting) return;
    setState(() => draft.detecting = true);
    try {
      final result = await sl<AiService>().detectItem(draft.photos.first.bytes);
      if (!mounted) return;
      setState(() {
        final name = result['name']?.toString().trim();
        if (name != null && name.isNotEmpty) draft.nameController.text = name;

        final condition = _normalizeAiCondition(
          result['condition']?.toString(),
        );
        if (condition != null) draft.condition = condition;

        final matched = _findMatchingItem(name);
        if (matched != null) draft.campaignItemId = matched.id;
        draft.aiDetected = true;
        draft.nameError = null;
      });
      _snack('AI đã nhận diện và điền thông tin.');
    } catch (_) {
      if (!mounted) return;
      _snack(
        'Không kết nối được AI (${AppConstants.apiHost}). Bạn vẫn có thể tự điền.',
      );
    } finally {
      if (mounted) setState(() => draft.detecting = false);
    }
  }

  CampaignItemModel? _findMatchingItem(String? detectedName) {
    if (detectedName == null || detectedName.isEmpty) return null;
    final normalized = detectedName.toLowerCase();
    final matches = _selectedCampaign?.items.where(
      (item) =>
          normalized.contains(item.name.toLowerCase()) ||
          item.name.toLowerCase().contains(normalized),
    );
    if (matches == null || matches.isEmpty) return null;
    // Ưu tiên món còn thiếu, nhưng vẫn gợi ý được món đã đủ.
    final pending = matches.where((item) => item.remaining > 0);
    return pending.isNotEmpty ? pending.first : matches.first;
  }

  String? _normalizeAiCondition(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'new' => 'new',
      'like_new' || 'like new' || 'excellent' => 'like_new',
      'good' => 'good',
      'used' || 'fair' || 'acceptable' => 'used',
      'worn' || 'poor' => 'worn',
      _ => null,
    };
  }

  void _changeQuantity(_ItemDraft draft, int delta) {
    final current = int.tryParse(draft.quantityController.text) ?? 1;
    // Cho phép vượt số còn thiếu (backend không chặn), chỉ đặt trần an toàn.
    const hardMax = 999;
    setState(() {
      draft.quantityController.text = '${(current + delta).clamp(1, hardMax)}';
      draft.quantityError = null;
    });
  }

  /// Lý do không thể gửi đơn, hoặc null nếu gửi được.
  /// Trả về chuỗi để hiển thị ngay cạnh nút thay vì để nút xám im lặng.
  String? get _blockedReason {
    if (_campaigns.isEmpty) {
      return 'Hiện chưa có đợt quyên góp nào đang mở để tiếp nhận.';
    }
    final campaign = _selectedCampaign;
    if (campaign == null) return 'Vui lòng chọn đợt quyên góp.';
    if (campaign.items.isEmpty) {
      return 'Đợt "${campaign.title}" chưa khai báo vật phẩm cần nhận. '
          'Vui lòng liên hệ hội nhóm.';
    }
    if (_items.isEmpty) return 'Vui lòng thêm ít nhất một vật phẩm.';
    if (_checkingAccess) return 'Đang kiểm tra quyền quyên góp...';
    final eligibility = _eligibility;
    if (eligibility != null && !eligibility.canDonate) {
      return eligibility.reason;
    }
    return null;
  }

  /// Kiểm tra toàn bộ dòng vật phẩm, mở lại dòng nào sai để người dùng thấy.
  bool _validate() {
    var valid = true;
    for (final draft in _items) {
      draft.itemError = null;
      draft.nameError = null;
      draft.quantityError = null;

      if (draft.campaignItemId == null) {
        draft.itemError = 'Chọn vật phẩm của đợt';
        valid = false;
      }
      if (draft.nameController.text.trim().isEmpty) {
        draft.nameError = 'Nhập tên món đồ';
        valid = false;
      }
      if (draft.quantity < 1) {
        draft.quantityError = 'Số lượng phải từ 1';
        valid = false;
      }
      if (draft.itemError != null ||
          draft.nameError != null ||
          draft.quantityError != null) {
        draft.expanded = true;
      }
    }

    _addressError = null;
    if (_pickupMethod == 'pickup' && _addressController.text.trim().isEmpty) {
      _addressError = 'Vui lòng nhập địa chỉ để hội nhóm đến nhận.';
      valid = false;
    }

    setState(() {});
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final campaign = _selectedCampaign;
    if (campaign == null) return;

    setState(() => _submitting = true);
    try {
      // Tải ảnh của từng món trước, vì payload cần sẵn URL công khai.
      final inputs = <ContributionItemInput>[];
      final uploads = <MediaUploadResult>[];
      for (final draft in _items) {
        final result = await uploadDonationPhotos(
          draft.photos,
          refType: 'donation',
        );
        uploads.addAll(result);
        inputs.add(
          ContributionItemInput(
            campaignItemId: draft.campaignItemId!,
            name: draft.nameController.text,
            quantity: draft.quantity,
            conditionDeclared: draft.condition,
            imageUrls: result.map((upload) => upload.publicUrl).toList(),
          ),
        );
      }

      final contribution = await sl<CampaignRemoteDataSource>()
          .createContribution(
            campaignId: campaign.id,
            items: inputs,
            pickupMethod: _pickupMethod,
            pickupAddress: _pickupMethod == 'pickup'
                ? _addressController.text
                : null,
          );

      // Bắt buộc: ảnh chưa link vẫn ở trạng thái `temp` và sẽ bị cron của
      // media-service xoá sau TEMP_TTL_HOURS, khiến hội nhóm mở lên thấy ảnh vỡ.
      await linkDonationPhotos(
        uploads,
        refType: 'donation',
        refId: contribution.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi đóng góp để hội nhóm duyệt.')),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      _snack(campaignErrorMessage(error, fallback: 'Không gửi được đóng góp.'));
    } finally {
      // Luôn nhả nút, tránh kẹt ở trạng thái "Đang gửi...".
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text(
          'Tạo đơn quyên góp',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CampaignModel>>(
        future: _campaignsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              onRetry: () => setState(() {
                _campaignsFuture = sl<CampaignRemoteDataSource>().getCampaigns(
                  groupId: widget.groupId,
                );
              }),
            );
          }
          _campaigns = snapshot.data ?? const [];
          _seedSelection();
          if (_campaigns.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Hiện chưa có đợt quyên góp đang mở. Hội nhóm cần tạo đợt quyên góp trước khi tiếp nhận vật phẩm.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Kiểm tra quyền cho nhóm của đợt đang chọn (sau khi vẽ xong frame).
          final currentGroupId = _selectedCampaign?.groupId ?? '';
          if (currentGroupId.isNotEmpty && _accessGroupId != currentGroupId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _refreshAccess();
            });
          }

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              // Cảnh báo quyền đặt trên cùng: người dùng biết ngay trước khi
              // mất công chụp ảnh và điền thông tin.
              if (_eligibility != null && !_eligibility!.canDonate) ...[
                DonationGateBanner(
                  eligibility: _eligibility!,
                  onJoined: () => _refreshAccess(force: true),
                  onRetry: () => _refreshAccess(force: true),
                ),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(
                      'Chiến dịch tiếp nhận',
                      Icons.volunteer_activism_outlined,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCampaignId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Chọn chiến dịch quyên góp',
                        prefixIcon: Icon(Icons.favorite_border_rounded),
                      ),
                      items: _campaigns
                          .map(
                            (campaign) => DropdownMenuItem(
                              value: campaign.id,
                              child: Text(
                                campaign.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: widget.campaignId != null
                          ? null
                          : _onCampaignChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Label(
                      'Vật phẩm quyên góp (${_items.length})',
                      Icons.inventory_2_outlined,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm món'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _items.length; index++) ...[
                _ItemCard(
                  draft: _items[index],
                  index: index,
                  campaignItems: _selectedCampaign?.items ?? const [],
                  canRemove: _items.length > 1,
                  onToggle: () => setState(
                    () => _items[index].expanded = !_items[index].expanded,
                  ),
                  onRemove: () => _removeItem(index),
                  onItemChanged: (value) => setState(() {
                    final draft = _items[index];
                    draft.campaignItemId = value;
                    draft.itemError = null;
                    draft.nameController.clear();
                    _fillNameFromItem(draft);
                  }),
                  onConditionChanged: (value) =>
                      setState(() => _items[index].condition = value),
                  onQuantityDelta: (delta) =>
                      _changeQuantity(_items[index], delta),
                  onAddPhoto: () => _addPhotos(_items[index]),
                  onRemovePhoto: (photoIndex) => setState(() {
                    _items[index].photos.removeAt(photoIndex);
                    _items[index].aiDetected = false;
                  }),
                  onDetect: () => _detectItem(_items[index]),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Cách bàn giao', Icons.local_shipping_outlined),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          _SegmentPill(
                            label: 'Tự mang đến',
                            icon: Icons.store_mall_directory_outlined,
                            selected: _pickupMethod == 'drop_off',
                            onTap: () =>
                                setState(() => _pickupMethod = 'drop_off'),
                          ),
                          _SegmentPill(
                            label: 'Đến nhận',
                            icon: Icons.local_shipping_outlined,
                            selected: _pickupMethod == 'pickup',
                            onTap: () =>
                                setState(() => _pickupMethod = 'pickup'),
                          ),
                        ],
                      ),
                    ),
                    if (_pickupMethod == 'pickup') ...[
                      const SizedBox(height: 18),
                      _Label('Địa chỉ nhận đồ *', Icons.location_on_outlined),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Nhập địa chỉ để hội nhóm đến nhận',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          errorText: _addressError,
                        ),
                        onChanged: (_) {
                          if (_addressError != null) {
                            setState(() => _addressError = null);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_blockedReason != null) ...[
                InfoBanner(
                  icon: Icons.report_gmailerrorred_outlined,
                  message: _blockedReason!,
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: _submitting || _blockedReason != null
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _submitting
                          ? 'Đang gửi...'
                          : 'Gửi đơn quyên góp (${_items.length} món)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_submitting)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ một vật phẩm trong đơn, thu gọn được để danh sách dài vẫn dễ nhìn.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.draft,
    required this.index,
    required this.campaignItems,
    required this.canRemove,
    required this.onToggle,
    required this.onRemove,
    required this.onItemChanged,
    required this.onConditionChanged,
    required this.onQuantityDelta,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onDetect,
  });

  final _ItemDraft draft;
  final int index;
  final List<CampaignItemModel> campaignItems;
  final bool canRemove;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final ValueChanged<String?> onItemChanged;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<int> onQuantityDelta;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = campaignItems
        .where((item) => item.id == draft.campaignItemId)
        .firstOrNull;
    final hasError =
        draft.itemError != null ||
        draft.nameError != null ||
        draft.quantityError != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? colors.error
              : colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.nameController.text.trim().isEmpty
                              ? 'Vật phẩm ${index + 1}'
                              : draft.nameController.text.trim(),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!draft.expanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${draft.quantityController.text} ${selected?.unit ?? 'món'} · '
                            '${itemConditionLabel(draft.condition)}'
                            '${draft.photos.isEmpty ? '' : ' · ${draft.photos.length} ảnh'}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
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
                        color: colors.error,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoStrip(
                    photos: draft.photos,
                    onAdd: onAddPhoto,
                    onRemove: onRemovePhoto,
                    emptyLabel: 'Thêm ảnh',
                    firstPhotoBadge: 'Ảnh AI',
                  ),
                  if (draft.photos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: draft.detecting ? null : onDetect,
                        icon: draft.detecting
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          draft.detecting
                              ? 'AI đang nhận diện...'
                              : draft.aiDetected
                              ? 'Nhận diện lại bằng AI'
                              : 'Nhận diện bằng AI',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: draft.campaignItemId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Vật phẩm đợt đang cần *',
                      prefixIcon: const Icon(Icons.card_giftcard_rounded),
                      errorText: draft.itemError,
                    ),
                    items: campaignItems
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.remaining > 0
                                  ? '${item.name} · còn ${item.remaining} ${item.unit ?? ''}'
                                        .trim()
                                  : '${item.name} · đã đủ',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onItemChanged,
                  ),
                  if (selected != null && selected.remaining == 0) ...[
                    const SizedBox(height: 8),
                    const InfoBanner(
                      icon: Icons.info_outline_rounded,
                      message:
                          'Vật phẩm này đã nhận đủ mục tiêu. Bạn vẫn có thể gửi, '
                          'hội nhóm sẽ xem xét.',
                    ),
                  ],
                  if (selected?.conditionRequired != null) ...[
                    const SizedBox(height: 8),
                    InfoBanner(
                      icon: Icons.verified_outlined,
                      message:
                          'Hội nhóm yêu cầu tình trạng tối thiểu: '
                          '${itemConditionLabel(selected!.conditionRequired)}.',
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: draft.nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên món đồ *',
                      hintText: 'Ví dụ: Áo khoác gió nam',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      errorText: draft.nameError,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: draft.quantityError != null
                                      ? colors.error
                                      : colors.outlineVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => onQuantityDelta(-1),
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: draft.quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => onQuantityDelta(1),
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              draft.quantityError ??
                                  'Đơn vị: ${selected?.unit ?? 'món'}',
                              style: textTheme.labelSmall?.copyWith(
                                color: draft.quantityError != null
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: DropdownButtonFormField<String>(
                          initialValue: draft.condition,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tình trạng',
                            prefixIcon: Icon(Icons.stars_outlined),
                          ),
                          items: kItemConditions
                              .map(
                                (condition) => DropdownMenuItem(
                                  value: condition.value,
                                  child: Text(
                                    condition.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) onConditionChanged(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khối thông tin nhỏ màu nhạt, dùng lại ở nhiều chỗ trong luồng quyên góp.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Tải lại đợt quyên góp'),
      ),
    );
  }
}
