import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../injection_container.dart';
import '../../../../core/network/media_service.dart';
import '../cubit/group_feed_cubit.dart';
import '../cubit/group_feed_state.dart';

class CreatePostWidget extends StatefulWidget {
  final String groupId;
  const CreatePostWidget({super.key, required this.groupId});

  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final _contentController = TextEditingController();
  String _selectedType = 'normal';
  List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  final List<Map<String, String>> _postTypes = [
    {'value': 'normal', 'label': 'Thảo luận'},
    {'value': 'call_for_donation', 'label': 'Kêu gọi Quyên góp'},
    {'value': 'thank_you', 'label': 'Cảm ơn'},
    {'value': 'announcement', 'label': 'Thông báo'},
  ];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(limit: 10);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 10) {
          _selectedImages = _selectedImages.sublist(0, 10);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    List<String> uploadedUrls = [];
    final mediaService = sl<MediaService>();

    try {
      for (var img in _selectedImages) {
        final bytes = await img.readAsBytes();
        final mimeType = img.mimeType ?? MediaService.mimeFromFileName(img.name);
        final url = await mediaService.uploadImage(bytes, mimeType, refType: 'post_images');
        uploadedUrls.add(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh lên: $e')));
      }
      setState(() {
        _isUploadingImages = false;
      });
      return;
    }

    if (mounted) {
      context.read<GroupFeedCubit>().createPost(
        widget.groupId,
        _contentController.text.trim(),
        _selectedType,
        uploadedUrls,
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<GroupFeedCubit, GroupFeedState>(
      listener: (context, state) {
        if (state is GroupFeedCreateSuccess) {
          _contentController.clear();
          setState(() {
            _selectedImages.clear();
            _isUploadingImages = false;
            _selectedType = 'normal';
          });
          FocusScope.of(context).unfocus();
        } else if (state is GroupFeedCreateError) {
          setState(() {
            _isUploadingImages = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is GroupFeedCreating || _isUploadingImages;

        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        items: _postTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: isLoading ? null : (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Bạn muốn chia sẻ điều gì với nhóm?',
                    border: InputBorder.none,
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                ? Image.network(
                                    _selectedImages[index].path,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_selectedImages[index].path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: isLoading ? null : () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const Divider(),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: isLoading ? null : _pickImages,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Thêm ảnh'),
                      style: TextButton.styleFrom(foregroundColor: colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: isLoading ? null : _submitPost,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB73A41),
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Đăng bài'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
