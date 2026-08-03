import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../data/campaign_error.dart';
import '../../data/datasources/campaign_remote_data_source.dart';
import '../../data/models/campaign_item_input.dart';
import '../../data/models/contribution_model.dart';
import 'donation_photo_picker.dart';

/// Các bottom sheet hội nhóm dùng để xử lý đơn đóng góp.
///
/// Tách riêng khỏi tab quản lý để phần thao tác có trạng thái (đang gửi, lỗi,
/// ảnh chờ tải lên) không làm phình widget danh sách.

/// Duyệt sơ bộ một đơn: `pending → accepted | rejected`.
///
/// Khi từ chối, backend nhận `reason` và gửi kèm cho người quyên góp trong
/// thông báo `contribution.reviewed`, nên đây là trường bắt buộc.
Future<bool?> showReviewContributionSheet(
  BuildContext context, {
  required ContributionModel contribution,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReviewSheet(contribution: contribution),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.contribution});

  final ContributionModel contribution;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _reasonController = TextEditingController();
  bool _rejecting = false;
  bool _submitting = false;
  String? _reasonError;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (_rejecting && reason.isEmpty) {
      setState(() => _reasonError = 'Vui lòng cho biết lý do từ chối.');
      return;
    }
    setState(() {
      _reasonError = null;
      _error = null;
      _submitting = true;
    });
    try {
      await sl<CampaignRemoteDataSource>().reviewContribution(
        id: widget.contribution.id,
        action: _rejecting ? 'rejected' : 'accepted',
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = campaignErrorMessage(
          error,
          fallback: 'Không xử lý được đơn đóng góp.',
        );
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contribution = widget.contribution;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return _SheetShell(
      title: 'Duyệt đơn đóng góp',
      subtitle: contribution.code,
      children: [
        _SummaryTile(
          icon: Icons.inventory_2_outlined,
          label:
              '${contribution.items.length} loại · '
              '${contribution.totalQuantity} món',
        ),
        _SummaryTile(
          icon: Icons.local_shipping_outlined,
          label: contribution.pickupMethod == 'pickup'
              ? 'Hội nhóm đến nhận${contribution.pickupAddress == null ? '' : ' · ${contribution.pickupAddress}'}'
              : 'Người quyên góp tự mang đến',
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.check_circle_outline, size: 18),
              label: Text('Tiếp nhận'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.cancel_outlined, size: 18),
              label: Text('Từ chối'),
            ),
          ],
          selected: {_rejecting},
          onSelectionChanged: _submitting
              ? null
              : (value) => setState(() {
                  _rejecting = value.first;
                  _reasonError = null;
                }),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: _rejecting ? 'Lý do từ chối *' : 'Ghi chú (không bắt buộc)',
            hintText: _rejecting
                ? 'Ví dụ: Không phù hợp nhu cầu của đợt này'
                : 'Lời nhắn gửi tới người quyên góp',
            errorText: _reasonError,
            counterText: '',
          ),
          onChanged: (_) {
            if (_reasonError != null) setState(() => _reasonError = null);
          },
        ),
        const SizedBox(height: 4),
        Text(
          _rejecting
              ? 'Người quyên góp sẽ nhận được lý do này trong thông báo.'
              : 'Sau khi tiếp nhận, bạn kiểm tra từng món để cập nhật tiến độ đợt.',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: _rejecting ? colors.error : null,
            foregroundColor: _rejecting ? colors.onError : null,
          ),
          child: Text(
            _submitting
                ? 'Đang gửi...'
                : _rejecting
                ? 'Từ chối đơn'
                : 'Tiếp nhận đơn',
          ),
        ),
      ],
    );
  }
}

/// Kiểm tra một vật phẩm: ghi tình trạng thực tế, ghi chú và ảnh bằng chứng.
///
/// Món `accepted` sẽ được backend cộng vào `campaign_items.received_quantity`
/// ngay trong cùng transaction, nên đây là bước quyết định tiến độ của đợt.
Future<bool?> showCheckItemSheet(
  BuildContext context, {
  required String contributionId,
  required ContributionItemModel item,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CheckItemSheet(contributionId: contributionId, item: item),
  );
}

class _CheckItemSheet extends StatefulWidget {
  const _CheckItemSheet({required this.contributionId, required this.item});

  final String contributionId;
  final ContributionItemModel item;

  @override
  State<_CheckItemSheet> createState() => _CheckItemSheetState();
}

class _CheckItemSheetState extends State<_CheckItemSheet> {
  final _noteController = TextEditingController();
  final _rejectReasonController = TextEditingController();
  final _photoPicker = DonationPhotoPicker();

