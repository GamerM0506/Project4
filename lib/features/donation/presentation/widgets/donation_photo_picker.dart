import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/media_service.dart';
import '../../../../injection_container.dart';

/// Một ảnh đang chờ tải lên, giữ cả [XFile] (để lấy mime) lẫn bytes (để xem trước).
class PendingPhoto {
  const PendingPhoto({required this.file, required this.bytes});

  final XFile file;
  final Uint8List bytes;

  String get mimeType =>
      file.mimeType ?? MediaService.mimeFromFileName(file.name);
}

/// Chọn ảnh (thư viện hoặc camera) và trả về danh sách đã đọc sẵn bytes.
///
/// Dùng chung cho cả người quyên góp lẫn hội nhóm nên logic giới hạn số lượng,
/// nén ảnh và xử lý lỗi chỉ tồn tại một chỗ.
class DonationPhotoPicker {
  DonationPhotoPicker({ImagePicker? imagePicker})
    : _picker = imagePicker ?? ImagePicker();

  final ImagePicker _picker;

  static const int maxPhotos = 10;

  /// Nén nhẹ trước khi tải lên: backend chặn ảnh quá 5 MB.
  static const double _maxDimension = 1200;
  static const int _quality = 78;

  Future<List<PendingPhoto>> pickMultiple({required int remaining}) async {
    if (remaining <= 0) return const [];
    final images = await _picker.pickMultiImage(
      limit: remaining,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    return _read(images.take(remaining));
  }

  Future<PendingPhoto?> pickOne(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    if (image == null) return null;
    return PendingPhoto(file: image, bytes: await image.readAsBytes());
  }

  Future<List<PendingPhoto>> _read(Iterable<XFile> files) async {
    final list = files.toList();
    final bytes = await Future.wait(list.map((file) => file.readAsBytes()));
    return [
      for (var i = 0; i < list.length; i++)
        PendingPhoto(file: list[i], bytes: bytes[i]),
    ];
  }
}

/// Tải danh sách ảnh lên Media service rồi liên kết với thực thể vừa tạo.
///
/// Trả về cả `mediaId` lẫn `publicUrl`: URL để nhét vào payload của
/// donation-service, còn id để gọi [linkDonationPhotos] sau khi thực thể đã
/// được tạo.
///
/// QUAN TRỌNG: ảnh chưa link nằm ở trạng thái `temp` và sẽ bị cron dọn rác của
/// media-service xoá khỏi storage sau `TEMP_TTL_HOURS` (mặc định 24h). Lúc đó
/// URL vẫn còn trong DB nhưng ảnh đã mất. Mọi lần upload đều phải kết thúc
/// bằng một lần link.
Future<List<MediaUploadResult>> uploadDonationPhotos(
  List<PendingPhoto> photos, {
  required String refType,
  String? refId,
}) async {
  if (photos.isEmpty) return const [];
  final mediaService = sl<MediaService>();
  final uploads = <MediaUploadResult>[];
  for (final photo in photos) {
    uploads.add(
      await mediaService.uploadImageResult(
        photo.bytes,
        photo.mimeType,
        refType: refType,
      ),
    );
  }
  if (refId != null && refId.isNotEmpty) {
    await linkDonationPhotos(uploads, refType: refType, refId: refId);
  }
  return uploads;
}

/// Gắn ảnh vừa tải lên vào thực thể nghiệp vụ (`temp` → `linked`).
///
/// Không để lỗi link làm hỏng nghiệp vụ chính: đơn/đợt đã tạo xong rồi, ảnh
/// chưa link thì chỉ mất ảnh chứ không mất đơn.
Future<void> linkDonationPhotos(
  List<MediaUploadResult> uploads, {
  required String refType,
  required String refId,
}) async {
  if (uploads.isEmpty || refId.isEmpty) return;
  try {
    await sl<MediaService>().linkMedia(
      uploads.map((upload) => upload.mediaId).toList(),
      refType,
      refId,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Không gắn được ảnh vào $refType/$refId',
      name: 'donation.media',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Bottom sheet chọn nguồn ảnh. Trả về `true` nếu người dùng chọn thư viện.
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Dải ảnh xem trước nằm ngang, có nút thêm và nút xoá từng ảnh.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.height = 110,
    this.maxPhotos = DonationPhotoPicker.maxPhotos,
    this.emptyLabel = 'Thêm ảnh',
    this.firstPhotoBadge,
  });

  final List<PendingPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double height;
  final int maxPhotos;
  final String emptyLabel;

  /// Nhãn gắn lên ảnh đầu tiên, ví dụ "Ảnh AI".
  final String? firstPhotoBadge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canAdd = photos.length < maxPhotos;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == photos.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: height * 0.86,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  photos[index].bytes,
                  width: height * 0.86,
                  height: height,
                  fit: BoxFit.cover,
                ),
              ),
              if (index == 0 && firstPhotoBadge != null)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      firstPhotoBadge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton.filled(
                  onPressed: () => onRemove(index),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 15),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lưới ảnh đã tải lên (đọc từ URL), dùng khi xem lại đơn đóng góp.
class RemotePhotoStrip extends StatelessWidget {
  const RemotePhotoStrip({
    super.key,
    required this.imageUrls,
    this.height = 76,
  });

  final List<String> imageUrls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrls[index],
            width: height,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: height,
              height: height,
              color: colors.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
