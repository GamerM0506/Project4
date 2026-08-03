import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../injection_container.dart';
import '../network/media_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String label;
  final String? initialUrl;
  final ValueChanged<String?> onImageUploaded;
  final bool isAvatar;

  /// Loại media gửi cho media-service. Phải nằm trong danh sách backend chấp
  /// nhận: avatar | post | donation | delivery | chat | listing.
  final String refType;

  /// Id thực thể để gắn ảnh (`temp` → `linked`). Bỏ trống thì ảnh sẽ bị cron
  /// dọn rác của media-service xoá sau TEMP_TTL_HOURS, khiến ảnh vỡ về sau.
  final String? refId;

  const ImagePickerWidget({
    super.key,
    required this.label,
    required this.onImageUploaded,
    this.initialUrl,
    this.isAvatar = false,
    this.refType = 'avatar',
    this.refId,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _currentUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ảnh mới từ server (sau khi lưu và tải lại) phải phản ánh lên UI.
    if (widget.initialUrl != oldWidget.initialUrl && !_isUploading) {
      _currentUrl = widget.initialUrl;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final mediaService = sl<MediaService>();
      final bytes = await image.readAsBytes();
      final mimeType =
          image.mimeType ?? MediaService.mimeFromFileName(image.name);

      final uploaded = await mediaService.uploadImageResult(
        bytes,
        mimeType,
        refType: widget.refType,
      );

      // Gắn ngay nếu đã biết thực thể; nếu chưa (form tạo mới) thì phía gọi
      // phải tự link sau khi tạo xong.
      final refId = widget.refId;
      if (refId != null && refId.isNotEmpty) {
        try {
          await mediaService.linkMedia(
            [uploaded.mediaId],
            widget.refType,
            refId,
          );
        } catch (error, stackTrace) {
          developer.log(
            'Không gắn được ảnh vào ${widget.refType}/$refId',
            name: 'media.link',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _currentUrl = uploaded.publicUrl;
        _isUploading = false;
      });

      widget.onImageUploaded(uploaded.publicUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _currentUrl = null;
    });
    widget.onImageUploaded(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isAvatar) {
      return Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    image: _currentUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_currentUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: _currentUrl == null && !_isUploading
                      ? Icon(
                          Icons.camera_alt,
                          color: colorScheme.onSurfaceVariant,
                          size: 32,
                        )
                      : null,
                ),
                if (_isUploading)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (_currentUrl != null && !_isUploading)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: colorScheme.onError,
                            size: 16,
                          ),
                        ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  image: _currentUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_currentUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: _currentUrl == null && !_isUploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: colorScheme.onSurfaceVariant,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn để chọn ảnh',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              if (_isUploading)
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              if (_currentUrl != null && !_isUploading)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: colorScheme.onError,
                          size: 20,
                        ),
                      ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