  late String _conditionActual = widget.item.conditionDeclared.isEmpty
      ? 'good'
      : widget.item.conditionDeclared;
  bool _rejecting = false;
  bool _submitting = false;
  String? _rejectError;
  String? _error;
  List<PendingPhoto> _photos = [];

  @override
  void dispose() {
    _noteController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final photo = await _photoPicker.pickOne(source);
        if (photo == null || !mounted) return;
        setState(() => _photos = [..._photos, photo]);
        return;
      }
      final remaining = DonationPhotoPicker.maxPhotos - _photos.length;
      if (remaining <= 0) return;
      final photos = await _photoPicker.pickMultiple(remaining: remaining);
      if (photos.isEmpty || !mounted) return;
      setState(() => _photos = [..._photos, ...photos]);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không chọn được ảnh: $error');
    }
  }

  Future<void> _submit() async {
    if (_rejecting && _rejectReasonController.text.trim().isEmpty) {
      setState(() => _rejectError = 'Vui lòng cho biết vì sao món không đạt.');
      return;
    }
    setState(() {
      _rejectError = null;
      _error = null;
      _submitting = true;
    });
    try {
      final uploads = await uploadDonationPhotos(_photos, refType: 'donation');
      await sl<CampaignRemoteDataSource>().checkContributionItem(
        contributionId: widget.contributionId,
        itemId: widget.item.id,
        action: _rejecting ? 'rejected' : 'accepted',
        conditionActual: _conditionActual,
        note: _noteController.text,
        rejectReason: _rejecting ? _rejectReasonController.text : null,
        imageUrls: uploads.map((upload) => upload.publicUrl).toList(),
      );
      // Gắn ảnh vào đơn để không bị cron dọn rác của media-service xoá mất.
      await linkDonationPhotos(
        uploads,
        refType: 'donation',
        refId: widget.contributionId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = campaignErrorMessage(
          error,
          fallback: 'Không ghi nhận được kết quả kiểm tra.',
        );
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mismatch = _conditionActual != item.conditionDeclared;

    return _SheetShell(
      title: 'Kiểm tra vật phẩm',
      subtitle: '${item.name} × ${item.quantity}',
      children: [
        if (item.declaredImages.isNotEmpty) ...[
          Text(
            'Ảnh người quyên góp gửi',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          RemotePhotoStrip(
            imageUrls: item.declaredImages
                .map((image) => image.imageUrl)
                .toList(),
          ),
          const SizedBox(height: 14),
        ],
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.check_circle_outline, size: 18),
              label: Text('Đạt'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.cancel_outlined, size: 18),
              label: Text('Không đạt'),
            ),
          ],
          selected: {_rejecting},
          onSelectionChanged: _submitting
              ? null
              : (value) => setState(() {
                  _rejecting = value.first;
                  _rejectError = null;
                }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _conditionActual,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Tình trạng thực tế',
            prefixIcon: const Icon(Icons.stars_outlined),
            helperText: 'Người quyên góp khai: '
                '${itemConditionLabel(item.conditionDeclared)}',
          ),
          items: kItemConditions
              .map(
                (condition) => DropdownMenuItem(
                  value: condition.value,
                  child: Text(condition.label),
                ),
              )
              .toList(),
          onChanged: _submitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _conditionActual = value);
                  }
                },
        ),
        if (mismatch) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: colors.tertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Khác với khai báo ban đầu — nên ghi rõ ở phần ghi chú.',
                  style: textTheme.bodySmall?.copyWith(color: colors.tertiary),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          maxLines: 2,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Ghi chú kiểm tra',
            hintText: 'Ví dụ: Đồ còn mới, đã giặt sạch',
            counterText: '',
          ),
        ),
        if (_rejecting) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _rejectReasonController,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Lý do không đạt *',
              hintText: 'Ví dụ: Áo rách vai, không dùng được',
              errorText: _rejectError,
              counterText: '',
            ),
            onChanged: (_) {
              if (_rejectError != null) setState(() => _rejectError = null);
            },
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Ảnh kiểm tra thực tế',
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        PhotoStrip(
          photos: _photos,
          onAdd: _addPhotos,
          onRemove: (index) => setState(() => _photos.removeAt(index)),
          emptyLabel: 'Chụp ảnh',
        ),
        const SizedBox(height: 6),
        Text(
          'Ảnh này minh bạch hoá hành trình món đồ cho người quyên góp.',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (!_rejecting) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Xác nhận đạt sẽ cộng ${item.quantity} vào tiến độ của đợt.',
                  style: textTheme.bodySmall?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: _rejecting ? colors.error : null,
            foregroundColor: _rejecting ? colors.onError : null,
          ),
          child: Text(
            _submitting
                ? 'Đang lưu...'
                : _rejecting
                ? 'Ghi nhận không đạt'
                : 'Xác nhận đạt',
          ),
        ),
      ],
    );
  }
}

/// Đóng đợt sớm: `active → closed`, kèm lý do gửi cho người đã quyên góp.
Future<bool?> showCloseCampaignSheet(
  BuildContext context, {
  required String campaignId,
  required String campaignTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _CloseSheet(campaignId: campaignId, campaignTitle: campaignTitle),
  );
}

class _CloseSheet extends StatefulWidget {
  const _CloseSheet({required this.campaignId, required this.campaignTitle});

  final String campaignId;
  final String campaignTitle;

  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await sl<CampaignRemoteDataSource>().closeCampaign(
        widget.campaignId,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = campaignErrorMessage(error, fallback: 'Không đóng được đợt.');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SheetShell(
      title: 'Đóng đợt quyên góp',
      subtitle: widget.campaignTitle,
      children: [
        Text(
          'Sau khi đóng, hội nhóm không nhận thêm đóng góp mới cho đợt này. '
          'Các đơn đang xử lý vẫn kiểm tra bình thường.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Lý do đóng đợt',
            hintText: 'Ví dụ: Hết hạn đợt, chưa đủ mục tiêu',
            helperText: 'Người đã quyên góp sẽ nhận được thông báo kèm lý do.',
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: Text(_submitting ? 'Đang đóng...' : 'Đóng đợt'),
        ),
      ],
    );
  }
}

/// Trao tặng đợt: `active → fulfilled`, kèm ảnh và ghi chú làm bằng chứng.
Future<bool?> showDeliverCampaignSheet(
  BuildContext context, {
  required String campaignId,
  required String campaignTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _DeliverSheet(campaignId: campaignId, campaignTitle: campaignTitle),
  );
}

class _DeliverSheet extends StatefulWidget {
  const _DeliverSheet({required this.campaignId, required this.campaignTitle});

  final String campaignId;
  final String campaignTitle;

  @override
  State<_DeliverSheet> createState() => _DeliverSheetState();
}

class _DeliverSheetState extends State<_DeliverSheet> {
  final _noteController = TextEditingController();
  final _photoPicker = DonationPhotoPicker();
  List<PendingPhoto> _photos = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final photo = await _photoPicker.pickOne(source);
        if (photo == null || !mounted) return;
        setState(() => _photos = [..._photos, photo]);
        return;
      }
      final remaining = DonationPhotoPicker.maxPhotos - _photos.length;
      if (remaining <= 0) return;
      final photos = await _photoPicker.pickMultiple(remaining: remaining);
      if (photos.isEmpty || !mounted) return;
      setState(() => _photos = [..._photos, ...photos]);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không chọn được ảnh: $error');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      // Backend chỉ nhận một ảnh trao tặng, lấy ảnh đầu làm ảnh đại diện.
      final uploads = await uploadDonationPhotos(_photos, refType: 'delivery');
      await sl<CampaignRemoteDataSource>().deliverCampaign(
        widget.campaignId,
        note: _noteController.text,
        deliveryPhotoUrl: uploads.isEmpty ? null : uploads.first.publicUrl,
      );
      await linkDonationPhotos(
        uploads,
        refType: 'delivery',
        refId: widget.campaignId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = campaignErrorMessage(
          error,
          fallback: 'Không xác nhận trao được.',
        );
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _SheetShell(
      title: 'Xác nhận đã trao tặng',
      subtitle: widget.campaignTitle,
      children: [
        Text(
          'Thao tác này không thể hoàn tác. Đợt sẽ chuyển sang "Đã trao tặng" '
          'và mọi người đã quyên góp đều nhận được thông báo.',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text(
          'Ảnh trao tặng',
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        PhotoStrip(
          photos: _photos,
          onAdd: _addPhotos,
          onRemove: (index) => setState(() => _photos.removeAt(index)),
          emptyLabel: 'Thêm ảnh',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Ghi chú trao tặng',
            hintText: 'Ví dụ: Đã trao toàn bộ đồ cho bà con vùng lũ',
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.volunteer_activism_rounded, size: 18),
          label: Text(_submitting ? 'Đang gửi...' : 'Xác nhận đã trao'),
        ),
      ],
    );
  }
}

/// Khung chung cho các sheet: tiêu đề, mã tham chiếu và vùng cuộn.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
